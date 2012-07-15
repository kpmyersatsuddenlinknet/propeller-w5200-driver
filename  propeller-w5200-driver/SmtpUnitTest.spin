CON
  _clkmode = xtal1 + pll16x     
  _xinfreq = 5_000_000

  BUFFER_2K     = $800
  
  CR            = $0D
  LF            = $0A
  NULL          = $00
  
  #0, CLOSED, TCP, UDP, IPRAW, MACRAW, PPPOE
  
       
VAR

DAT
  buff          byte  $0[BUFFER_2K]
  ehlo          byte  "EHLO agavejoe@cox.net", $0D, $0A, 0
  mfrom         byte  "MAIL FROM: <agavejoe@cox.net>", $0D, $0A, 0
  mto           byte  "RCPT TO: <agavejoe@cox.net>", $0D, $0A, 0
  mdata         byte  "DATA", $0D, $0A, 0
  subject       byte  "SUBJECT: test", $0D, $0A,  0
  msg           byte  "This is a test from script!", $0D, $0A, 0
  done          byte  ".", $0D, $0A, 0
  equit         byte  "quit", $0D, $0A, 0


OBJ
  pst           : "Parallax Serial Terminal"
  sock          : "Socket"
  wiz           : "W5200"


 
PUB Main | bytesToRead, buffer, bytesSent, receiving

  receiving := true
  bytesToRead := 0
  pst.Start(115_200)
  pause(500)


  pst.str(string("Initialize", CR))
  'Initialize Socket 0 port 8080
  buffer := sock.Init(0, TCP, 8080)

  'Wiz Mac and Ip
  sock.Mac($00, $08, $DC, $16, $F8, $01)
  sock.Ip(192, 168, 1, 107)

  'www.agaverobotics.com
  sock.RemoteIp(68, 6, 19, 4)
  sock.RemotePort(25)

  pst.str(string(CR, "Begin SMTP Conversation", CR))

  'Client
  pst.str(string("Open", CR))
  sock.Open
  pst.str(string("Connect", CR))
  sock.Connect
   
  'Connection?
  repeat until sock.Connected
    pause(100)


  bytesToRead := sock.Available
  buffer := sock.Receive(@buff)
  pst.str(buffer)


  
  bytesSent := sock.Send(@ehlo, strsize(@ehlo))

  pst.str(string("Sent EHLO",13))
  'pause(100)
  
  bytesToRead := sock.Available
  buffer := sock.Receive(@buff)
  pst.str(buffer)


  
  bytesSent := sock.Send(@mfrom, strsize(@mfrom))
  'pause(100)

  bytesToRead := sock.Available
  buffer := sock.Receive(@buff)
  pst.str(buffer)


  bytesSent := sock.Send(@mto, strsize(@mto))
  'pause(100)

  bytesToRead := sock.Available
  buffer := sock.Receive(@buff)
  pst.str(buffer)


  bytesSent := sock.Send(@mdata, strsize(@mdata))
  'pause(100)
  bytesSent := sock.Send(@subject, strsize(@subject))
  'pause(100)
  bytesSent := sock.Send(@msg, strsize(@msg))
  'pause(100)
  bytesSent := sock.Send(@done, strsize(@done))
  'pause(100)

  bytesToRead := sock.Available
  buffer := sock.Receive(@buff)
  pst.str(buffer)


  bytesSent := sock.Send(@equit, strsize(@equit))
  'pause(100)
  
  bytesToRead := sock.Available
  buffer := sock.Receive(@buff)
  pst.str(buffer) 


  pst.str(string(CR, "Disconnect", CR)) 
  sock.Disconnect
   
  
  

PUB PrintNameValue(name, value, digits) | len
  len := strsize(name)
  
  pst.str(name)
  repeat 30 - len
    pst.char($2E)
  if(digits > 0)
    pst.hex(value, digits)
  else
    pst.dec(value)
  pst.char(CR)


PUB DisplayMemory(addr, len, isHex) | j
  pst.str(string(13,"-----------------------------------------------------",13))
  pst.str(string(13, "      "))
  repeat j from 0 to $F
    pst.hex(j, 2)
    pst.char($20)
  pst.str(string(13, "      ")) 
  repeat j from 0 to $F
    pst.str(string("-- "))

  pst.char(13) 
  repeat j from 0 to len
    if(j == 0)
      pst.hex(0, 4)
      pst.char($20)
      pst.char($20)
      
    if(isHex)
      pst.hex(byte[addr + j], 2)
    else
      pst.char($20)
      if(byte[addr+j] == 0)
        pst.char($20)
      pst.char(byte[addr+j])

    pst.char($20) 
    if((j+1) // $10 == 0) 
      pst.char($0D)
      pst.hex(j+1, 4)
      pst.char($20)
      pst.char($20)  
  pst.char(13)
  
  pst.char(13)
  pst.str(string("Start: "))
  pst.dec(addr)
  pst.str(string(" Len: "))
  pst.dec(len)
  pst.str(string(13,"-----------------------------------------------------",13,13))
      
PUB PrintIp(addr) | i
  repeat i from 0 to 3
    pst.dec(byte[addr][i])
    if(i < 3)
      pst.char($2E)
    else
      pst.char($0D)
  
PRI pause(Duration)  
  waitcnt(((clkfreq / 1_000 * Duration - 3932) #> 381) + cnt)
  return