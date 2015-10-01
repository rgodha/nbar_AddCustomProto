#!/usr/local/bin/perl5.8 -w

#############################################################################
#
#     Web Application Framework To Define NBAR Custom Protocol Classification
#     Author: Rahul Godha (rgodha@cisco.com)
#
##############################################################################

use warnings;
use strict;
use CGI;
require "common_subroutines.pl";

my $form = new CGI;
print $form->header; #Print HTML header. this is mandatory

#$CGI::POST_MAX = 1024 * 5000;  # Max file Size to Upload 5 MB
my $size = $ENV{'CONTENT_LENGTH'};

if( $size > 5120000 ){
	print "<script>parent.callback2('Problem Uploading your file ( try smaller file ).')</script>";
	exit;
}

my $workingDir = getWorkingDirectory();
my $folderName = $form->param('timestamp2');
my $captureFile = $form->param('upfile2');
my $UPLOAD_FH = $form->upload("upfile2");

if( !$captureFile ){
	print $form->header ( ); 
	print "<script>parent.callback2('Problem Uploading your file (Try Again).')</script>";
	exit; 
}


umask 0000; #This is needed to ensure permission in new file

open my $NEWFILE_FH, "+>", "$workingDir/$folderName/$captureFile" 
    or die "Problems creating file '$captureFile': $!";

while ( <$UPLOAD_FH> ) {
    print $NEWFILE_FH "$_";
}

close $NEWFILE_FH or die "I cannot close filehandle: $!";

##this is the only way to send msg back to the client
print "<script>parent.callback2('Uploaded $captureFile')</script>";

exit;

#END OF SCRIPT
##############
