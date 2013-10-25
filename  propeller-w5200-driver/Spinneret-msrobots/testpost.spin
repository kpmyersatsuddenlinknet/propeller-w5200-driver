'':::::::[ Test Post ]::::::::::::::::::::::::::::::::::::::::::::::::::::::
{{
''
''AUTHOR:           Michael Sommer (@MSrobots)
''COPYRIGHT:        See LICENCE (MIT)    
''LAST MODIFIED:    10/24/2013
''VERSION:          1.0       
''LICENSE:          MIT (see end of file)
''
''
''DESCRIPTION:
''                  test for post method
''                  compile and save output as testpost.binary.
''                  rename to testpost.psx and save to sd
''                  call in webrowser as testpost.psx
''
''MODIFICATIONS:
''10/09/2013        created
''10/24/2013        added comments
''                  Michael Sommer (MSrobots)
}}
CON
''
''=======[ Global CONstants ]=============================================================

  { PSX/PSE CMDS }    
    
  REQ_PARA_STRING   = 1  ' get Hubaddress of GET parameter (as string)
  REQ_PARA_NUMBER   = 2  ' get Value of GET parameter (as long)
  REQ_FILENAME      = 3  ' get Hubaddress of Request  
  REQ_HEADER_STRING = 4  ' get Hubaddress of HEADER parameter (as string)
  REQ_HEADER_NUMBER = 5  ' get Value of HEADER parameter (as long)
  REQ_POST_STRING   = 6  ' get Hubaddress of POST parameter (as string)
  REQ_POST_NUMBER   = 7  ' get Value of POST parameter (as long)
  
  SEND_FILE_EXT     = 11 ' set FileExtension and content-type for response
  SEND_SIZE_HEADER  = 12 ' send size and HEADER of response to socket (buffered)
  SEND_DATA         = 13 ' send number of bytes to socket (buffered)
  SEND_STRING       = 14 ' send string to socket (buffered)
  SEND_FLUSH        = 15 ' flush buffer to wiznet
  SEND_FILE_CONTENT = 16 ' send content of file to socket (buffered)       
  
  CHANGE_DIRECTORY  = 21 ' change to Directory on SD
  LIST_ENTRIES      = 22 ' list Entries (first/next)
  LIST_ENTRY_ADDR   = 23 ' get Hubaddress of Directory cache Entry (FAT Dir Entry)       
  CREATE_DIRECTORY  = 24 ' create new Directory       
  DELETE_ENTRY      = 25 ' delete File or Directory             
  FILE_WRITE_BLOCK  = 26 ' open file, read block, close file       
  FILE_READ_BLOCK   = 27 ' open file, write block, close file       

  QUERY_DNS         = 41 ' resolves name to ip with DNS
  QUERY_NETBIOS     = 42 ' send NetBios Query
  CHECK_NETBIOS     = 43 ' poll next answer
  
  PSE_CALL          = 91 ' call submodul in new COG and return
  PSE_TRANSFER      = 92 ' call submodul in same COG (DasyChain)

''
''=======[ PUBlic Spin Methods]===========================================================
Pub getPasmADDR
return @cmdptr
''
''=======[ Assembly Cog ]=================================================================
Dat
''-------[ Start and Stop ]---------------------------------------------------------------
                        org     0
                        
cmdptr                  mov     cmdptr,         par            ' adr of cmd mailbox
par1ptr                 mov     par1ptr,        par            ' adr of param1 mailbox
par2ptr                 mov     par2ptr,        par            ' adr of param2 mailbox
bufptr                  add     par1ptr,        #4             ' adr of output buffer (1K)
outptr                  add     par2ptr,        #8             ' adr of current written pos in out-buf
count                   rdlong  bufptr,         par1ptr        ' init adress of output buffer

                        call    #main                          ' call usermodule

                        wrlong  zero,           cmdptr         ' write exit to cmd mailbox
                        cogid   cmdin                          ' get own cogid
                        cogstop cmdin                          ' and shoot yourself ... done
                        
''-------[ Main Program ]-----------------------------------------------------------------
main                        
                        
                        add     postptr,        bufptr         ' now postptr hubadress last 64 bytes buf

getp                    mov     par1,           #"p"           ' get string parameter "p"
                        mov     cmdout,         #REQ_POST_STRING
                        call    #sendspincmd                   ' result is string in par1

                        mov     outptr,         postptr        ' save post content of textbox "p" at end of buf                
                        call    #strhub2hub                    ' copy p
                        
                        wrbyte  zero,           outptr         ' terminate string
                        
                         ' now done with parameter
                        
parsdone                mov     par1,           fileext        ' send file extension
                        mov     cmdout,         #SEND_FILE_EXT
                        call    #sendspincmd                   ' set file ext 

                        mov     par2,           zero           ' clear flag nulti-status 
                        mov     par1,           minusone       ' size ' send packet size unknown
                        mov     cmdout,         #SEND_SIZE_HEADER
                        call    #sendspincmd                   ' send Header and content type/size

sendheader              mov     outptr,         bufptr         ' copy header
                        movd    cog2hub,        #htmheader
                        mov     count,          #htmfooter-htmheader              
                        call    #cog2hub                       ' to Output Hub Buffer
                        call    #sendstringbuf                 ' send header
                        
sendP                   
                        mov     par1,           postptr        ' send string postptr aka textbox "p" 
                        mov     cmdout,         #SEND_STRING
                        call    #sendspincmd                        
                       
