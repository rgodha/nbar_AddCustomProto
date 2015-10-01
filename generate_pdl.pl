#!/usr/local/bin/perl5.8 -w

# XML to PDL Conversion
# Algo:
# 1. Parse the XML
# 2. Store all the values in a hash
# 3. Generate the PDL
# 4. [Copy base, iana and pdl_common file into /tmp/nbar_sdk - Not needed while deploying - deprecated]
#		i.	Copy custom PDL file into the advanced PDLs folder and create the
#			incremental or non-incremental pPack, as the case may be.
#		ii.	Delete the .pdl and .pdlh file from the advanced PDLs folder after #			pPack is created
# 5. Create the pdl list file
# 6. Create the protocol pack
# 7. [Create the command file for clisim to execute - deprecated]
# 8. Load protocol on clisim & analyze results


##############################
## Libraries
use strict;
use warnings;
use XML::XPath;
use Expect;
use Encode qw(decode);
#use XML::XPath::XMLParser;
require "common_subroutines.pl";
##############################

##############################
##Variables
my $workingDir = getWorkingDirectory();
my %nameValueHash = ();
my $clisimPath = getSimulatorPath();
my $protocolName = '';
my $fileName = '';
my $folderName = '';
my $server_handler = '';
my $client_handler = '';
my $table1_handler = '';
my $table2_handler = '';
my $temp_url = '';
my $temp_host = '';
##############################

## Generic PDL generation subroutines

sub generic_generate_custom_pdl {
	insert_initial_preprocessor_directives();
	print PDL_File_Handler "\n";
	generic_insert_header();
	print PDL_File_Handler "\n";
	generic_insert_handlers();
	print PDL_File_Handler "\n";
	close PDL_File_Handler;
}

sub generic_insert_header {
	print PDL_File_Handler "( define ". $nameValueHash{'custom_protocol_name'}."_id\n";
	generic_insert_register_protocol();
	print PDL_File_Handler ")\n";    #closing for header
}

sub generic_insert_register_protocol {
	print PDL_File_Handler "\t ( register-protocol `$nameValueHash{custom_protocol_name}'\n";	
	#insert_protocol_id();
	#insert_global_IANA_id();
	#insert_link_age();
	insert_ip_transport_support();
	insert_help_string();	
	insert_protocol_w_k_p();
	print PDL_File_Handler "\t )\n";    #closing for register-protocol
}

sub generic_insert_handlers {
	if ( $nameValueHash{'port_type'} eq 'any' ) {
		generic_insert_server_handler();
		print PDL_File_Handler "\n";
		generic_insert_client_handler();
	}
	elsif (  $nameValueHash{'port_type'}  eq 'destination' ) {
		generic_insert_server_handler();
		print PDL_File_Handler "( define-handler $client_handler )\n";
	}
	elsif (  $nameValueHash{'port_type'} eq 'source' ) {
		print PDL_File_Handler "( define-handler $server_handler )\n";
		generic_insert_client_handler();
	}
}

sub generic_insert_server_handler {
	print PDL_File_Handler "( define-handler $server_handler\n";
	if ( exists( $nameValueHash{'pattern_payload_offset'} ) ) {
		generic_insert_protocol_struct();
	}
	insert_classify_packet();
	generic_insert_set_flow_handler();
	print PDL_File_Handler "\n)\n";    #clsoing for server handler
}

sub generic_insert_client_handler {
	print PDL_File_Handler "( define-handler $client_handler\n";
	if ( exists( $nameValueHash{'pattern_payload_offset'} ) ) {
		generic_insert_protocol_struct();
	}
	insert_classify_packet();
	generic_insert_set_flow_handler();
	print PDL_File_Handler "\n)\n";    #closing for client handler
}

