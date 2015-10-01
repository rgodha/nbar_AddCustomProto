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
use File::Temp;
require "common_subroutines.pl";

my $SelectedXML="";
my $folderName = getTimestamp();

print "Content-Type: text/html \n\n";
print <<HTML;
<html><head><title>DPI SDK OUTPUT</title> 
<link rel="stylesheet" type="text/css" href="../../../nbar_sdk/style.css" />
<link rel="stylesheet" type="text/css" href="../../../nbar_sdk/autocomplete/autocomplete.css" />
<script type="text/javascript" language="javascript" src="../../../nbar_sdk/jquery.js"></script>
<script type="text/javascript" language="javascript" src="../../../nbar_sdk/chart/FusionCharts.js"></script>

<script type="text/javascript">

function goBackPage(){
var HomeURL = document.referrer ;
alert("Thank You, for using NBAR Custom PDL Generation And Classification Wizzard. ");
window.location.href = HomeURL ;
}


function DisplayXML(){

	 var SelectedXML = \$('#GeneratedXML').val();
	  alert( SelectedXML );
	 window.open('/cgi-bin/download.pl?file='+SelectedXML+'.xml&timestamp=$folderName','_blank');
	
}

</script>

</head> 
<body>
<div id="backPage" style="margin:120px 0 0 150px; float:left;">
<input type="button" value="Go Back" id="goback" ONCLICK="goBackPage();" class="EndButton" style="width: 100px;" >
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
my $custom_url="";
my $custom_host="";
my $pat_type="";
my $ProtocolType="off"; my $SrcPort="off"; my $DestPort="off";
my $pPackType ="";
my $pattern_name="";
my $pattern_size="";
my $CustomBuffers="";
my $r=0;
my @XMLarray="";

#################################################
#Create /tmp/nbar_sdk folder

#my $folderName = getTimestamp();
my $workingDir = getWorkingDirectory();
system("mkdir -p $workingDir/$folderName");


##################################################

#print $buffer."<br><br>";
my @CustomPairs = split(/&rahul=godha&/, $buffer);   ## Split attribute.

