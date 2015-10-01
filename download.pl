#!/usr/local/bin/perl5.8 -w

use strict;
use warnings;
use CGI;
require "common_subroutines.pl";

#$CGI::DISABLE_UPLOADS = 1;

my $form = new CGI;
#print $q->header(-type=>'text/html'),
#         $q->start_html(-title=>'Error'),
#         $q->h3("Error: $_[0]"),
#         $q->end_html;

my $workingDir = getWorkingDirectory();
my $folderName = $form->param('timestamp');
my $fileName = $form->param('file');
#my %params = getParameters("$workingDir/$folderName");
my $filePath = "$workingDir/$folderName/$fileName";
my @temp = split('\.',$fileName);
my $fileType = $temp[1];

if ($fileType eq 'xml') {
	print $form->header(-type=>'application/xml') ;
}
else {
	print $form->header(-type=>'text/plain') ;
}
 
#elsif ($fileType eq 'pdl') {
#	print $form->header(-type=>'text/plain') ;
#} elsif ($fileType eq 'yml') {
#	print $form->header(-type=>'text/plain') ;
#}

open(File_Handler, $filePath);
while (<File_Handler>) {
	print "$_"; 
}

close(File_Handler);