sub generic_insert_protocol_struct {
	my $bytes;
	my $stringLength;
	
	print PDL_File_Handler "\t( structure "
	  .  $nameValueHash{'protocol_type'} 
	  . "-header-struct \n";
	print PDL_File_Handler
	  "\t\t( field offset $nameValueHash{'pattern_payload_offset'} )\n";

	if ( $nameValueHash{'pattern_type'} eq 'decimal' ) {
		print PDL_File_Handler "\t\t( field var0 ";

		if ( !$nameValueHash{'pattern_value'} < ( 2**32 ) ) {
			$nameValueHash{'pattern_value'} %= ( 2**32 );
			##TODO: Check above code - run tests manually
		}

		if ( $nameValueHash{'pattern_value'} < ( 2**8 ) ) {
			print PDL_File_Handler "1 )";
		}
		elsif ( $nameValueHash{'pattern_value'} < ( 2**16 ) ) {
			print PDL_File_Handler "2 )";
		}
		elsif ( $nameValueHash{'pattern_value'} < ( 2**24 ) ) {
			print PDL_File_Handler "3 )";
		}

		#elsif( $nameValueHash{'pattern_value'} < ( 2**32 ) ) {
		else {
			print PDL_File_Handler "4 )";
		}

		print PDL_File_Handler "\n\t)\n";    #closing for structure

		print PDL_File_Handler "\t( require var0 ";
		print PDL_File_Handler "0x",
		  sprintf( "%x", $nameValueHash{'pattern_value'} ), ")\n";
	}
	elsif ( $nameValueHash{'pattern_type'} eq 'ascii' ) {

		$stringLength = length( $nameValueHash{'pattern_value'} );

		if ( $stringLength >= 16 ) {
			$nameValueHash{'pattern_value'} =
			  substr( $nameValueHash{'pattern_value'}, 0, 15 );
			print "Truncated str: $nameValueHash{'pattern_value'}";
			$stringLength = 15;
		}
		if ( $stringLength <= 8 ) {
			print PDL_File_Handler "\t\t( field var0 $stringLength )";
		}
		else {
			print PDL_File_Handler "\t\t( field var0 8 )\n";
			print PDL_File_Handler "\t\t( field var1 ", ( $stringLength - 8 ), " )";
		}

		print PDL_File_Handler "\n\t)\n";    #closing for structure

		if ( $stringLength <= 8 ) {
			print PDL_File_Handler "\t( require var0 `",
			  substr( $nameValueHash{'pattern_value'}, 0, $stringLength ),
			  "' )\n";
		}
		else {
			print PDL_File_Handler "\t( require var0 `",
			  substr( $nameValueHash{'pattern_value'}, 0, 8 ), "' )\n";

			print PDL_File_Handler "\t( require var1 `",
			  substr( $nameValueHash{'pattern_value'}, 8, $stringLength ),
			  "' )\n";
		}
	}
	elsif ( $nameValueHash{'pattern_type'} eq 'hex' ) {

		$stringLength = length( $nameValueHash{'pattern_value'} );

		if ( $stringLength >= 8 ) {
			$nameValueHash{'pattern_value'} = substr(
				$nameValueHash{'pattern_value'},
				$stringLength - 8,
				$stringLength
			);
			print "Truncated hex: $nameValueHash{'pattern_value'}\n";
			print PDL_File_Handler "\t\t( field var0 4 )";
		}
		else {
			$bytes = ( int( $stringLength / 2 ) ) + ( $stringLength % 2 );
			print PDL_File_Handler "\t\t( field var0 " . $bytes . " )";
		}
		print PDL_File_Handler "\n\t)\n";    #closing for structure
		print PDL_File_Handler "\t( require var0 0x$nameValueHash{'pattern_value'} )\n";
	}
}

sub generic_insert_set_flow_handler {
	print PDL_File_Handler "\t ( set-flow-handler ";
	if ( $nameValueHash{'port_type'} eq 'any' ) {
		print PDL_File_Handler "both-dir";
	}
	else {
		print PDL_File_Handler "same-dir";
	}
	print PDL_File_Handler ")";
}
## End of generic PDL generation subroutines


## URL &/or Host PDL generation subroutines

sub generate_host_url_custom_pdl() {
	insert_initial_preprocessor_directives();
	print PDL_File_Handler "\n";
	url_host_insert_header();
	print PDL_File_Handler "\n";
	url_host_insert_handlers();
	print PDL_File_Handler "\n";
	close PDL_File_Handler;
}

sub url_host_insert_header {
	print PDL_File_Handler "( define ". $nameValueHash{'custom_protocol_name'} . "_id\n";
	url_host_insert_register_protocol();
	print PDL_File_Handler ")\n";    #closing for header
}

