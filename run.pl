#!/usr/local/bin/perl5.8 -w

use strict;
use warnings;
use CGI;
require "common_subroutines.pl";

my $form = new CGI;
print $form->header; #Print HTML header. this is mandatory
my $command = $form->param('txt');
my $folderName = $form->param('timestamp');

#####Krish Code starts here#####
my $workingDir = getWorkingDirectory();
my %params = getParameters("$workingDir/$folderName");
my $output = '';
#my $prompt = '';

$command =~ s/^\s+//; ##remove whitespace from start of string
$command =~ s/\s+$//; ##remove whitespace from end of string

#[no] custom protocol <name> ==> not to be supported
#     dump attributes  ... => Unknown command
#     dump protocol attributes => Unknown command
#     internal dump  ... => dunno, do not support
#[no] load protocol-pack <filename> force
#[no] load protocol-pack <filename> => chk this while testing
#     show protocol-pack information  ... => Unknown Command
#     show protocol-pack information non-loaded <filename> => TO, handle filename
#     show sub-protocol  ...  => not supported
#     tests => not to be supported
#     write state nodes <file> => done

if ($command =~ m/^load capture .*/) {
#	print "<br>Found a load capture cmd<br>";
#	print "<br>Captures are : <br>";
#	foreach my $file (@{$params{'captureFile'}}) {
#		print "<br>$file";
#	}
	my @words = split (" capture ",$command);
	$words[1] = "$workingDir/$folderName/".$words[1];
	$command = $words[0]." capture ".$words[1];
#	$prompt = 'stile>';
}
elsif ($command =~ m/^(no )?load protocol-pack .*/) {
#	print "<br>Found a load ppack cmd<br>";
#	print "<br>Ppacks are : <br>";
#	foreach my $file (@{$params{'captureFile'}}) {
#		print "<br>$file";
#	}
	my @words = split (":",$command);
	if ( $words[1] eq 'onclick' ) {
		my $temp = "no load protocol-pack ".$params{'currentPack'};
		$output = connectToServer("name=$params{'protocolName'}:folder=$folderName:command=??\n");
		$command = $words[0];
	}

	@words = split (" protocol-pack ",$command);
	$words[1] = "$workingDir/$folderName/".$words[1];
	$command = $words[0]." protocol-pack ".$words[1];
#	$prompt = 'stile>';
}
elsif ($command =~ m/(write state nodes).*/) {
	$command = $1." $workingDir/$folderName/state.yml";
#	$prompt = 'stile>';
}
elsif ($command =~ m/^(no )?custom protocol .*/) {
	my @words = split (" protocol",$command);
	if ($#words > 2) {
		print "Output:<br><br>No space allowed in custom protocol name...<br>";
		exit;
	}
	if ( $words[1] =~ m/[a-z]*/ ) {
	}
	else {
		print "Output:<br><br>No uppercase alphabets allowed in custom protocol name...<br>";
		exit;
	}
#	$prompt = 'stile(custom-'.$words[1].')>';
#	print "expected prompt: $prompt";
}
#elsif ($command =~ m/^tests/) {
#}

#$output = connectToServer("name=$params{'protocolName'}:folder=$folderName:command=$command:cli_prompt=$prompt\n");
$output .= connectToServer("name=$params{'protocolName'}:folder=$folderName:command=$command\n");
$output =~ s/\n/<br>/g;
$output =~ s/ /&nbsp;/g;

print "Output:<br><br>$output<br>";

#####Krish Code  ends  here#####