sendfooter              mov     outptr,         bufptr         
                        movd    cog2hub,        #htmfooter        ' Transfer footer into hub-buff
                        mov     count,          #htmfooter_end-htmfooter       
                        call    #cog2hub                       ' copy footer to Output Hub Buffer
                        call    #sendstringbuf                 ' send footer

main_ret                ret                                    ' done

''-------[ Send Spin Cmds ]---------------------------------------------------------------
{{
''sendspincmd:          call spin cog with command and wait for response
}}                     
sendspincmd             wrlong  par2,           par2ptr        ' write param2 value
                        wrlong  par1,           par1ptr        ' write param1 value
                        wrlong  cmdout,         cmdptr         ' write cmd value                        
sendspincmdwait         rdlong  cmdin,          cmdptr
                        cmp     cmdin,          cmdout wz
        if_z            jmp     #sendspincmdwait               ' wait for spin
                        rdlong  par1,           par1ptr        ' get answer param1
                        rdlong  par2,           par2ptr        ' get answer param2
sendspincmd_ret         ret

''-------[ Send String bufptr ]-----------------------------------------------------------
{{
''
''sendstringbuf:        sends String from Hub Buffer bufptr to the socket/browser (buffered)
''
''PARMS:              - none   
''  
''RETURNS:            - none
''
}}
sendstringbuf           mov     par1,           bufptr         ' send string from Output hub-buff 
                        mov     cmdout,         #SEND_STRING
                        call    #sendspincmd                   
sendstringbuf_ret       ret
''-------[ Copy Cog to Hub ]--------------------------------------------------------------
{{
''
''cog2hub:              copy count longs from Cog to Hub
''
''PARMS:
''  cog2hub           - use "movd cog2hub, #COGlabel" to set source address in cog
''  count             - number of longs to copy
''  outptr            - hubaddress destination
''  
''RETURNS:            - none - outptr get incremented accordingly (by 4 each long)
''
}}
cog2hub                 wrlong  0-0,            outptr
                        add     cog2hub,        incDest1
                        add     outptr,         #4
                        djnz    count,          #cog2hub
cog2hub_ret             ret

''-------[ Copy Hub to Hub ]--------------------------------------------------------------
{{
''
''strhub2hub:           copy string size bytes from Hub to Hub. zero will not be copied
''
''PARMS:
''  par1              - hubaddress source
''  outptr            - hubaddress destination
''
''  
''RETURNS:            - none - par1 and outptr get incremented each byte written
''
}}
strhub2hub              rdbyte  tmp,            par1
                        cmp     tmp,            zero wz
              if_z      jmp     #strhub2hub_ret
                        add     par1,           #1
                        wrbyte  tmp,            outptr
                        add     outptr,         #1
                        jmp     #strhub2hub
strhub2hub_ret          ret                                    

''-------[ Data Constants ]---------------------------------------------------------------
zero                    long    0
minusone                long    -1
space                   long    32
incDest1                long    1 << 9
fileext                 long
                        byte    "htm",0
postptr                 long    $400 - $40                     ' last 64 bytes buffer
                        
htmheader               long
                        byte    "<html>", 13, 10,"<head>", 13, 10,"<title>Test Post Verb</title>",13,10 
                        byte    "<style type=",34,"text/css",34,">"
                        byte    "table {border-collapse: collapse; border: 1px solid black; cellpadding: 5px;} "
                        byte    "table td, table th {border: 1px solid black; } "
                        byte    "</style>",13,10 
                        byte    "</head>", 13, 10
                        byte    "<body>", 13, 10,"<form action=",34,"testpost.psx",34," method=",34,"post",34,">"
                        byte    "<table>", 13, 10, "<tr><th colspan=",34,"3",34,">Test Post Verb</th></tr>",13,10
                        byte    "<tr><td>NAME</td><td><input type=",34,"text",34," name=",34,"p",34," /></td>"
                        byte    "<td><input type=",34,"submit",34," name=",34,"submit",34," value=",34,"Submit",34," /></td></tr>",13,10
                        byte    "<tr><td colspan=",34,"3",34,">",0
                        
htmfooter               long
                        byte    "</td></tr>",13,10
                        byte    "</table></form></body></html>", 13, 10, 0
htmfooter_end           long
                        
''-------[ Variables ]--------------------------------------------------------------------
cmdin                   res     1
cmdout                  res     1
par1                    res     1
par2                    res     1
tmp                     res     1
                        fit     496
''
''=======[ Documentation ]================================================================
CON                                                
{{{
This .spin file supports PhiPi's great Spin Code Documenter found at
http://www.phipi.com/spin2html/

You can at any time create a .htm Documentation out of the .spin source.

If you change the .spin file you can (re)create the .htm file by uploading your .spin file
to http://www.phipi.com/spin2html/ and then saving the the created .htm page. 
}}

''
''=======[ MIT License ]==================================================================
CON                                                 
{{{
 ______________________________________________________________________________________
|                            TERMS OF USE: MIT License                                 |                                                            
|______________________________________________________________________________________|
|Permission is hereby granted, free of charge, to any person obtaining a copy of this  |
|software and associated documentation files (the "Software"), to deal in the Software |
|without restriction, including without limitation the rights to use, copy, modify,    |
|merge, publish, distribute, sublicense, and/or sell copies of the Software, and to    |
|permit persons to whom the Software is furnished to do so, subject to the following   |
|conditions:                                                                           |
|                                                                                      |
|The above copyright notice and this permission notice shall be included in all copies |
|or substantial portions of the Software.                                              |
|                                                                                      |
|THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,   |
|INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A         |
|PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT    |
|HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF  |
|CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE  |
|OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                         |
|______________________________________________________________________________________|
}}