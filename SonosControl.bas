
' http://technikblog.ch/2015/08/sonos-web-interface-erweiterte-einrichtung-fuer-sonos-lautsprecher/

'##############################################################################################################
'TEST-CLIENT für TSNE_V3
'##############################################################################################################
'##############################################################################################################
#Include Once "inc/TSNE_V3.bi"							'Die TCP Netzwerkbibliotek integrieren
#Include Once "andev/ini.bi"

'##############################################################################################################
Const APP_VERSION As String = "17.05.02" ' 16.08.02

Dim G_Client As UInteger

Dim Shared SONOS_IP As String
Dim Shared SONOS_PORT As Integer
Dim Shared SONOS_VOL As String
Dim Shared THREADS_OPEN As Integer

Const DEBUG As Byte = 0

'##############################################################################################################
Sub TSNE_Connected(ByVal V_TSNEID As UInteger)		'Empfänger für das Connect Signal (Verbindung besteht)
	Print "[CONNECT]"
	
	'Daten zum senden vorbereiten (HTTP Protokoll Anfrage)
	Dim CRLF As String = Chr(13, 10)
	Dim D As String
	D += "GET / HTTP/1.1" & CRLF
	D += "Host: www.google.de" & CRLF
	D += "connection: close" & CRLF
	D += CRLF
	
	'Daten an die Verbindung senden
	Print "[SEND] ..."
	Print ">" & D & "<"
	Dim BV As Integer = TSNE_Data_Send(V_TSNEID, D)
	If BV <> TSNE_Const_NoError Then
		Print "[FEHLER] " & TSNE_GetGURUCode(BV)		'Fehler ausgeben
	Else
		Print "[SEND] OK"
	End If
End Sub

'##############################################################################################################
Sub TSNE_Disconnected(ByVal V_TSNEID As UInteger)	'Empfänger für das Disconnect Signal (Verbindung beendet)
	'Print "[DISCONNECTED] ";
End Sub

'##############################################################################################################
Sub TSNE_NewData (ByVal V_TSNEID As UInteger, ByRef V_Data As String)	'Empfänger für neue Daten
	If DEBUG = 1 Then
		Print
		Print
		Color 12,0
		Print "[RECEIVED]"
		Print V_Data
		Color 7,0
		Print
		Print 
		'Print "[RECEIVED] " & Len(V_Data) & " Bytes"
	Else
		'Print "[ANSWER RECEIVED] ";
	EndIf
End Sub

'##############################################################################################################
Sub SONOS_Scan(ByVal V_TSNEID As UInteger)
	'Daten zum senden vorbereiten (HTTP Protokoll Anfrage)
	Dim CRLF As String = Chr(13, 10)
	Dim D As String
	D += "GET /status/zp HTTP/1.1" & CRLF
	D += "HOST: " & SONOS_IP & ":" & SONOS_PORT & CRLF
	D += "connection: close" & CRLF
	D += CRLF
	
	'If DEBUG = 1 Then
	'	Print
	'	Print
	'	Color 10,0
	'	Print D
	'	Color 7,0
	'	Print
	'	Print
	'EndIf
	
	'Daten an die Verbindung senden
	Dim BV As Integer = TSNE_Data_Send(V_TSNEID, D)
	If BV <> TSNE_Const_NoError Then
		Print "[FEHLER] " & TSNE_GetGURUCode(BV)		'Fehler ausgeben
	'Else
		'Print "[SEND] OK"
	End If
End Sub

Sub TSNE_Scan_NewData(ByVal V_TSNEID As UInteger, ByRef V_Data As String)
	'If DEBUG = 1 Then
	'	Print
	'	Print
	'	Color 14,0
	'	Print "[RECEIVED]"
	'	Print V_Data
	'	Color 7,0
	'	Print
	'	Print 
	'EndIf
	
	Dim As Integer pF, pS, pE
	Dim As String Tmp, LocalUID, IPAddress
	
	pF = InStr(V_Data, "<LocalUID>")
	If pF > 1 Then
		pS = pF + Len("<LocalUID>")
		pE = InStr(pS+1, V_Data, "</LocalUID>")
		LocalUID = Mid(V_DATA, pS, pE-pS)
		'Print "LocalUID: [" & LocalUID & "]"
	EndIf
	
	pF = InStr(V_Data, "<IPAddress>")
	If pF > 1 Then
		pS = pF + Len("<IPAddress>")
		pE = InStr(pS+1, V_Data, "</IPAddress>")
		IPAddress = Mid(V_DATA, pS, pE-pS)
		'Print "IPAddress: [" & IPAddress & "]"
	EndIf
	
	If LocalUID <> "" And IPAddress <> "" Then
		Print "found device " & LocalUID & " -> " & IPAddress
		ini.setString "Devices", LocalUID, IPAddress, ExePath & "\SonosCotrol.ini"
	EndIf