sub url_host_insert_register_protocol {
	print PDL_File_Handler "\t ( register-protocol `$nameValueHash{custom_protocol_name}'\n";
	#insert_protocol_id();
	#insert_global_IANA_id();
	#insert_link_age();
	insert_ip_transport_support();
	insert_help_string();	
	
	if (exists($nameValueHash{'pattern_host'}) && exists($nameValueHash{'pattern_url'})) {
		url_host_insert_hostURL_string();
	}
	elsif (exists($nameValueHash{'pattern_host'})) {
		url_host_insert_host_string();
	}
	elsif (exists($nameValueHash{'pattern_url'})) {
		url_host_insert_url_string();
	}
	print PDL_File_Handler "\t )\n";    #closing for register-protocol
}

sub url_host_insert_hostURL_string {
	$temp_host = $nameValueHash{'pattern_host'};
	$temp_host =~ s/\./[.]/g;
	$temp_host =~ s/\*/[^ \\n\\r]*/g;
	$temp_url = $nameValueHash{'pattern_url'};
	$temp_url =~ s/\*/[^ \\n\\r]*/g;
	print PDL_File_Handler "\t\t ( heuristic-regexp-tcp-all-handler `((GET)|(PUT)|(HEAD)|(POST)|(DELETE)|(TRACE)|(OPTIONS)|(CONNECT)) +http://(";
	print PDL_File_Handler "$temp_host";
	print PDL_File_Handler ')[^ \n\r/]*/(';
	print PDL_File_Handler "$temp_url )'";
	url_host_insert_handler_names();
	print PDL_File_Handler ")\n";
	print PDL_File_Handler "\t\t ( heuristic-regexp-tcp-all-handler `((GET)|(PUT)|(HEAD)|(POST)|(DELETE)|(TRACE)|(OPTIONS)|(CONNECT)) +/(";
	print PDL_File_Handler "$temp_url";
	print PDL_File_Handler ")'";
	print PDL_File_Handler " heuristic-".$nameValueHash{'custom_protocol_name'}."-skiptohost )\n";
}

sub url_host_insert_host_string {
	$temp_host = $nameValueHash{'pattern_host'};
	$temp_host =~ s/\./[.]/g;
	$temp_host =~ s/\*/[^ \\n\\r]*/g;
	print PDL_File_Handler "\t\t".' ( heuristic-regexp-tcp-all-handler `((GET)|(PUT)|(HEAD)|(POST)|(DELETE)|(TRACE)|(OPTIONS)|(CONNECT)) +http://(';
	print PDL_File_Handler $temp_host;
	print PDL_File_Handler ')\'';
	url_host_insert_handler_names();
	print PDL_File_Handler ")\n";
	print PDL_File_Handler "\t\t".' ( heuristic-regexp-tcp-all-handler `((GET)|(PUT)|(HEAD)|(POST)|(DELETE)|(TRACE)|(OPTIONS)|(CONNECT)) +((([^\n])|(\n[^h])|(\nh[^o])|(\nho[^s])|(\nhos[^t])|(\nhost[^:])|(\nhost:[^ ]))*\nhost: (';
	print PDL_File_Handler $temp_host;
	print PDL_File_Handler "))'";
	url_host_insert_handler_names();
	print PDL_File_Handler " )\n";
}

sub url_host_insert_url_string {
	$temp_url = $nameValueHash{'pattern_url'};
	$temp_url =~ s/\*/[^ \\n\\r]*/g;
	print PDL_File_Handler "\t\t".' ( heuristic-regexp-tcp-all-handler `((GET)|(PUT)|(HEAD)|(POST)|(DELETE)|(TRACE)|(OPTIONS)|(CONNECT)) +/('.$temp_url.')\'';
	url_host_insert_handler_names();
	print PDL_File_Handler ")\n";
	print PDL_File_Handler "\t\t".' ( heuristic-regexp-tcp-all-handler `((GET)|(PUT)|(HEAD)|(POST)|(DELETE)|(TRACE)|(OPTIONS)|(CONNECT)) +http://[^ \n\r/]*/('.$temp_url.')\''.$server_handler.' )'."\n"
}

