#!/usr/local/bin/perl5.8 -w

use strict;
use warnings;
use Socket;
use CGI;
require "common_subroutines.pl";

my $form = new CGI;
print $form->header; #For HTML header

my $workingDir = getWorkingDirectory();
my $folderName = $form->param('time');
my $iolPath = $form->param('iolpath');
my $pagentPath = $form->param('pagentpath');

print "<script>parent.callback3(\'iolPath=$iolPath:folder=$folderName:pagentPath=$pagentPath\')</script>";

#####Krish Code starts here#####
#my %params = getParameters("$workingDir/$folderName");
my $output = '';
my $prompt = '';

#if ($command =~ m/^load capture .*/) {
##	print "<br>Found a load capture cmd<br>";
##	print "<br>Captures are : <br>";
##	foreach my $file (@{$params{'captureFile'}}) {
##		print "<br>$file";
##	}
#	my @words = split (" capture ",$command);
#	$words[1] = "$workingDir/$folderName/".$words[1];
#	$command = $words[0]." capture ".$words[1];
##	$prompt = 'stile>';
#}
#elsif ($command =~ m/^(no )?load protocol-pack .*/) {
##	print "<br>Found a load ppack cmd<br>";
##	print "<br>Ppacks are : <br>";
##	foreach my $file (@{$params{'captureFile'}}) {
##		print "<br>$file";
##	}
#	my @words = split (":",$command);
#	if ( $words[1] eq 'onclick' ) {
#		my $temp = "no load protocol-pack ".$params{'currentPack'};
#		$output = connectToServer("name=$params{'protocolName'}:folder=$folderName:command=??\n");
#		$command = $words[0];
#	}
#
#	@words = split (" protocol-pack ",$command);
#	$words[1] = "$workingDir/$folderName/".$words[1];
#	$command = $words[0]." protocol-pack ".$words[1];
##	$prompt = 'stile>';
#}
#elsif ($command =~ m/(write state nodes).*/) {
#	$command = $1." $workingDir/$folderName/state.yml";
##	$prompt = 'stile>';
#}
#elsif ($command =~ m/^(no )?custom protocol .*/) {
#	my @words = split (" protocol",$command);
#	if ($#words > 2) {
#		print "Output:<br><br>No space allowed in custom protocol name...<br>";
#		exit;
#	}
#	if ( $words[1] =~ m/[a-z]*/ ) {
#	}
#	else {
#		print "Output:<br><br>No uppercase alphabets allowed in custom protocol name...<br>";
#		exit;
#	}
##	$prompt = 'stile(custom-'.$words[1].')>';
##	print "expected prompt: $prompt";
#}
##elsif ($command =~ m/^tests/) {
##}

#$output = connectToServer("name=$params{'protocolName'}:folder=$folderName:command=$command:cli_prompt=$prompt\n");
#$output .= connectToServer("name=$params{'protocolName'}:folder=$folderName:command=$command\n");

print "iolPath=$iolPath:folder=$folderName:pagentPath=$pagentPath\n";
$output = connectToIOLServer("iolPath=$iolPath:folder=$folderName:pagentPath=$pagentPath\n");
$output =~ s/\n/<br>/g;
$output =~ s/ /&nbsp;/g;

print "Output:<br><br>'$output'<br>";

## Sub-routines
sub connectToIOLServer {
	#create a socket
	socket(Server, PF_INET, SOCK_STREAM, getprotobyname('tcp')) ||  die "socket: ";

	# build the address of the remote machine
	my $internet_addr = inet_aton("127.0.0.1")
		|| die "Couldn't convert 127.0.0.1 into an Internet address: $!\n";
	my $paddr = sockaddr_in(50001, $internet_addr);
	
	# connect to server
	#print "<br>Connecting to server. . .<br>";
	connect(Server, $paddr) ||
		die "Couldn't connect to 127.0.0.1:50001 : $!\n";

	select((select(Server), $| = 1)[0]); # enable command buffering
	
	# send something over the socket
	print Server "$_[0]";
		
	## no more writing to server
	shutdown(Server, 1);
	
	# read the remote answer
	my $answer = '';
	while(<Server>) {
		$answer .= $_;
	}
	
	# terminate the connection when done
	close(Server);
	return $answer;
}

#####Krish Code  ends  here#####
