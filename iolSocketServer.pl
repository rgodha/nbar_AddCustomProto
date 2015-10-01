#!/usr/local/bin/perl5.8 -w

use strict;
use warnings;
use Socket;
use Expect;

## Variables #####
my $iolObject;
my $pagentObject;
my %iolObjectHash = ();
my %pagentObjectHash = ();
my $output;
my $iolPath;
my $pagentPath;
my $folderName;
my @timeouts = (2, 10 ,30 ,60 , 120);
##################

## Subroutines ###

sub startServer {
	# make the socket
	socket(Server, PF_INET, SOCK_STREAM, getprotobyname('tcp')) || die "socket: $!";;
	# so we can restart our server quickly
	setsockopt(Server, SOL_SOCKET, SO_REUSEADDR, 1) || die "setsock: $!";
	# build up my socket address
	my $my_addr = sockaddr_in(50001, INADDR_ANY);
	bind(Server, $my_addr) || die "Couldn't bind to port 50001 : $!\n";
	# establish a queue for incoming connections
	listen(Server, SOMAXCONN) || die "Couldn't listen on port 50001: $!\n";
	print "IOL-Pagent Server started: Port # 50,001..\n";
	# accept and process connections
	while(1) {
		##Testing Code#######
		##print the hash here
		foreach my $i ( sort keys %iolObjectHash ) {
			print "\n'$i' => '$iolObjectHash{$i}'\t\t";
			print "'$i' => '$pagentObjectHash{$i}'";
		}
		print "\nWaiting for client..\n";
		my $clientSocket = accept(Client, Server) || die "accept : $!";;
		print "Client connected..\n";
		# do something with new Client connection
		my $param = <Client>;
		chomp $param;
		print ">>>>$param<<<<";
		my $returnValue = runCommand($param);
		print Client "$returnValue\n";
		## no more writing to server
		#shutdown(Client, 1);    # Socket::SHUT_WR constant in v5.6
		close(Client);
	}
	close(Server);
}

sub runCommand {
	my @clientParams = split(":", $_[0]);
	my @temp;
	
	foreach my $var (@clientParams) {
		@temp = split('=',$var);
		if($temp[0] eq 'folder') {
			$folderName = $temp[1];
		}
		elsif($temp[0] eq 'iolPath') {
			$iolPath = $temp[1];
		}
		elsif($temp[0] eq 'pagentPath') {
			$pagentPath = $temp[1];
		}
	}

	if ( (exists($iolObjectHash{$folderName})) && (exists($iolObjectHash{$folderName})) ) {
		##iol object already exists in hash
		$iolObject = $iolObjectHash{$folderName};
		#if ($command eq 'exit') {
		#	$expectObject->send("exit\r");
		#	$expectObject->soft_close();
		#	$objectHash{$folderName} = undef;
		#	delete $objectHash{$folderName};
		#	print "<br>Exited successfully<br>";
		#}
		
		#$expectObject->send("$command\r");
		#if ($command eq 'run all') {
		#	$expectObject->expect(300,"stile>");
		#}
		#else {
		#	$expectObject->expect(5,"stile>");
		#}
		#$expectObject->expect(5,"stile>");
		#$output = $expectObject->before();
	}
	else {
		# load the iol image
		spawn_iol();
		# start protocol discovery
		conf_iol();
		# spawn the pagent
		spawn_pagent();
		# configure pagent		
		conf_pagent();
		
		#open CSV file to store output??
		
		
	}
	return $output;
}

sub spawn_iol {
    ## Start IOL
    $iolObject = Expect->spawn("$iolPath -m 1024 100") || die "\nIOLSocketServer cannot spawn IOL: $!\n";
    $iolObjectHash{$folderName} = $iolObject;
    
    $iolObject->expect(10, "Would you like to enter the initial configuration dialog? [yes/no]: ");
    $iolObject->send("no\r");
    
	$iolObject->expect(10, "Would you like to terminate autoinstall? [yes]: ");
	dyes
	
	$iolObject->expect(10, "Press RETURN to get started!");
	$iolObject->send("\r");
	$iolObject->expect(10, "Router>" );
	#$expectObject->log_file(getWorkingDirectory()."$clientParams[0]/clisim.log","w");
}

sub conf_iol {
    ## Configure IOL
	$iolObject->send("en\n");
	$iolObject->expect(10, "Router#" );
	$iolObject->send("terminal length 0 \n");
	$iolObject->expect(10, "Router#" );
	$iolObject->send("conf t\n");
	$iolObject->expect(10, "Router(config)#" );
	$iolObject->send("in e0/0\n");
	$iolObject->expect(10, "Router(config-if)#" );
	$iolObject->send( "ip nbar protocol-discovery\n", "end\n" );
	$iolObject->expect( 30, "Router#" );
}

sub spawn_pagent {
	## Start Pagent Traffic Generator
	$pagentObject = Expect->spawn( "$pagentPath -m 1024 150" ) || die "PagentSocketServer cannot spawn pagent: $! \n";
	$pagentObjectHash{$folderName} = $pagentObject;
	$pagentObject->expect( 10, "*Interface Serial2/2, changed state to administratively down" );
	$pagentObject->send("\r");
	$pagentObject->expect( 10, "Router>" );
}

sub conf_pagent {
	## Configure Pagent
    $pagentObject->send("en\n");
    $pagentObject->expect( 10, "Router#" );
}

## End of subroutines





## MAIN - Start of script

startServer();


## Sub-routines ##