sub url_host_insert_handler_names {
	$server_handler = " heuristic-".$nameValueHash{'custom_protocol_name'};
	$client_handler = undef;
	print PDL_File_Handler " $server_handler ";
}

sub url_host_insert_handlers {
	if (exists($nameValueHash{'pattern_host'}) && exists($nameValueHash{'pattern_url'})) {			##if both exist
		print PDL_File_Handler "( define-handler heuristic-";
		print PDL_File_Handler $nameValueHash{'custom_protocol_name'};
		print PDL_File_Handler "-skiptohost\n";
		print PDL_File_Handler "\t".' ( structure'."\n\t\t";
		print PDL_File_Handler " ( field host\n";
		print PDL_File_Handler "\t\t\t".'( regexp insensitive store `.*((\n\r\n)|(\r\nHost: ))\' 4 )'."\n";
		print PDL_File_Handler "\t\t )\n\t )\n";
		print PDL_File_Handler "\t ( if ( = host.1 `st: ') (handler heuristic-";
		print PDL_File_Handler $nameValueHash{'custom_protocol_name'};
		print PDL_File_Handler "-host-check ) )\n";
		print PDL_File_Handler ")\n\n";
		
		print PDL_File_Handler "( define-handler heuristic-";
		print PDL_File_Handler $nameValueHash{'custom_protocol_name'};
		print PDL_File_Handler "-host-check\n";
		print PDL_File_Handler "\t".' ( structure '."\n\t\t".' ( field hostname '."\n";
		print PDL_File_Handler "\t\t\t".' ( regexp insensitive `(';
		print PDL_File_Handler $temp_host;
		print PDL_File_Handler ")' )\n\t\t )\n\t )\n";
		print PDL_File_Handler "\t ( require hostname 1) ( handler heuristic-";
		print PDL_File_Handler $nameValueHash{'custom_protocol_name'};
		print PDL_File_Handler " )\n)\n\n";
		
		print PDL_File_Handler "( define-handler $server_handler\n";
		insert_classify_packet();
		print PDL_File_Handler "\t ( set-flow-handler both-dir )\n)";
	}
	#elsif (exists($nameValueHash{'pattern_host'}) || exists($nameValueHash{'pattern_url'})) {
	else {		##if either one exists
		print PDL_File_Handler "( define-handler $server_handler\n";
		insert_classify_packet();
		print PDL_File_Handler "\t ( set-flow-handler both-dir )\n)";
	}
}

## End of URL &/or Host PDL generation subroutines

## Variable format PDL generation subroutines

sub generate_variable_format_custom_pdl {
	insert_initial_preprocessor_directives();
	print PDL_File_Handler "\n";
	variable_format_insert_header();
	print PDL_File_Handler "\n";
	variable_format_insert_handlers();
	print PDL_File_Handler "\n";
	close PDL_File_Handler;
}

sub variable_format_insert_header {
	print PDL_File_Handler "( define ". $nameValueHash{'custom_protocol_name'} . "_id\n";
	variable_format_insert_register_protocol();
	print PDL_File_Handler ")\n";    #closing for header
}

sub variable_format_insert_register_protocol {
	print PDL_File_Handler "\t ( register-protocol `$nameValueHash{custom_protocol_name}'\n";	
	#insert_protocol_id();
	#insert_global_IANA_id();
	#insert_link_age();
	insert_ip_transport_support();
	insert_help_string();	
	url_host_insert_parameter_info();
	insert_protocol_w_k_p();
	print PDL_File_Handler "\t )\n";    #closing for register-protocol
}

sub url_host_insert_parameter_info {
	print PDL_File_Handler "\t\t ( parameter (type-multi) `".$nameValueHash{'pattern_variable_name'}."' `User defined field'\n";
	variable_format_insert_parameter_handler_names();
	print PDL_File_Handler "\t\t )\n"; ##closing for parameter
}

