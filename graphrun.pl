#!/usr/local/bin/perl5.8 -w

use strict;
use warnings;
use CGI;
require "common_subroutines.pl";

my $form = new CGI;
print $form->header; #Print HTML header. this is mandatory
my $command = $form->param('txt');
my $folderName = $form->param('timestamp');


my $workingDir = getWorkingDirectory();
my %params = getParameters("$workingDir/$folderName");
my $output = '';
$command =~ s/^\s+//; ##remove whitespace from start of string
$command =~ s/\s+$//; ##remove whitespace from end of string

if ($command =~ m/^load capture .*/) {
#	print "<br>Found a load capture cmd<br>";
#	print "<br>Captures are : <br>";
#	foreach my $file (@{$params{'captureFile'}}) {
#		print "<br>$file";
#	}
	my @words = split (" capture ",$command);	
	$words[1] = "$workingDir/$folderName/".$words[1];
	$command = $words[0]." capture ".$words[1];
}

$output = connectToServer("name=$params{'protocolName'}:folder=$folderName:command=$command\n");
#$output =~ s/\n/<br>/g;
#$output =~ s/ /&nbsp;/g;

## Output Formatting 

my @protocols = "";

my @lines = split /\n/, $output;

foreach my $line (@lines) {
	if ( $line =~ /^\s*\d+\s*[->]+\s*(.*)\s*[:]/ ) {
		push(@protocols, $1);
	}
}

@protocols = sort(@protocols);
#foreach my $p (@protocols)
#{ print $p, " "; }
my $count = 1;
my %mydata = ();

for(my $i = 0 ; $i < $#protocols+1 ; $i++){
	while( $protocols[$i] eq $protocols[$i+1] ){
		$count++;	
		$i++;
	}
	$mydata{$protocols[$i]} = $count ;
	$count = 1;
}

my $CaptureXML = "$workingDir/$folderName/Capture.xml" ;

open( INFILE, ">$CaptureXML" )  || die "\nError opening file: \n'$!'\n";
print INFILE "<graph caption='Capture Analysis' xAxisName='Protocols' yAxisName='Units' showNames='1' bgColor='CCC9FF' canvasBgColor='ffffff' decimalPrecision='0' formatNumberScale='0'>\n";

 delete($mydata{""});
 while ( my ($key, $value) = each(%mydata) ) {
   #print "$key => $value\n";
   if( $key =~ /<.*/ ){
  	print INFILE "<set name='unknown' value='$value' />\n";
	} else {
		print INFILE "<set name='$key' value='$value' />\n";
   	}
 }
#print INFILE "<set name='Total' value='$#protocols' />\n"; 

print INFILE "</graph>";
close(INFILE);

#print "$output";

#####Krish Code  ends  here#####
