#!/usr/local/bin/perl5.8 -w

#############################################################################
#
#     Web Application Framework To Define NBAR Custom Protocol Classification
#     Author: Rahul Godha (rgodha@cisco.com)
#
##############################################################################

use strict;
use warnings;
use XML::Simple;
use Data::Dumper;
use XML::XPath;
use XML::XPath::XMLParser;
require "common_subroutines.pl";

print "Content-Type: text/html \n\n";
print <<HTML;
<html><head><title>DPI SDK OUTPUT</title> 
<script type="text/javascript">

function goBackPage(){
var HomeURL = document.referrer ;
alert("Thank You, for using NBAR Custom PDL Generation And Classification Wizzard. ");
window.location.href = HomeURL ;
}

</script>

</head> 
<body>
<div id="backPage" style="margin:120px 0 0 150px; float:left; border:1px #000; ">
<input type="button" value="Go Back" ONCLICK="goBackPage();" >
</div>
<div style="margin:100px 0 0 20px; float:left;" class="registration" >

HTML

#my $ContentSize = 0;
#$ContentSize = $ENV{'CONTENT_LENGTH'};
#print "<h3> Content Size: $ContentSize.  </h3>";

#if( $ContentSize == "" || $ContentSize == 0 ){
#print "<h3> No Content Received.  </h3>";
#exit;
#}

	my($buffer) = "";
	
	if($ENV{'REQUEST_METHOD'} eq 'GET') {
		$buffer = $ENV{'QUERY_STRING'};
	} else {
	read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
	}
	
	
## Variable Declaration
my %FORM=();
my $pair="";
my $key="";
my $offset="";
my $pattern=""; my $value="";
my $appid="";
my $version="off";
my $name="";
my $size="";
my $pat_type="";
my $ProtocolType="off"; my $SrcPort="off"; my $DestPort="off";


my @pairs = split(/&/, $buffer);
foreach $pair (@pairs) {
    my($name, $value) = split(/=/, $pair);
    $value =~ tr/+/ /;
    $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
    $FORM{$name} = $value;
}

foreach $key (keys(%FORM)) {
	
	#if($key eq "pattern") { $pattern = $FORM{$key}; }
	#if($key eq "app-id") { $appid = $FORM{$key}; }
	if($key eq "version"){ $version = $FORM{$key}; }
	if($key eq "name") { $name = $FORM{$key}; }
	if($key eq "size") { $size = $FORM{$key}; }
	if($key eq "pat_type") { $pat_type = $FORM{$key}; }
	if($key eq "payload-offset") { $offset = $FORM{$key}; }
	if($key eq "value"){ $value = $FORM{$key}; }

	if($key eq "ProtocolType"){
		$ProtocolType = $FORM{$key};
	}
	
	if($key eq "SrcPort"){
		if($FORM{$key} eq "") { $SrcPort = "off"; 
		} else {
		$SrcPort = $FORM{$key};
		}
	}
	if($key eq "DestPort"){
		if($FORM{$key} eq "") { $DestPort = "off"; 
		} else {
		$DestPort = $FORM{$key};
		}
	}
}

#foreach $key (keys(%FORM)) {
#	print "$key = $FORM{$key}<br>";
#}

my $xml = XMLin('nsdk.xml', KeepRoot => 1,ForceArray => 1 );
$xml->{nsdk}->[0]->{custom}->[0]->{protocol_name} = "$name" ;

if ( $version ne "off" ){
$xml->{nsdk}->[0]->{custom}->[0]->{version} = "$version";
}

$xml->{nsdk}->[0]->{custom}->[0]->{app_id} = "ID";
$xml->{nsdk}->[0]->{custom}->[0]->{match}->[0]->{protocol}->[0]->{type} = "$ProtocolType";

if( $SrcPort eq "off" && $DestPort eq "off"){
$xml->{nsdk}->[0]->{custom}->[0]->{match}->[0]->{protocol}->[0]->{port}->[0]->{type} = "any";
$xml->{nsdk}->[0]->{custom}->[0]->{match}->[0]->{protocol}->[0]->{port}->[0]->{value} = "all";
}