sub variable_format_insert_parameter_handler_names {
	$server_handler = "server-".$nameValueHash{'custom_protocol_name'};
	$client_handler = "client-".$nameValueHash{'custom_protocol_name'};
	$table2_handler = "table2-".$nameValueHash{'custom_protocol_name'};
	$table1_handler = "table1-".$nameValueHash{'custom_protocol_name'};
	
	if ( $nameValueHash{'port_type'} eq 'any' ) {
		print PDL_File_Handler "\t\t\t $server_handler.".$nameValueHash{'pattern_variable_name'}."\n";
		print PDL_File_Handler "\t\t\t $client_handler.".$nameValueHash{'pattern_variable_name'}."\n";
		print PDL_File_Handler "\t\t\t $table2_handler.".$nameValueHash{'pattern_variable_name'}."\n";
	}
	elsif (  $nameValueHash{'port_type'}  eq 'destination' ) {
		print PDL_File_Handler "\t\t\t $server_handler.".$nameValueHash{'pattern_variable_name'}."\n";
		print PDL_File_Handler "\t\t\t $table2_handler.".$nameValueHash{'pattern_variable_name'}."\n";
	}
	elsif (  $nameValueHash{'port_type'} eq 'source' ) {
		print PDL_File_Handler "\t\t\t $client_handler.".$nameValueHash{'pattern_variable_name'}."\n";
		print PDL_File_Handler "\t\t\t $table2_handler.".$nameValueHash{'pattern_variable_name'}."\n";
	}
}

sub variable_format_insert_handlers {
	if ( $nameValueHash{'port_type'} eq 'any' ) {
		variable_format_insert_server_handler();
		print PDL_File_Handler "\n";
		variable_format_insert_client_handler();
	}
	elsif (  $nameValueHash{'port_type'}  eq 'destination' ) {
		variable_format_insert_server_handler();
		print PDL_File_Handler "\n( define-handler $client_handler )\n\n";
	}
	elsif (  $nameValueHash{'port_type'} eq 'source' ) {
		print PDL_File_Handler "\n( define-handler $server_handler )\n\n";
		variable_format_insert_client_handler();
	}
	variable_format_insert_table_handlers();
}

sub variable_format_insert_server_handler {
	print PDL_File_Handler "( define-handler $server_handler\n";
	print PDL_File_Handler "\t ( structure ".$nameValueHash{'protocol_type'}."-header-struct\n";
	print PDL_File_Handler "\t\t ( field offset ".$nameValueHash{'pattern_payload_offset'}." )\n";
	print PDL_File_Handler "\t\t ( field ".$nameValueHash{'pattern_variable_name'}." ".$nameValueHash{'pattern_variable_size'}." )\n\t )\n";
	insert_classify_packet();
	print PDL_File_Handler "\t ( touch ".$nameValueHash{'pattern_variable_name'}." )\n";
	insert_classify_packet();
	print PDL_File_Handler "\t ( set-flow-handler-and-sub-classify ";
	variable_format_set_flow_handler();
	print PDL_File_Handler " $table1_handler )\n)\n";
}

sub variable_format_insert_client_handler {
	print PDL_File_Handler "( define-handler $client_handler\n";
	print PDL_File_Handler "\t ( structure ".$nameValueHash{'protocol_type'}."-header-struct\n";
	print PDL_File_Handler "\t\t ( field offset ".$nameValueHash{'pattern_payload_offset'}." )\n";
	print PDL_File_Handler "\t\t ( field ".$nameValueHash{'pattern_variable_name'}." ".$nameValueHash{'pattern_variable_size'}." )\n\t )\n";
	insert_classify_packet();
	print PDL_File_Handler "\t ( touch ".$nameValueHash{'pattern_variable_name'}." )\n";
	insert_classify_packet();
	print PDL_File_Handler "\t ( set-flow-handler-and-sub-classify ";
	variable_format_set_flow_handler();
	print PDL_File_Handler " $table1_handler )\n)\n";
}

sub variable_format_set_flow_handler {
	if ( $nameValueHash{'port_type'} eq 'any' ) {
		print PDL_File_Handler "both-dir";
	}
	else {
		print PDL_File_Handler "same-dir";
	}
}

