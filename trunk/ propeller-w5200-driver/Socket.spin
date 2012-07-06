CON
  BUFFER_2K                     = $800

  'MACRAW and PPPOE can only be used with socket 0
  #0, CLOSED, TCP, UDP, IPRAW, MACRAW, PPPOE

  UPD_HEADER_IP     = $00
  UDP_HEADER_PORT   = $04
  UDP_HEADER_LENGTH = $06
  UPD_DATA          = $08
  TIMEOUT           = 500
  
  
  CR    = $0D
  LF    = $0A
  NULL  = $00

  
       
VAR
  byte  _sock
  byte  _protocol
  byte  _remoteIp[4]
  byte  readCount
  word  _remotePort
  long bytesToRead

DAT
  _port       byte  $2710

OBJ
  wiz           : "W5200"

'----------------------------------------------------
' Initialize
'----------------------------------------------------
PUB Init(socketId, protocol, portNum)

  _sock := socketId
  _protocol := protocol

  wiz.Init

  'Increment port numbers stating at 10,000
  if(portNum == 0)
    portNum := _port++
  
  wiz.InitSocket(socketId, protocol, portNum)

  readCount := 0


{ 
PUB GetIp
  return wiz.GetCommonRegister(wiz#SOURCE_IP0)
PUB GetPort
  return _remotePort
PUB GetbytesToRead
  return bytesToRead
PUB GetBytesToWrite
  return bytesToWrite
  }
  
PUB Mac(octet5, octet4, octet3, octet2, octet1, octet0)
  wiz.SetMac(octet5, octet4, octet3, octet2, octet1, octet0)

PUB Ip(octet3, octet2, octet1, octet0)
  wiz.SetIp(octet3, octet2, octet1, octet0)

PUB RemoteIp(octet3, octet2, octet1, octet0)
  _remoteIp[0] := octet3
  _remoteIp[1] := octet2
  _remoteIp[2] := octet1
  _remoteIp[3] := octet0
  wiz.RemoteIp(_sock, octet3, octet2, octet1, octet0)
  
PUB RemotePort(port)
  _remotePort := port
  wiz.SetRemotePort(_sock, port)

{
PUB DebugRead(register, buffer, length)
  wiz.DebugRead(_sock, register, buffer, length)
}  
'----------------------------------------------------
'
'----------------------------------------------------

PUB Open
  wiz.OpenSocket(_sock)

PUB Listen
  if(wiz.IsInit(_sock))
    wiz.StartListener(_sock)
    return true
  return false

PUB Connect
  wiz.OpenRemoteSocket(_sock)

PUB Connected
  return wiz.IsEstablished(_sock)

PUB Close
  return wiz.CloseSocket(_sock)

PUB IsClosed
  return wiz.IsClosed(_sock)

PUB Available | i
  bytesToRead := i := 0

  if(readCount++ == 0)
    repeat until NULL < bytesToRead := wiz.GetRxBytesToRead(_sock) 
      if(i++ > TIMEOUT)
        pause(1)
        return -1
  else
    bytesToRead := wiz.GetRxBytesToRead(_sock)
   
  return bytesToRead
  
PUB Receive(buffer) | ptr

  ptr := buffer
  wiz.Rx(_sock, buffer, bytesToRead)
  byte[buffer][bytesToRead] := NULL
  
  if(_protocol == UDP)
    ParseHeader(buffer)
    ptr += UPD_DATA

  return ptr
      
PUB Send(buffer, len) | before, after, bytesToWrite

  'Validate max Rx length in bytes
  bytesToWrite := len
  if(bytesToWrite > wiz.SocketTxSize(_sock))
    bytesToWrite := wiz.SocketTxSize(_sock)

  before := after := 0  
  wiz.Tx(_sock, buffer, bytesToWrite)

  repeat until ((after - before) == bytesToWrite)
    before :=  wiz.GetTxReadPointer(_sock)
    wiz.FlushSocket(_sock)
    after :=  wiz.GetTxReadPointer(_sock)
    
  return  bytesToWrite


PUB Disconnect | i
  i := readCount := 0
  wiz.DisconnectSocket(_sock)
  repeat until wiz.IsClosed(_sock)
    if(i++ > 500)
      wiz.CloseSocket(_sock)
    

PRI ParseHeader(header)
  if(bytesToRead > 8)
    UpdHeaderIp(header)
    UdpHeaderPort(header)

PRI UpdHeaderIp(header)
  RemoteIp(byte[header][UPD_HEADER_IP], byte[header][UPD_HEADER_IP+1], byte[header][UPD_HEADER_IP+2], byte[header][UPD_HEADER_IP+3])

PRI UdpHeaderPort(header)
  RemotePort(DeserializeWord(header + UDP_HEADER_PORT))

PRI DeserializeWord(buffer) | value
  value := byte[buffer++] << 8
  value += byte[buffer]
  return value

PRI pause(Duration)  
  waitcnt(((clkfreq / 1_000 * Duration - 3932) #> 381) + cnt)
  return