End Sub

Sub threadSonosScan(ByVal id As Integer)
	Dim connectIP As String
	
	THREADS_OPEN = THREADS_OPEN + 1
	connectIP = SONOS_IP & id
	
	Dim G_Client As UInteger
	Dim BV As Integer = TSNE_Create_Client(G_Client, connectIP, SONOS_PORT, @TSNE_Disconnected, @SONOS_Scan, @TSNE_Scan_NewData, 1, TSNE_INT_StackSize, 0)
	TSNE_WaitClose(G_Client)
	
	THREADS_OPEN = THREADS_OPEN - 1
End Sub

'##############################################################################################################
Sub SONOS_Play(ByVal V_TSNEID As UInteger)
	Print "CONNECTED"
	
	Dim CRLF As String = Chr(13, 10)
	Dim D As String
	Dim P As String

	D = "<s:Envelope xmlns:s=""http://schemas.xmlsoap.org/soap/envelope/"" s:encodingStyle=""http://schemas.xmlsoap.org/soap/encoding/""><s:Body><u:Play xmlns:u=""urn:schemas-upnp-org:service:AVTransport:1""><InstanceID>0</InstanceID><Speed>1</Speed></u:Play></s:Body></s:Envelope>"
	
	P += "POST /MediaRenderer/AVTransport/Control HTTP/1.1" & CRLF
	P += "CONNECTION: close" & CRLF
	P += "HOST: " & SONOS_IP & ":" & SONOS_PORT & CRLF
	P += "CONTENT-LENGTH: " & Len(D) & CRLF
	P += "CONTENT-TYPE: text/xml; charset=""utf-8""" & CRLF
	P += "SOAPACTION: ""urn:schemas-upnp-org:service:RenderingControl:1#Play""" & CRLF
	P += CRLF
	P += D
	
	If DEBUG = 1 Then
		Print
		Print
		Color 10,0
		Print P
		Color 7,0
		Print
		Print
	EndIf
	
	Print "Sending command PLAY to " & SONOS_IP & ":" & SONOS_PORT & " -> ";
	Dim BV As Integer = TSNE_Data_Send(V_TSNEID, P)
	If BV <> TSNE_Const_NoError Then
		Print "[ERROR] " & TSNE_GetGURUCode(BV)
	Else
		Print "OK"
	End If
End Sub

'##############################################################################################################
Sub SONOS_Pause(ByVal V_TSNEID As UInteger)
	Print "CONNECTED"
	
	Dim CRLF As String = Chr(13, 10)
	Dim D As String
	Dim P As String
	
	D = "<s:Envelope xmlns:s=""http://schemas.xmlsoap.org/soap/envelope/"" s:encodingStyle=""http://schemas.xmlsoap.org/soap/encoding/""><s:Body><u:Pause xmlns:u=""urn:schemas-upnp-org:service:AVTransport:1""><InstanceID>0</InstanceID></u:Pause></s:Body></s:Envelope>"
	
	P += "POST /MediaRenderer/AVTransport/Control HTTP/1.1" & CRLF
	P += "CONNECTION: close" & CRLF
	P += "HOST: " & SONOS_IP & ":" & SONOS_PORT & CRLF
	P += "CONTENT-LENGTH: " & Len(D) & CRLF
	P += "CONTENT-TYPE: text/xml; charset=""utf-8""" & CRLF
	P += "SOAPACTION: ""urn:schemas-upnp-org:service:RenderingControl:1#Pause""" & CRLF
	P += CRLF
	P += D
	
	If DEBUG = 1 Then
		Print
		Print
		Color 10,0
		Print P
		Color 7,0
		Print
		Print
	EndIf
	
	Print "Sending command PAUSE to " & SONOS_IP & ":" & SONOS_PORT & " -> ";
	Dim BV As Integer = TSNE_Data_Send(V_TSNEID, P)
	If BV <> TSNE_Const_NoError Then
		Print "[ERROR] " & TSNE_GetGURUCode(BV)
	Else
		Print "OK"
	End If
End Sub