sub variable_format_insert_table_handlers {
	print PDL_File_Handler "\n( define-handler $table1_handler";
	print PDL_File_Handler "\n\t ( structure ".$nameValueHash{'protocol_type'}."-header-struct )\n";
	insert_classify_packet();
	print PDL_File_Handler "\t ( handler $table2_handler )\n)\n\n";
	
	print PDL_File_Handler "( define-handler $table2_handler\n";
	print PDL_File_Handler "\t ( structure ".$nameValueHash{'protocol_type'}."-header-struct \n";
	print PDL_File_Handler "\t\t ( field offset ".$nameValueHash{'pattern_payload_offset'}." )\n";
	print PDL_File_Handler "\t\t ( field ".$nameValueHash{'pattern_variable_name'}." ".$nameValueHash{'pattern_variable_size'}." )\n\t )\n";
	print PDL_File_Handler "\t ( touch ".$nameValueHash{'pattern_variable_name'}." )\n";
	print PDL_File_Handler "\t ( set-flow-handler-and-sub-classify both-dir ".$table1_handler." )\n)";
}

## End of variable format PDL generation subroutines


##############################
## Common Subroutines for this script

sub parseXML {
	my $xpath;
	my $nodeset;
	my $nameValueString;
	my @tempList;
	my $nodeName;

	$xpath = XML::XPath->new("$workingDir/$folderName/$fileName");
	$nodeset = $xpath->find('//@*');
	foreach my $node ( $nodeset->get_nodelist ) {
		##split this and find the attribs
		$nameValueString = XML::XPath::XMLParser::as_string($node);
		@tempList        = split( '=', $nameValueString );

		##remove the space before the attrib name
		$tempList[0] = reverse( $tempList[0] );
		chop( $tempList[0] );
		$tempList[0] = reverse( $tempList[0] );

		##remove the double quotes surrounding the value
		$tempList[1] = substr( $tempList[1], 0, -1 );
		$tempList[1] = reverse( $tempList[1] );
		$tempList[1] = substr( $tempList[1], 0, -1 );
		$tempList[1] = reverse( $tempList[1] );

		$nodeName =
		  $xpath->find( '//*[@' . $tempList[0] . '=\'' . $tempList[1] . '\']' );

		for my $element ( $nodeName->get_nodelist ) {
			#print "\nNodeName: '", $element->getName, "'\n",$tempList[0],"=>",$tempList[1] ;
	
			# 2. Store all the values in a hash
			foreach my $item (@tempList) {
				$nameValueHash{ $element->getName . '_' . $tempList[0] } =
				  $tempList[1];
			}
		}
	}
}

sub insert_initial_preprocessor_directives {
	print PDL_File_Handler "; ModuleName: $nameValueHash{'custom_protocol_name'}\n";
	#print PDL_File_Handler "; ModuleVersion: $nameValueHash{'custom_version'}\n";
	print PDL_File_Handler "; ModuleVersion: 1.1\n";
}

sub insert_ip_transport_support {
	print PDL_File_Handler "\t\t ( ip-transport-support ipv4 ipv6 )\n";
}

sub insert_help_string {
	#if ( exists( $nameValueHash{'help_string'} ) ) {
	#	print PDL_File_Handler
	#	  "\t\t ( help-string `$nameValueHash{help_string}')\n";
	#}
	print PDL_File_Handler "\t\t ( help-string `User defined Protocol-$nameValueHash{'custom_protocol_name'}' )\n";
}


##TODO
#sub insert_protocol_id {
#	print PDL_File_Handler "\t\t ( protocol-id 243 )\n";
#}

##TODO
#sub insert_global_IANA_id {
#	print PDL_File_Handler "\t\t ( global-id  )\n";
#}

##TODO
#sub insert_link_age {
#	print PDL_File_Handler "\t\t ( link-age ??? )\n";
#}

##TODO
#sub insert_heuristic_rule {}


