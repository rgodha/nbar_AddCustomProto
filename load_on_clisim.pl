#!/usr/local/bin/perl5.8 -w

##############################
## Libraries
use strict;
use warnings;
use Expect;
require "common_subroutines.pl";
##############################

##############################
##Variables
my $workingDir = getWorkingDirectory();
my $clisimPath = getSimulatorPath();
my @pdlFileNames = ();
my $returnValue = 1;
my $folderName = '';
my $pPackName = '';
my $parameter = '';
##############################


## Subroutines

sub get_pdl_names {
	my @names = ();
	my $key = '';
	my $value = '';
	open( Params_File_Handler, "$workingDir/$folderName/params.file" ) || die "\nError opening parameters file for reading pdl files: \n'$!'\n";
	while(<Params_File_Handler>) {
		($key, $value) = split(":");	#implicitly splits $_
		chomp($value);					#strip newlines from $value
		if ($key eq 'protocolName') {
			push (@names, $value.".pdl");
		}
	}
	close Params_File_Handler;
	#print "\nProtocol Names: @names\n\n";
	return @names;
}

sub create_pdl_list_file {
	if ($parameter eq 'incremental') {
		## Advanced pdl list is statically generated beforehand
		## Use 'find -type f -name "*.pdl" | cut -c3- > advanced_pdl.lst' to
		## get the list of pdls again
		system("cp advanced_pdl.lst $workingDir/$folderName;");
		open( Temp_File_Handler, ">>$workingDir/$folderName/advanced_pdl.lst" ) || die "\nError opening pdl list file (incremental): \n$!\n";
		foreach my $fileName (@pdlFileNames) {
			print Temp_File_Handler "\n$fileName";
		}
		close Temp_File_Handler;
	}
	else {
		open( Temp_File_Handler, ">$workingDir/$folderName/advanced_pdl.lst" ) || die "\nError opening pdl list file (default): \n$!\n";
		print Temp_File_Handler "base.pdl\niana.pdl";
		foreach my $fileName (@pdlFileNames) {
			print Temp_File_Handler "\n$fileName";
		}
		close Temp_File_Handler;
	}
}

sub create_pPack {
	my $protocolPackName = getProtoPackName();
	#system("cd $clisimPath/stile/tools/src;./protocolPackGen -v 3.9 -f $workingDir/$folderName/advanced_pdl.lst -i ../../../sys/stile/advanced_pdls -name $protocolPackName; mv $protocolPackName $workingDir/$folderName");
	
	#print "cd $clisimPath/stile/tools/src;./protocolPackGen.sh -v 3.9 -f $workingDir/$folderName/advanced_pdl.lst -i ../../../sys/stile/advanced_pdls -name $protocolPackName -folder $workingDir/$folderName; mv $protocolPackName $workingDir/$folderName";
	
	system("cd $clisimPath/stile/tools/src;./protocolPackGen.sh -v 3.9 -f $workingDir/$folderName/advanced_pdl.lst -i ../../../sys/stile/advanced_pdls -name $protocolPackName -folder $workingDir/$folderName; mv $protocolPackName $workingDir/$folderName");
	$returnValue = $?;
	print $returnValue;
}

sub load_on_clisim {
	my $output = '';
	my $expectObject = Expect->spawn("$clisimPath/stile/tools/simulator/src/clisim.x86_64 -A") || die "\nCannot spawn clisim: $!\n";
	#$expectObject->log_file("$workingDir/clisim.log","w");
	$expectObject->expect(10,"stile>");
	$expectObject->send("load protocol-pack $workingDir/$folderName/".getProtoPackName()."\r");
	addParameter("$workingDir/$folderName","currentPack", getProtoPackName());
	$expectObject->expect(10,"stile>");
	#$output .= $expectObject->before();
	#$expectObject->send("protocol $nameValueHash{'custom_protocol_name'}\r");
	$expectObject->send("protocol discovery\r");
	$expectObject->expect(10,"stile>");
	#$output .= $expectObject->before();
	$expectObject->send("show activated protocols\r");
	$expectObject->expect(10,"stile>");
	$output .= $expectObject->before();
	$expectObject->send("exit\r");
	$expectObject->soft_close();
	
	open( Log_File_Handler, ">$workingDir/$folderName/clisim.log" ) || die "\nError opening clisim log file for writing 2: \n'$!'\n";
	$output =~ s/\n/<br>/g;
	$output =~ s/ /&nbsp;/g;
	print Log_File_Handler $output;
	close Log_File_Handler;
}

##############################

### MAIN - Start of script

#die if not equal to 2 args
if ( scalar(@ARGV) != 2 ) {
	die "\n1. Usage:\n $0  <folder name> < 'default' | 'incremental' | <protocol-pack name> >\n\n";
}

$folderName = $ARGV[0];
$parameter = $ARGV[1];

if (!(-e "$workingDir/$folderName")) {
	die "\n2. Usage:\n $0  <folder name> < 'default' | 'incremental' | <protocol-pack name> >\nFolder $folderName does not exist...!\n\n";
}

@pdlFileNames = get_pdl_names();

if ( ($parameter eq 'default') || ($parameter eq 'incremental') ) {
	# 5. Create the pdl list file
	create_pdl_list_file();
	
	#4. Copy all custom pdls to ./Clisim/sys/stile and 
	#	generate pPack in /tmp/nbar	
	foreach my $fileName (@pdlFileNames) {
		system("cp $workingDir/$folderName/$fileName ./Clisim/sys/stile/advanced_pdls/;");
	}
	
	# 6. Create the protocol pack
	create_pPack();
	
	# Delete the pdl and pdlh files from sys/stile/advanced_pdls dir
	foreach my $fileName (@pdlFileNames) {
		unlink("$clisimPath/sys/stile/advanced_pdls/$fileName");
		unlink("$clisimPath/sys/stile/advanced_pdls/$fileName"."h");
	}
	
	# 8. Load it on clisim & analyze results
	load_on_clisim();
}
else {
	#ppack given, just load on clisim
	
	#first check id ppack exists or not
	if (!(-e "$workingDir/$folderName/$parameter")) {
		die "\n3. Usage:\n $0  <folder name> < 'default' | 'incremental' | <protocol-pack name> >\nProtocol pack $parameter does not exist...!\n\n";
	}
}

### End of script


#sub create_command_file {
#	open( Command_File_Handler, ">$workingDir/commandList" ) || die "\nError opening command file: \n$!\n";
#	print Command_File_Handler "load protocol-pack $workingDir/$protocolPackName\n";
#	print Command_File_Handler "protocol $nameValueHash{'custom_protocol_name'}\n";
#	print Command_File_Handler "show activated protocols\n";
	#print Command_File_Handler "load capture hello.cap\n";
	#print Command_File_Handler "exit\n";
#	close Command_File_Handler;
#}