if( $SrcPort =~ /^(\d{1,5})$/ ){
$xml->{nsdk}->[0]->{custom}->[0]->{match}->[0]->{protocol}->[0]->{port}->[0]->{type} = "source";
$xml->{nsdk}->[0]->{custom}->[0]->{match}->[0]->{protocol}->[0]->{port}->[0]->{value} = "$SrcPort";
} else {
if( $DestPort =~ /^(\d{1,5})$/ ){
$xml->{nsdk}->[0]->{custom}->[0]->{match}->[0]->{protocol}->[0]->{port}->[0]->{type} = "destination";
$xml->{nsdk}->[0]->{custom}->[0]->{match}->[0]->{protocol}->[0]->{port}->[0]->{value} = "$DestPort";
}
}

if($offset ne ""){
$xml->{nsdk}->[0]->{custom}->[0]->{match}->[0]->{protocol}->[0]->{pattern}->[0]->{type} = "$pat_type";
#$xml->{nsdk}->[0]->{custom}->[0]->{match}->[0]->{protocol}->[0]->{pattern}->[0]->{size} = "$size";
$xml->{nsdk}->[0]->{custom}->[0]->{match}->[0]->{protocol}->[0]->{pattern}->[0]->{value} = "$value";
$xml->{nsdk}->[0]->{custom}->[0]->{match}->[0]->{protocol}->[0]->{pattern}->[0]->{payload_offset} = "$offset";
}
#################### GetFormDate Page Formating ######### 

print "<fieldset><legend> Results </legend>";

#################################################
#Create /tmp/nbar_sdk folder
my $folderName = getTimestamp();
my $workingDir = getWorkingDirectory();
system("mkdir -p $workingDir/$folderName");

#######################################
XMLout($xml, KeepRoot => 1, OutputFile => "$workingDir/$folderName/$name.xml");
		print "<p> XML Generated Successfully.&nbsp;&nbsp;&nbsp;<a href='/cgi-bin/download.pl?file=xml&timestamp=$folderName' target='_blank'>View</a><i>&nbsp;&nbsp;(opens in new window)</i></p>";


#################################################
#Create a parameters file
addParameter("$workingDir/$folderName","protocolName","$name");

#################################################
#Calling PDL gen script here
my $output='';
generatePDL();

#################################################

print "</fieldset><br><br>";

################ HTML file to upload Capture #############

print <<HTML;
<fieldset>
<legend> Load Capture or pPack </legend>
<br>

<table width="100%" border="0">
  <tr>
    <td>
    	<table width="90%" border="0" cellspacing="2" cellpadding="2" style="border-right: 1px solid #fff" >
		  <tr height="50px" >
    		    <td colspan="3" class="FormLabel" style="text-align:left; font-weight:lighter " > 
    		    	<form action="ajax_upload.pl" id="form1" encType="multipart/form-data"  method="POST" target="hidden_frame" >
			<input type="hidden" value="$folderName" name="timestamp" id="timestamp" >
			 Load Capture : <input type="file" class="FormInput" id="upfile" name="upfile"></td>
			         <!--<INPUT type="submit" id="test" value="submit">--> 
    		    </td>
    		  </tr>
    		  <tr height="40px" >  
		    <td colspan="3"> <span id="msg" style="text-align:right;" > &nbsp; </span></td>
			<iframe name='hidden_frame' id="hidden_frame" style='display:none;'></iframe>
			</form>
		    </td>
		  </tr>
		  <tr height="50px" >
		    <td>
		    	<select id="AddCapture" style="padding:3px;" >
		    		<option> --- Select --- </option>
		    	</select>
		    </td>
		     <td> <input type="button" name="RCapture1" id="RCapture1" value="Run Capture" style="font-size: 12px; padding:4px;" >   </td>
		    <td width="180px" >&nbsp;</td>
		  </tr>
		</table>
   </td>
   <td>
    	<table width="100%" border="0" cellspacing="2" cellpadding="2">
    		 <tr height="50px" >
    		     <td colspan="3" class="FormLabel" style="text-align:left; font-weight:lighter" > 
    		    	<form action="ajax_upload_pPack.pl" id="form2" encType="multipart/form-data"  method="POST" target="hidden_frame2" >
			<input type="hidden" value="$folderName" name="timestamp2" id="timestamp2" >
			 Load pPack : <input type="file" class="FormInput" id="upfile2" name="upfile2"></td>
		       	  <!--<INPUT type="submit"  id="test2" value="submit">--> 
    		    </td>
    		 </tr>
		  <tr height="40px" >
		    <td colspan="3"> <span id="msg2" style="text-align:right;" > &nbsp; </span></td>
			<iframe name='hidden_frame2' id="hidden_frame2" style='display:none;'></iframe>
			</form>
		    </td>
		  </tr>
		  <tr height="50px" >
		    <td>
		    	<select id="AddpPack" style="padding:3px;" >
		    		<option> --- Select --- </option>
		    	</select>
		    </td>
		    <td><input type="button" name="lpPack" id="lpPack" value="Load pPack" style="font-size: 12px; padding:4px;" > </td>
		    <td width="180px" >&nbsp;</td>
		  </tr>
		</table>
   
   </td>
  </tr>
