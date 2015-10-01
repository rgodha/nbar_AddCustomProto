#!/usr/local/bin/perl5.8 -w

use strict;
use warnings;
use Socket;
use Expect;
require "common_subroutines.pl";

my $workingDir = getWorkingDirectory();
my $clisimPath = getSimulatorPath();
my $expectObject;
my %objectHash = ();
my $output;

# make the socket
socket(Server, PF_INET, SOCK_STREAM, getprotobyname('tcp')) || die "socket: $!";;

# so we can restart our server quickly
setsockopt(Server, SOL_SOCKET, SO_REUSEADDR, 1) || die "setsock: $!";

# build up my socket address
my $my_addr = sockaddr_in(50000, INADDR_ANY);
bind(Server, $my_addr) || die "Couldn't bind to port 50000 : $!\n";

# establish a queue for incoming connections
listen(Server, SOMAXCONN) || die "Couldn't listen on port 50000: $!\n";

print "Server started: Port # 50,000..\n";
# accept and process connections
while(1) {

	##Testing Code#######
	##print the hash here
	foreach my $i ( sort keys %objectHash ) {
		print "\n'$i' => '$objectHash{$i}'";
	}

	print "\nWaiting for client..\n";
	my $clientSocket = accept(Client, Server) || die "accept : $!";;
	print "Client connected..\n";
    # do something with new Client connection
	my $param = <Client>;
	chomp $param;
	my $returnValue = runCommand($param);
	print Client "$returnValue\n";
	## no more writing to server
	#shutdown(Client, 1);    # Socket::SHUT_WR constant in v5.6
	close(Client);
}
close(Server);


## Sub-routines ##
sub runCommand {
	my @clientParams = split(":", $_[0]);
	my @temp;
	my $folderName;
	my $command;
	my $captureFile;
	my $protocolName;
	
	foreach my $var (@clientParams) {
		@temp = split('=',$var);
		if($temp[0] eq 'folder') {
			$folderName = $temp[1];
		}
		elsif($temp[0] eq 'command') {
			$command = $temp[1];
		}
		elsif($temp[0] eq 'capture') {
			$captureFile = $temp[1];
		}
		elsif($temp[0] eq 'name') {
			$protocolName = $temp[1];
		}
	}
	
	if (exists($objectHash{$folderName})) {
		##object already exists in hash
		$expectObject = $objectHash{$folderName};
		if ($command eq 'exit') {
			$expectObject->send("exit\r");
			$expectObject->soft_close();
			$objectHash{$folderName} = undef;
			delete $objectHash{$folderName};
			print "<br>Exited successfully<br>";
		}
		
		$expectObject->send("$command\r");
		if ($command eq 'run all') {
			$expectObject->expect(300,"stile>");
		}
		else {
			$expectObject->expect(5,"stile>");
		}
		$output = $expectObject->before();
	}
	else {
		$expectObject = Expect->spawn("$clisimPath/stile/tools/simulator/src/clisim.x86_64 -A") || die "\nServer cannot spawn clisim: $!\n";
		$objectHash{$folderName} = $expectObject;
		#$expectObject->log_file(getWorkingDirectory()."$clientParams[0]/clisim.log","w");
		$expectObject->expect(5,"stile>");
		$expectObject->send("load protocol-pack $workingDir/$folderName/".getProtoPackName()."\r");
		addParameter("$workingDir/$folderName","currentPack", getProtoPackName());
		$expectObject->expect(5,"stile>");
		$expectObject->send("protocol discovery\r");
		$expectObject->expect(5,"stile>");
		$expectObject->send("$command\r");
		if ($command eq 'run all') {
			$expectObject->expect(300,"stile>");
		}
		else {
			$expectObject->expect(5,"stile>");
		}
		$output = $expectObject->before();
		#addParameter("$workingDir/$folderName","current_prompt",$cli_prompt);
	}
	return $output;
}

