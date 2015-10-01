#!/usr/local/bin/perl5.8 -w

##############################
## Libraries
use strict;
use warnings;
use Socket;
##############################

sub getWorkingDirectory {
	#Hardcoded value needs to be changed
	#global variable
	return "/tmp/nbar_sdk/";
}

sub getProtoPackName {
	#Hardcoded value needs to be changed
	#global variable
	return "pPack.pack";
}

sub getSimulatorPath {
	#Hardcoded value needs to be changed
	#global variable
	return "./Clisim/";
}

#sub getParameters {
#	my $dirName = $_[0];
#	my %params = ();
#	my $line = '';
#	my $key = '';
#	my $value = '';
#	
#	open( Params_File_Handler, "$dirName/params.file" ) || die "\nError opening parameters file for reading: \n'$!'\n";
#	
#	while(<Params_File_Handler>) {
#		($key, $value) = split(":"); #implicitly splits $_
#		#strip newlines from $value
#		chomp($value);
#		$params{$key} = $value;
#	}
#	close Params_File_Handler;
#	###Testing Code#######
#	#print the hash here
#	#foreach my $i ( keys %params ) {
#	#	print "'$i' => '$params{$i}'\n";
#	#}
#	return %params;
#}

sub addParameter {
	my $dirName = $_[0];
	my $key = $_[1];
	my $value = $_[2];

	#The filename params.file contains all the parameters required for a session.
	#The filename is hardcoded
	my $paramFilename = "params.file";
	
	if (-e "$dirName/params.file") {
		open( Params_File_Handler, ">>$dirName/$paramFilename" ) || die "\nError opening parameters file for writing: \n'$!'\n";
		print Params_File_Handler "\n$key:$value";
		close Params_File_Handler;	
	}
	else {
		open( Params_File_Handler, ">$dirName/$paramFilename" ) || die "\nError creating parameters file: \n'$!'\n";
		print Params_File_Handler "$key:$value";
		close Params_File_Handler;
	}
	
	###Testing Code#######
	#print the hash here
	#foreach my $i ( keys %params ) {
	#	print "'$i' => '$params{$i}'\n";
	#}
	return 1;
}

sub getParameters {
	my $dirName = $_[0];
	my %params = ();
	my $line = '';
	my $key = '';
	my $value = '';
	
	my $captureExists = 0;
	my @captureNames = ();
	
	open( Params_File_Handler, "$dirName/params.file" ) || die "\nError opening parameters file for reading: \n'$!'\n";
	while(<Params_File_Handler>) {
		($key, $value) = split(":"); #implicitly splits $_
		#strip newlines from $value
		chomp($value);
		#if ($key eq 'captureFile') {
			##TODO chk if file already exists in array or not!
			#if exists, do not push again
			#if not exists, push into array
		#	my $valueExists = 0;
		#	foreach my $item (@{ $params{'captureFile'} }) {
		#		if ($value eq $item) {
		#			$valueExists = 1;
		#			last;
		#		}
		#	}
		#	if ($valueExists == 0) {
		#		push(@{$params{'captureFile'} }, $value);
		#	}
		#}
		#else {
			$params{$key} = $value;
		#}
	}
	close Params_File_Handler;
	###Testing Code#######
	#print the hash here
	#foreach my $i ( keys %params ) {
	#	if ($i eq 'captureFile') {
	#		print "<br>'$i' => '$params{$i}'\n";
	#		foreach my $var (@{$params{'captureFile'}}) {
	#			print "<br>'$var'\n";
	#		}
	#	}
	#	else {
	#		print "<br>'$i' => '$params{$i}'\n";
	#	}
	#}
	return %params;
}

sub connectToServer {
	#create a socket
	socket(Server, PF_INET, SOCK_STREAM, getprotobyname('tcp')) ||  die "socket: ";

	# build the address of the remote machine
	my $internet_addr = inet_aton("127.0.0.1")
		|| die "Couldn't convert 127.0.0.1 into an Internet address: $!\n";
	my $paddr = sockaddr_in(50000, $internet_addr);
	
	# connect to server
	#print "<br>Connecting to server. . .<br>";
	connect(Server, $paddr) ||
		die "Couldn't connect to 127.0.0.1:50000 : $!\n";

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

1; #must return true