</table>
</fieldset>

<br><br>
<fieldset>
   <legend> StILE Simulator </legend>
<br>
<span id="StartStile" style="cursor: pointer"> Click Here To <span id="StartStop"> Start </span> Debugging. </span>
<br><br>
<div id="stile" style="display: none;" >
<table border="0" > 
<tr>
<td width="160px" class="FormLabel" style="text-align:left;"> Type Command: </td>
<td width="240px" ><input type="text" class="ui-widget" id="tags" name="CommandBox" size="24" style="-moz-box-shadow: 0 1px 2px rgba(0,0,0,0.5);
  -webkit-box-shadow: 0 1px 3px rgba(0,0,0,0.5);
  -webkit-border-radius: 5px;
  -moz-border-radius: 3px;" ></td>
<td width="60px" ><span> <input type="button" id="enter" value="  Enter  " style="padding:4px; font-weight: bold;" /> </span> </td>
<td width="140px" ><span id="ProgressBar"> &nbsp; </span> </td>
</tr>
<tr>
  <td colspan="4"><span id="DownloadFile" style="display:none;" > Click <a href="/tmp/nbar_sdk/$folderName/base.pdl"> here </a> to download state.yml file. </span> </td>
</tr>
</table>
<br><p> Output : </p>
<div id="Division" style="background-color:#000; margin-left:30px; color:white; font-size: 12px; overflow: auto; height:300px; width:680px;
  -moz-box-shadow: 0 1px 2px rgba(0,0,0,0.5);
  -webkit-box-shadow: 0 1px 3px rgba(0,0,0,0.5);
  -webkit-border-radius: 5px;
  -moz-border-radius: 3px; ">
<span id="textarea" style="font-family: monospace;" >
HTML

##
if($output ne '') { print $output;}
##

print <<HTML;
</span>
<!--<div> stile > <input type="text" id="text2" /> </div>-->
</div>
<br>
</div>
</fieldset>
<br>
<script type="text/javascript" language="javascript" src="../nbar_sdk/jquery.js"></script>
<script src="../nbar_sdk/autocomplete/jquery.ui.core.js" type="text/javascript" charset="utf-8"></script>
<script src="../nbar_sdk/autocomplete/jquery.ui.widget.js" type="text/javascript" charset="utf-8"></script>
<script src="../nbar_sdk/autocomplete/jquery.ui.position.js" type="text/javascript" charset="utf-8"></script>
<script src="../nbar_sdk/autocomplete/jquery.ui.autocomplete.js" type="text/javascript" charset="utf-8"></script>
<script type="text/javascript" language="javascript" src="../nbar_sdk/effects.js" ></script>
<link rel="stylesheet" type="text/css" href="../nbar_sdk/style.css" />
<link rel="stylesheet" type="text/css" href="../nbar_sdk/autocomplete/autocomplete.css" />
HTML

print "<br></div></body></html>";
#################################################################


##Krish's subroutines
sub getTimestamp {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time); 
	$year += 1900;
	$mon+=1;
	return "$year.$mon.$mday.$hour.$min.$sec";
}

sub generatePDL {
	my $returnValue = `./generate_pdl.pl $folderName`;
	#my $temp = grep {/(E|e)rror/} $returnValue;
	#print "=====>>".$temp."<<=====";
	if ( (grep {/(E|e)rror/} $returnValue) == 0 ) {
		print "<p> PDL Generated Successfully.&nbsp;&nbsp;&nbsp;<a href='/cgi-bin/download.pl?file=pdl&timestamp=$folderName' target='_blank'>View</a><i>&nbsp;&nbsp;(opens in new window)</i></p>";
		open( Log_File_Handler, "$workingDir/$folderName/clisim.log" ) || die "\nError opening clisim log file for reading: \n'$!'\n";
		while(<Log_File_Handler>) {
			$output .= "$_";
		}
		close Log_File_Handler;
		##Delete the clisim.log file
		unlink("$workingDir/$folderName/clisim.log");
	}
	else {
		print "<p>Internal Server Error. Cannot generate PDL.</p>";
		#clear pPack cache for resolving this
		exit (5);
	}
}

#######################################