sub insert_protocol_w_k_p {
	print PDL_File_Handler "\t\t ( $nameValueHash{'protocol_type'}-well-known-port ";
	if ($nameValueHash{'port_value'} ne 'all') {
		if ($nameValueHash{'port_value'} =~ m/-/) {
			#port range found
			#(tcp-well-known-port range  3445 4544  server-hithere client-hithere 
			my @ports = split("-", $nameValueHash{'port_value'});
			print PDL_File_Handler "range $ports[0] $ports[1] ";
		}
		elsif ($nameValueHash{'port_value'} =~ m/,/) {
			#multiple ports found
			#(tcp-well-known-port 4567 7896 4564 46567 34875  server-brthere client-brthere ))
			my @ports = split(",", $nameValueHash{'port_value'});
			foreach my $port (@ports) {
				print PDL_File_Handler "$port ";
			}
		}
		else {
			print PDL_File_Handler " $nameValueHash{'port_value'}  ";
		}
	}
	
	if ( exists($nameValueHash{'pattern_type'}) && $nameValueHash{'pattern_type'} eq 'variable' ) {
		print PDL_File_Handler "$server_handler $client_handler ";
	}
	else {
		$server_handler = $nameValueHash{'custom_protocol_name'} . "-handler-server";
		$client_handler = $nameValueHash{'custom_protocol_name'} . "-handler-client";
		print PDL_File_Handler "$server_handler $client_handler ";
	}
	print PDL_File_Handler ")\n";    #closing for proto_w_k_p
}

sub insert_classify_packet {
	print PDL_File_Handler "\t ( classify-packet ". $nameValueHash{'custom_protocol_name'}."_id )\n";
}

## End of common Subroutines for this script



## MAIN - Start of script##
#die if not equal to 1 arg
if ( scalar(@ARGV) != 2 ) {
	die "1. Usage: $0  <folder name> <XML filename>\n";
}

$folderName = $ARGV[0];
$protocolName = $ARGV[1];
$fileName = $protocolName.".xml";


if (!(-e "$workingDir/$folderName")) {
	die "2. Usage: $0  <Folder Name> <XML filename>\tFolder does not exist...!\n";
}

if (!(-e "$workingDir/$folderName/$fileName")) {
	die "3. Usage: $0  <Folder Name> <XML filename>\tXML file does not exist...!\n";
}

##############################
# 1. Parse the XML
parseXML();
	###Testing Code#######
	#print the hash here
	#foreach my $key ( keys %nameValueHash ) {
	#	print "'$key' => '$nameValueHash{$key}'\n";
	#}
##XML parsing done


# 3. Generate the PDL

# First convert the values into ASCII
#convert_to_ASCII();
#sub convert_to_ASCII {
#	my $temp;
#	foreach my $key ( keys %nameValueHash ) {
#		#my @list = Encode->encodings(); shows the encodings available
#		#print ">>@list<<";
#		print "'$key' => '$nameValueHash{$key}' <<--BEFORE\n";
#		$temp = $nameValueHash{$key};
#		$nameValueHash{$key} = decode("ascii", $temp);
#		print "'$key' => '$nameValueHash{$key}' <<--AFTER\n";
#	}
#}

$fileName = $nameValueHash{'custom_protocol_name'}.".pdl";
open( PDL_File_Handler, ">$workingDir/$folderName/$fileName" ) || die "\nError opening PDL file for writing: \n'$!'\n";
print PDL_File_Handler "\n";

if ( exists($nameValueHash{'pattern_host'}) || exists($nameValueHash{'pattern_url'}) ) {
	generate_host_url_custom_pdl();
}
elsif ( exists($nameValueHash{'pattern_type'}) ) {
	if ( $nameValueHash{'pattern_type'} eq 'variable' ) {
		generate_variable_format_custom_pdl();
	}
	else {
		generic_generate_custom_pdl();
		#works fine
	}
}
else {
	generic_generate_custom_pdl();
	#works fine
}

##PDL Generated
##Copying files and generation of pPack now done by load_on_clisim.pl script

## End of script
##############################


#customp 'name' source|dest tcp|udp [range]  'port1 port2 ...' 
#  customp 'name' tcp|udp [range] 'port1 port2...'
#  customp 'name' offset 'offset' ascii|decimal|hex|variable 'value' ...
#   - if 'variable' is specified, to be followed by variable name and size
#      - ... variable 'var-name' 'size' tcp|udp|source...
#   - ascii etc to be followed by field value
#   - ... ascii/decimal/hex value tcp|udp|source...
#   - tcp|udp|source... to be followed by port as before
#customp 2test offset 5 variable var_name 14453 dest udp 1345
#uint16_t variable_size