foreach my $CustomPair (@CustomPairs){
$r++;
my @pairs = split(/&/, $CustomPair);
foreach $pair (@pairs) {
    my($name, $value) = split(/=/, $pair);
    $value =~ tr/+/ /;
    $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
    $FORM{$name} = $value;
}


foreach $key (keys(%FORM)) {
	
	if($key eq "version".$r){ $version = $FORM{$key}; }
	if($key eq "name".$r) { $name = $FORM{$key}; }
	if($key eq "size".$r) { $size = $FORM{$key}; }
	if($key eq "appid".$r) { $appid = $FORM{$key}; }
	if($key eq "pat_type".$r) { $pat_type = $FORM{$key}; }
	if($key eq "payload-offset".$r) { $offset = $FORM{$key}; }
	if($key eq "value".$r){ $value = $FORM{$key}; }
	if($key eq "custom_url".$r) { $custom_url = $FORM{$key}; }
	if($key eq "custom_host".$r){ $custom_host = $FORM{$key}; }
	if($key eq "pPackType") { $pPackType = $FORM{$key}; }
	if($key eq "pattern_name".$r) { $pattern_name = $FORM{$key}; }
	if($key eq "pattern_size".$r) { $pattern_size = $FORM{$key}; }

	if($key eq "ProtocolType".$r){
		$ProtocolType = $FORM{$key};
	}
	
	if($key eq "SrcPort".$r){
		if($FORM{$key} eq "") { $SrcPort = "off"; 
		} else {
		$SrcPort = $FORM{$key};
		}
	}
	if($key eq "DestPort".$r){
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

$xml->{nsdk}->[0]->{custom}->[0]->{app_id} = "$appid";

## If Custom Host or URL Selected.
if ($custom_url ne "" || $custom_host ne ""){

if($custom_url ne "")
{
$xml->{nsdk}->[0]->{custom}->[0]->{match}->[0]->{pattern}->[0]->{url} = "$custom_url";
}
if($custom_host ne "")
{
$xml->{nsdk}->[0]->{custom}->[0]->{match}->[0]->{pattern}->[0]->{host} = "$custom_host";
}

} else {
## If Protocol Type or Offset is Selected.

$xml->{nsdk}->[0]->{custom}->[0]->{match}->[0]->{protocol}->[0]->{type} = "$ProtocolType";

my $allports = 0;
if( $SrcPort eq "off" && $DestPort eq "off"){
$xml->{nsdk}->[0]->{custom}->[0]->{match}->[0]->{protocol}->[0]->{port}->[0]->{type} = "any";
$xml->{nsdk}->[0]->{custom}->[0]->{match}->[0]->{protocol}->[0]->{port}->[0]->{value} = "all";
$allports = 1;
}


if($allports == 0 ){
if( $SrcPort ne "off"){
$xml->{nsdk}->[0]->{custom}->[0]->{match}->[0]->{protocol}->[0]->{port}->[0]->{type} = "source";
$xml->{nsdk}->[0]->{custom}->[0]->{match}->[0]->{protocol}->[0]->{port}->[0]->{value} = "$SrcPort";
} else {
#if( $DestPort =~ /^(\d{1,5})$/ ){
$xml->{nsdk}->[0]->{custom}->[0]->{match}->[0]->{protocol}->[0]->{port}->[0]->{type} = "destination";
$xml->{nsdk}->[0]->{custom}->[0]->{match}->[0]->{protocol}->[0]->{port}->[0]->{value} = "$DestPort";
#}
}
}

if($offset ne ""){
	if($pat_type eq "variable"){

	$xml->{nsdk}->[0]->{custom}->[0]->{match}->[0]->{protocol}->[0]->{pattern}->[0]->{type} = "$pat_type";
	$xml->{nsdk}->[0]->{custom}->[0]->{match}->[0]->{protocol}->[0]->{pattern}->[0]->{payload_offset} = "$offset";
	$xml->{nsdk}->[0]->{custom}->[0]->{match}->[0]->{protocol}->[0]->{pattern}->[0]->{pattern_name} = "$pattern_name";
	$xml->{nsdk}->[0]->{custom}->[0]->{match}->[0]->{protocol}->[0]->{pattern}->[0]->{pattern_size} = "$pattern_size";

	}else{
	$xml->{nsdk}->[0]->{custom}->[0]->{match}->[0]->{protocol}->[0]->{pattern}->[0]->{type} = "$pat_type";
	$xml->{nsdk}->[0]->{custom}->[0]->{match}->[0]->{protocol}->[0]->{pattern}->[0]->{value} = "$value";
	$xml->{nsdk}->[0]->{custom}->[0]->{match}->[0]->{protocol}->[0]->{pattern}->[0]->{payload_offset} = "$offset";
	}
}

}
#################### GetFormDate Page Formating ######### 


#######################################
XMLout($xml, KeepRoot => 1, OutputFile => "$workingDir/$folderName/$name.xml");

## Count to no of XML formed

$XMLarray[$r-1] = $name;

#################################################
#Create a parameters file
addParameter("$workingDir/$folderName","protocolName","$name");

}   ### Loop Closed

print "<fieldset><legend> Results </legend>";
print "<p> XML Generated Successfully.&nbsp;&nbsp;&nbsp;

<select name=\"GeneratedXML\" id=\"GeneratedXML\" style=\"width:200px\"  ONCHANGE=\"DisplayXML();\" >";

for(my $XMLCount=0 ; $XMLCount<=$#XMLarray ; $XMLCount++){
print "<option value=\"$XMLarray[$XMLCount]\" >$XMLarray[$XMLCount]</option>";
}

print "</select><i>&nbsp;&nbsp;(opens in new window)</i></p>";

#################################################
#Calling PDL gen script here
my $output='';
generatePDL();

#################################################

print "</fieldset><br><br>";

######   Calling Protocol Pack Generate Tool

if($pPackType eq "tool"){
#print "<script>window.open('http://bgl-ads-521:50002?timestamp=$folderName','_blank');</script>";
}

################ HTML file to upload Capture #############

print <<HTML;
<fieldset>
<legend> Load Capture </legend>
<br>
    	<table width="90%" border="1" cellspacing="2" cellpadding="2" >
		  <tr >
    		 <td colspan="3" class="FormLabel" style="text-align:left; font-weight:lighter " > 
    		  	<form action="ajax_upload.pl" id="form1" encType="multipart/form-data"  method="POST" target="hidden_frame" >
				<input type="hidden" value="$folderName" name="timestamp" id="timestamp" >
			 	Load Capture : <input type="file" class="FormInput" id="upfile" name="upfile"></td>
			    <!--<INPUT type="submit" id="test" value="submit">--> 
    		 </td>
    	  </tr>
    	  <tr >  
		    <td colspan="3"> <span id="msg" style="text-align:right;" > &nbsp; </span></td>
			<iframe name='hidden_frame' id="hidden_frame" style='display:none;'></iframe>
			</form>
		    </td>
		  </tr>
		  <tr >
		    <td>
		    	<select id="AddCapture" style="width:200px;">
		    		<option value="select" > --- Select --- </option>
		    	</select>
		    </td>
		    <td><input type="button" name="RCapture" id="RCapture" value="Run Capture" style="font-size: 12px; padding:4px; "> </td>
		    <td width="180px"> <span id="WaitForGraph"> &nbsp; </span> </td>
		  </tr>
		</table>
		
</fieldset>
<br><br>
<fieldset>
  <legend> Analysis </legend>
     <div align="left"> Select Chart Type : 
     <select id="SelectChart" style="width:200px;" >
     	<option value="Bar"> Bar Chart </option>
     	<option value="Pie" selected > Pie Chart </option>
     	<option value="Column"> Column Chart </option>
     	<option value="Doughnut3D"> Doughnut 3D Chart </option>
     	<option value="Doughnut2D" > Doughnut 2D Chart </option>
     	<option value="Line"> Line Chart </option>
     </select>
     </div>
     <a name="ScrollDown" >
<div id="chartdiv" align="center">The Capture Analysis will be shown here.</div>
    <script type="text/javascript">
    function DrawGraph() {
    	var myXML = \$("#AddCapture").val();
    	var ChooseChart = \$("#SelectChart").val();
    	ChooseChart = ChooseChart + ".swf";
    	
    	var chart = "../../../nbar_sdk/chart/" + ChooseChart ;
       	var myChart = new FusionCharts( chart , "myChartId", "800", "400");
       	//var CaptureXML = "../../../nbar_sdk/chart/$folderName/" + myXML + ".xml" ;
       	var CaptureXML = '/cgi-bin/Capture.pl?timestamp=$folderName';
        	myChart.setDataURL( CaptureXML );
        	myChart.render("chartdiv");
     }
    </script>
    </a> 		 

</fieldset>

<br><br>
<fieldset>
   <legend> StILE Simulator </legend>
<br>
<span id="StartStile" style="cursor: pointer"> Click Here To <span id="StartStop" style="text-decoration: underline;" > Start/Stop </span> Debugging. </span>
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
<div id="Division" style="background-color:#000; margin-left:30px; color:white; font-size: 12px; overflow: auto; height:300px; width:720px;
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

<!-- ############## here for IOL ############ -->

<fieldset>
   <legend> IOL Simulator </legend>
<br>
<span id="StartIOL" style="cursor: pointer"> Click Here To <span id="StartStopIOL" style="text-decoration: underline;" > Start/Stop</span>  IOL. </span>
<br><br>
<div id="iol" style="display: none;" >
<table border="1" > 
<form action="iolinfo.pl?timestamp=$folderName" id="form3" encType="multipart/form-data"  method="POST" target="hidden_frame3">
<tr>
<td width="200px" class="FormLabel" style="text-align:left;"> Give Path of IOL Image: </td>
<td width="240px" ><input type="text" size="25" id="iolpath" name="iolpath" 
   style="padding:3px;
  -moz-box-shadow: 0 1px 2px rgba(0,0,0,0.5);
  -webkit-box-shadow: 0 1px 3px rgba(0,0,0,0.5);
  -webkit-border-radius: 5px;
  -moz-border-radius: 3px;" >
</td>
<td width="60px" ><span> &nbsp; </span> </td>
<td width="140px" ><span id="ProgressBarIOL"> &nbsp; </span> </td>
</tr>
<tr>
<td width="200px" class="FormLabel" style="text-align:left;"> Give Path of Pagent: </td>
<td width="240px" ><input type="text" size="25" id="pagentpath" name="pagentpath" 
   style="padding:3px;
  -moz-box-shadow: 0 1px 2px rgba(0,0,0,0.5);
  -webkit-box-shadow: 0 1px 3px rgba(0,0,0,0.5);
  -webkit-border-radius: 5px;
  -moz-border-radius: 3px;" >
</td>
<td width="60px" ><span> <input type="button" id="enterIOL" value="  Enter  " style="padding:4px; font-weight: bold;" /> </span> </td>
<td width="140px" ><span id="ProgressBarIOL"> &nbsp; </span> </td>
</tr>
<tr>
<td colspan="4"><span id="DownloadFileIOL" style="display:none;" >  </span> </td>
</tr>
</form>
</table>
<iframe name='hidden_frame3' id="hidden_frame3" style='display:none;'></iframe>
<br><p> Output : </p>
<div id="DivisionIOL" style="background-color:#000; margin-left:30px; color:white; font-size: 12px; overflow: auto; height:300px; width:720px;
  -moz-box-shadow: 0 1px 2px rgba(0,0,0,0.5);
  -webkit-box-shadow: 0 1px 3px rgba(0,0,0,0.5);
  -webkit-border-radius: 5px;
  -moz-border-radius: 3px; ">
<span id="textareaIOL" style="font-family: monospace;" >
HTML

##
#if($output ne '') { print $output;}
##

print <<HTML;
</span>
<!--<div> stile > <input type="text" id="text2IOL" /> </div>-->
</div>
<br>
</div>
</fieldset>


<!-- ############### Upto here ############# ---->

<!-- <link rel="stylesheet" type="text/css" href="../../../nbar_sdk/style.css" />
<link rel="stylesheet" type="text/css" href="../../../nbar_sdk/autocomplete/autocomplete.css" /> -->

<script src="../../../nbar_sdk/autocomplete/jquery.ui.core.js" type="text/javascript" charset="utf-8"></script>
<script src="../../../nbar_sdk/autocomplete/jquery.ui.widget.js" type="text/javascript" charset="utf-8"></script>
<script src="../../../nbar_sdk/autocomplete/jquery.ui.position.js" type="text/javascript" charset="utf-8"></script>
<script src="../../../nbar_sdk/autocomplete/jquery.ui.autocomplete.js" type="text/javascript" charset="utf-8"></script>
<script type="text/javascript" language="javascript" src="../../../nbar_sdk/effects.js" ></script> 
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
	my $returnValue = 1;
	
	foreach my $protocolName ( @XMLarray ) {
		system("./generate_pdl.pl $folderName $protocolName");
		$returnValue = $?;
		if ( $returnValue != 0) {
			print "<p>Internal Server Error. Cannot generate PDL for $protocolName.</p>";
		}
	}
	
	$returnValue = 1;
	if ( $pPackType eq 'incremental' ) {
		$returnValue = `./load_on_clisim.pl $folderName incremental`;
		#system("./load_on_clisim.pl $folderName incremental");
	}
	elsif ( $pPackType eq 'non_incremental' ) {
		$returnValue = `./load_on_clisim.pl $folderName default`;
		#system("./load_on_clisim.pl $folderName default");
	}
	#elsif ( $pPackType eq 'tool' ) { call }
	$returnValue = $?;		##capture ret val of load_on_clisim script
	
#	if ( (grep {/(E|e)rror/} $returnValue) == 0 ) {
	if ($returnValue == 0) {
		#print "<p> PDL Generated Successfully.&nbsp;&nbsp;&nbsp;<a href='/cgi-bin/download.pl?file=pdl&timestamp=$folderName' target='_blank'>View</a><i>&nbsp;&nbsp;(opens in new window)</i></p>";
		
		print "<p> XML Generated Successfully.&nbsp;&nbsp;&nbsp;<select name=\"GeneratedXML\" id=\"GeneratedXML\" style=\"width:200px\"  ONCHANGE=\"DisplayXML();\" >";
		for(my $XMLCount=0 ; $XMLCount<=$#XMLarray ; $XMLCount++) {
			print "<option value=\"$XMLarray[$XMLCount]\" >$XMLarray[$XMLCount]</option>";
		}
		print "</select><i>&nbsp;&nbsp;(opens in new window)</i></p>";
		
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
		exit (1);
	}
}

#######################################

