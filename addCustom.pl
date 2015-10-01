#!/usr/local/bin/perl5.8 -w

use strict;
use warnings;
use CGI;

my $form = new CGI;
print $form->header; #Print HTML header. this is mandatory
my $i = $form->param('addCount');


print<<HTML;
<br>
<hr width="60%" align="center" >
<input type="hidden" name="rahul" value="godha"/>
<br>
<fieldset>
	   <legend> Custom Protocol $i </legend><br>
		<TABLE border="0" >
		<tr> 
		<td colspan="3" style="text-align: right; cursor:pointer; text-decoration:underline;" ONCLICK="deleteThis($i);" > Delete this Custom Protocol </td>
		</tr>
		<TR>
		<TD width="160px" class="FormLabel">Protocol Name<span style="color:red">*</span> : </TD>
		<TD width="240px" ><INPUT TYPE="text" class="FormInput" NAME="name$i" maxlength="25" ID="name$i"  SIZE="23" ONBLUR="validatePresent($i);" >
			
		<span onMouseOver="ShowText('Message',1$i); return true;"
			onmouseout="HideText('Message',1$i); return true;" 
			href="javascript:ShowText('Message',1$i)"> 
			<img src="question-mark.png" alt="Help" > </span>
                         
		<span id="Message1$i" class="box"> Give Protocol Name. Example: 'myprotocol' </span>
		</TD>
		<TD width="400px" id="inf_name$i"> &nbsp; &nbsp; &nbsp; </TD>
		</TR>

		<TR>
		<TD class="FormLabel" >Application ID : </TD>
		<TD><INPUT TYPE="text" NAME="appid$i" ID="app$i" SIZE="23" class="FormInput" maxlength="3" ONCHANGE="validateApp($i);" >
		
			<span onMouseOver="ShowText('Message',2$i); return true;"
			onmouseout="HideText('Message',2$i); return true;" 
			href="javascript:ShowText('Message',2$i)"> 
			<img src="question-mark.png" alt="Help" > </span>
                         
		<span id="Message2$i" class="box"> Give Application ID(Range b/w 128 - 255). Example: 24$i </span>		
		</TD>
		<TD id="inf_app$i" class="forerror" >&nbsp;&nbsp;&nbsp; </TD>
		</TR>
	</TABLE>
	<BR>
</fieldset>
<br>
<fieldset>
<legend onmouseover="set_mouse_pointer(this);" id="HTTPID$i" ONCLICK="HidePType($i);" ><U> HTTP </U> </legend>
<div id="HTTPDiv$i">
<table border="0">
     <tr>
     	<td class="FormLabel" width="160px" id="LabelURL$i" > Enter URL:  </td>
     	<TD width="240px" ><INPUT TYPE="text" name="custom_url$i" ID="custom_url$i" class="FormInput" SIZE="23" ONBLUR="validateURL($i);">
     	
     	<span onMouseOver="ShowText('Message',3$i); return true;" 
			onmouseout="HideText('Message',3$i); return true;" 
			href="javascript:ShowText('Message',3$i)"> 
	<img src="question-mark.png" alt="Help" > </span> 
	<div id="Message3$i" class="box"> Enter Host Name or Regular Expressions. Example: value level/exec </div>					
					
	</TD>
	<TD id="inf_custom_url$i" width="400px" >&nbsp;</TD>
     </tr>
     <tr>
     	<td class="FormLabel" id="LabelHost$i" > Enter Host:  </td>
     	<TD><INPUT TYPE="text" name="custom_host$i" ID="custom_host$i" class="FormInput" SIZE="23" ONBLUR="validateHost($i);" >
     	
     	<span onMouseOver="ShowText('Message',4$i); return true;" 
			onmouseout="HideText('Message',4$i); return true;" 
			href="javascript:ShowText('Message',4$i)"> 
	<img src="question-mark.png" alt="Help" > </span> 
	<div id="Message4$i" class="box"> Enter Host URL. Example: www.cisco.com </div>					
					
	</TD>
	<TD id="inf_custom_host$i" >&nbsp;</TD>
     </tr>

</table>
<br>
</div>
</fieldset>
<br>
<fieldset>
<legend onmouseover="set_mouse_pointer(this);" id="PTypeID$i" ONCLICK="HideHttp($i);" ><u> L4 PROTOCOL TYPE </u></legend>
<div id="ProtocolTypeDiv$i">
	<br>
    <TABLE border="0" >
	<tr>
	<td width="210px" class="FormLabel" style="text-align: center;"> Protocol Type: </td>
	<td width="240px"  >
	<input type="radio" name="ProtocolType$i" value="tcp" id="ProtocolTCP$i" ONCLICK="HideHTTPDiv($i);"/> <span class="TextStyle"> TCP  </span>
	</td>
		
	<td width="200px">		
	<input type="radio" name="ProtocolType$i" value="udp"  id="ProtocolUDP$i" ONCLICK="HideHTTPDiv($i);" /><span class="TextStyle"> UDP </span>
	</td>
	<td width="250px;" >
	 <span id="timeMsg$i">  &nbsp; </span>
	</td>
	</tr>
	<tr>
	    <td>&nbsp;</td>
	    <td>&nbsp;</td>
	</tr>
	<tr>
	<td class="FormLabel" id="LabelSrcPort$i" >Source Port :</td>
    	<td><INPUT TYPE="text" NAME="SrcPort$i" ID="SrcPort$i" class="FormInput" SIZE="22" ONBLUR="validateSrcPort($i);">
            								
            <span  onMouseOver="ShowText('Message',5$i); return true;" 
				onmouseout="HideText('Message',5$i); return true;" 
				href="javascript:ShowText('Message',5$i)"> 
		<img src="question-mark.png" alt="Help" > </span> 
					
		<div id="Message5$i" class="boxPort"> Enter Port Ranges as (No - No) or Ports as (101, 102, 104) or  Leave Blank for Both. </div>
		</td>
        <TD colspan="2" ><span id="inf_SrcPort$i" class="forerror" > &nbsp; &nbsp; &nbsp; </span></TD>
        </tr>
        
        <TR>            	
        <TD class="FormLabel" id="LabelDestPort$i" >Destination Port: </TD>
        <TD><INPUT TYPE="text" NAME="DestPort$i" ID="DestPort$i" class="FormInput" SIZE="22" ONBLUR="validateDestPort($i);">
        	<span  onMouseOver="ShowText('Message',6$i); return true;" 
			onmouseout="HideText('Message',6$i); return true;" 
			href="javascript:ShowText('Message',6$i)"> 
		<img src="question-mark.png" alt="Help" > </span> 
			
          <div id="Message6$i" class="boxPort"> Enter Port Ranges as (No - No) or Ports as (101, 102, 104) or  Leave Blank for Both. </div>
	</TD>
	<TD colspan="2" ><span id="inf_DestPort$i" class="forerror" > &nbsp; &nbsp; </span></TD>
	</table>