'##############################################################################################################
Sub SONOS_Volume(ByVal V_TSNEID As UInteger)
	Print "CONNECTED"
	
	Dim CRLF As String = Chr(13, 10)
	Dim D As String
	Dim P As String
	
	D = "<s:Envelope xmlns:s=""http://schemas.xmlsoap.org/soap/envelope/"" s:encodingStyle=""http://schemas.xmlsoap.org/soap/encoding/""><s:Body><u:SetVolume xmlns:u=""urn:schemas-upnp-org:service:RenderingControl:1""><InstanceID>0</InstanceID><Channel>Master</Channel><DesiredVolume>" & SONOS_VOL & "</DesiredVolume></u:SetVolume></s:Body></s:Envelope>"
	
	P += "POST /MediaRenderer/AVTransport/Control HTTP/1.1" & CRLF
	P += "CONNECTION: close" & CRLF
	P += "HOST: " & SONOS_IP & ":" & SONOS_PORT & CRLF
	P += "CONTENT-LENGTH: " & Len(D) & CRLF
	P += "CONTENT-TYPE: text/xml; charset=""utf-8""" & CRLF
	P += "SOAPACTION: ""urn:schemas-upnp-org:service:RenderingControl:1#SetVolume""" & CRLF
	P += CRLF
	P += D
	
	If DEBUG = 1 Then
		Print
		Print
		Color 10,0
		Print P
		Color 7,0
		Print
		Print
	EndIf
	
	Print "Sending command VOLUME to " & SONOS_IP & ":" & SONOS_PORT & " -> ";
	Dim BV As Integer = TSNE_Data_Send(V_TSNEID, P)
	If BV <> TSNE_Const_NoError Then
		Print "[ERROR] " & TSNE_GetGURUCode(BV)
	Else
		Print "OK"
	End If
End Sub

'##############################################################################################################
'##############################################################################################################
'##############################################################################################################
Dim BV As Integer									'Variable für Statusrückgabe erstellen
Dim SonosIP As String = Command(1)
Dim SonosCmd As String = Command(2)

If UCase(Left(SonosIP, 6)) = "RINCON" Then
	SonosIP = ini.getString("Devices", SonosIP, "", ExePath & "\SonosCotrol.ini")
EndIf

If SonosIP = "" Or SonosCmd = "" Then
	Print
	Print "SonosControl (" & APP_VERSION & ") by M. Lindner"
	Print
	Print "usage: SonosControl <IP or NAME> <COMMAND> <VALUE>"
	Print
	Print "example: SonosControl 192.168.178.1 SCAN"
	Print "         (IP = any ip from your network | ip of router)
	Print
	Print "example: SonosControl RINCON_B8E93733EF4001400 PLAY
	Print "example: SonosControl RINCON_B8E93733EF4001400 PAUSE
	Print "example: SonosControl RINCON_B8E93733EF4001400 VOLUME 10
	Print
	Print "press any key to exit..."
	Sleep
	End
EndIf

SONOS_IP = SonosIP
SONOS_PORT = 1400
SONOS_VOL = Trim(Command(3))
If SONOS_VOL = "" Then SONOS_VOL = "0"
If Len(SONOS_VOL) = 1 Then SONOS_VOL = "0" & SONOS_VOL

'BV = TSNE_Create_Client(G_Client, "www.google.de", 80, @TSNE_Disconnected, @TSNE_Connected, @TSNE_NewData, 60)

Select Case UCase(SonosCmd)
	Case "SCAN"
		Dim i As Integer
		
		i = InStrRev(SonosIP, ".")
		SONOS_IP = Left(SonosIP, i)
		
		Print "Scanning - please wait..."
		
		For i = 1 To 254
		    ThreadCreate(Cast(Any Ptr,@threadSonosScan), i) 
		    Sleep 10
		Next i
		
		Do
		    Sleep 100
		    If THREADS_OPEN = 0 Then Exit Do
		Loop Until Inkey = Chr(27) 
		
		BV = TSNE_Const_NoError
	
	Case "PLAY"
		Print "Connecting to " & SONOS_IP & ":" & SONOS_PORT & " -> ";
		BV = TSNE_Create_Client(G_Client, SONOS_IP, SONOS_PORT, @TSNE_Disconnected, @SONOS_Play, @TSNE_NewData, 60)
		
	Case "PAUSE", "STOP"
		Print "Connecting to " & SONOS_IP & ":" & SONOS_PORT & " -> ";
		BV = TSNE_Create_Client(G_Client, SONOS_IP, SONOS_PORT, @TSNE_Disconnected, @SONOS_Pause, @TSNE_NewData, 60)
	
	Case "VOLUME", "VOL"
		Print "Connecting to " & SONOS_IP & ":" & SONOS_PORT & " -> ";
		BV = TSNE_Create_Client(G_Client, SONOS_IP, SONOS_PORT, @TSNE_Disconnected, @SONOS_Volume, @TSNE_NewData, 60)
End Select

'	Statusrückgabe auswerten
'If BV <> TSNE_Const_NoError Then
'	Print "[ERROR] " & TSNE_GetGURUCode(BV)		'Fehler ausgeben
'	Print "[[" & BV & "]]"
'	End -1											'Programmbeenden
'End If

'Print "[CLOSING] ";
TSNE_WaitClose(G_Client)
If DEBUG = 1 Then Print "[CLOSED]"

Print
Print "press any key to exit..."
Sleep 3000
End

' Play: 1
' MAC: 5c:aa:fd:4d:26:94
' uuid:RINCON_5CAAFD4D269401400

