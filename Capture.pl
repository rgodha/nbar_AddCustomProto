#!/usr/local/bin/perl5.8 -w

#############################################################################
#
#     Web Application Framework To Define NBAR Custom Protocol Classification
#     Author: Rahul Godha (rgodha@cisco.com)
#
##############################################################################

use strict;
use warnings;
use CGI;
require "common_subroutines.pl";

my $form = new CGI;

my $workingDir = getWorkingDirectory();
my $folderName = "";
$folderName = $form->param('timestamp');

my $filePath = "$workingDir/$folderName/Capture.xml";
print $form->header(-type=>'application/xml') ;

open(File_Handler, $filePath);
while (<File_Handler>) {
	print "$_"; 
}

close(File_Handler);
