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
print $form->header; #Print HTML header. this is mandatory
#my $command = $form->param('txt');

my $folderName = $form->param('timestamp');

my $command = "exit";
my %params = getParameters($folderName);
my $output = connectToServer("name=$params{'protocolName'}:folder=$folderName:command=$command\n");

#system("rm -R ../chart/$folderName");

unlink("../chart/$folderName");

exit;