</div>
<br>
</fieldset>
<div id="OffsetDiv$i">
<br>
<fieldset>
<legend> OFFSET  </legend>

<TABLE border="0" >
	<TR>
 	<TD  class="FormLabel" >Offset :</TD>
            <TD><INPUT TYPE="text" NAME="payload-offset$i" ID="offset$i" class="FormInput" maxlength="3"  SIZE="23" ONBLUR="validateOffset($i);">
            	<span  onMouseOver="ShowText('Message',7$i); return true;" 
		onmouseout="HideText('Message',7$i); return true;" 
		href="javascript:ShowText('Message',7$i)"> 
		<img src="question-mark.png" alt="Help" > </span> 
	<div id="Message7$i" class="box"> Enter Payload Offset. In Range (1-255) </div>
	</TD>
            <TD colspan="2" ><span id="inf_offset$i" class="forerror" > &nbsp;  </span></TD>
           </TR>
            <TR>
            	<TD colspan="4" >&nbsp;</TD>
            </TR>
            
         <TR>
	<TD colspan="2" style="text-align: left;" class="FormLabel" >PATTERN INFORMATION</TD>
	</TR>
	<TR>
	<TD width="160px">
	 <input type="radio" class="radio" name="pat_type$i" value="ascii" id="pat_ascii$i" ONCLICK="ClickAscii($i);" /><span class="TextStyle">ASCII </span>   
	</td>
	<td  width="240px" >
	<input type="radio" class="radio" name="pat_type$i" value="decimal" id="pat_dec$i" ONCLICK="ClickDec($i);" /><span class="TextStyle"> DECIMAL </span>
	</td>
	<td width="200px" >
	<input type="radio" class="radio" name="pat_type$i" value="hex" id="pat_hex$i" ONCLICK="ClickHex($i);" /><span class="TextStyle"> HEXADECIMAL </span>
	</td>
	<td width="200px">
	<input type="radio" class="radio" name="pat_type$i" value="variable" id="pat_var$i" ONCLICK="ClickVar($i);" /><span class="TextStyle"> VARIABLE </span>
	</TD>
         </TR>
	<TR>
	<TD colspan="4">&nbsp;  </TD>
	</TR>

	<TR id="value_row$i" >
	<TD class="FormLabel" > Value :</TD>
	<TD><INPUT TYPE="text" NAME="value$i" ID="value$i" class="FormInput" size="23" ONBLUR="validateValue($i);">
        	<span  onMouseOver="ShowText('Message',8$i); return true;" 
		onmouseout="HideText('Message',8$i); return true;" 
		href="javascript:ShowText('Message',8$i)"> 
	<img src="question-mark.png" alt="Help" > </span> 
	<div id="Message8$i" class="box"> Enter Match pattern. </div>
	</TD>
        	<TD colspan="2" ><div id="inf_value$i" class="forerror" > &nbsp;  </div></TD>
          </TR>
         
         <TR id="pattern_name_row$i" style="display:none;" >
        	<TD class="FormLabel"> Pattern Name:  </TD>
         	<TD> <input type="text" id="pattern_name$i" name="pattern_name$i" class="FormInput" size="23" ONBLUR="validatePatternName($i);" />
         	<span  onMouseOver="ShowText('Message',9$i); return true;" 
		onmouseout="HideText('Message',9$i); return true;" 
		href="javascript:ShowText('Message',9$i)"> 
	<img src="question-mark.png" alt="Help" > </span> 
	<div id="Message9$i" class="box"> Enter Name Value for Variable. </div>
         	</TD>
        	<td colspan="2" ><span id="inf_pattern_name$i" class="forerror" > &nbsp; </span></td>
        </TR>
           
        <TR id="pattern_size_row$i" style="display:none;" >
        	<TD class="FormLabel">Pattern Size:  </TD>
         	<TD> <input type="text" id="pattern_size$i" name="pattern_size$i" class="FormInput" size="23" ONCLICK="validatePatternSize($i);" />
         	<span  onMouseOver="ShowText('Message',10$i); return true;" 
		onmouseout="HideText('Message',10$i); return true;" 
		href="javascript:ShowText('Message',10$i)"> 
	<img src="question-mark.png" alt="Help" > </span> 
	<div id="Message10$i" class="box"> Enter Size Value for Variable. </div>
         	</TD>
        	<td colspan="2" ><span id="inf_pattern_size$i" class="forerror" > &nbsp; </span></td>
        </TR>
        <TR>
         	<TD colspan="4">&nbsp;</TD>
        </TR>
</TABLE>

</fieldset>
</div>
</FORM>
HTML

