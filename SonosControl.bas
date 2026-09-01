
' http://technikblog.ch/2015/08/sonos-web-interface-erweiterte-einrichtung-fuer-sonos-lautsprecher/

'##############################################################################################################
'TEST-CLIENT f�r TSNE_V3
'##############################################################################################################
'##############################################################################################################
#Include Once "inc/TSNE_V3.bi"							'Die TCP Netzwerkbibliotek integrieren
#Include Once "inc/ini.bi"

'##############################################################################################################
Const APP_VERSION As String = "26.09.01"

Dim G_Client As UInteger

Dim Shared SONOS_IP As String
Dim Shared SONOS_PORT As Integer
Dim Shared SONOS_VOL As String
Dim Shared THREADS_OPEN As Integer
Dim Shared hMutexThreadsOpen As Any Ptr
Dim Shared hMutexIniWrite As Any Ptr

Const DEBUG As Byte = 1

'##############################################################################################################
Sub TSNE_Connected(ByVal V_TSNEID As UInteger)		'Empf�nger f�r das Connect Signal (Verbindung besteht)
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
Sub TSNE_Disconnected(ByVal V_TSNEID As UInteger)	'Empf�nger f�r das Disconnect Signal (Verbindung beendet)
	'Print "[DISCONNECTED] ";
End Sub

'##############################################################################################################
Sub TSNE_NewData (ByVal V_TSNEID As UInteger, ByRef V_Data As String)	'Empf�nger f�r neue Daten
	If InStr(V_Data, "errorCode") > 0 Then
		Print "ERROR"
	Else
		Print "OK"
	EndIf
	
	If DEBUG = 1 Then
		Print
		Print
		If InStr(V_Data, "errorCode") > 0 Then
			Color 12,0
		Else
			Color 10,0
		EndIf
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
	D += "HOST: " & TSNE_GetIPA(V_TSNEID) & ":" & SONOS_PORT & CRLF
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
	Dim As String Tmp, LocalUID, IPAddress, ZoneName

	pF = InStr(V_Data, "<LocalUID>")
	If pF > 1 Then
		pS = pF + Len("<LocalUID>")
		pE = InStr(pS+1, V_Data, "</LocalUID>")
		LocalUID = Mid(V_DATA, pS, pE-pS)
		If DEBUG = 1 Then Print "LocalUID: [" & LocalUID & "]"
	EndIf

	pF = InStr(V_Data, "<IPAddress>")
	If pF > 1 Then
		pS = pF + Len("<IPAddress>")
		pE = InStr(pS+1, V_Data, "</IPAddress>")
		IPAddress = Mid(V_DATA, pS, pE-pS)
		If DEBUG = 1 Then Print "IPAddress: [" & IPAddress & "]"
	EndIf

	pF = InStr(V_Data, "<ZoneName>")
	If pF > 1 Then
		pS = pF + Len("<ZoneName>")
		pE = InStr(pS+1, V_Data, "</ZoneName>")
		ZoneName = Mid(V_DATA, pS, pE-pS)
		If DEBUG = 1 Then Print "ZoneName: [" & ZoneName & "]"
	EndIf

	If LocalUID <> "" And IPAddress <> "" Then
		If hMutexIniWrite <> 0 Then MutexLock(hMutexIniWrite)
		Print "found device " & LocalUID & " -> " & IPAddress & " (" & ZoneName & ")"
		ini.setString "Devices", LocalUID, IPAddress, ExePath & "\SonosControl.ini"
		ini.setString "Names", LocalUID, ZoneName, ExePath & "\SonosControl.ini"
		If hMutexIniWrite <> 0 Then MutexUnlock(hMutexIniWrite)
	EndIf
End Sub

Sub threadSonosScan(ByVal id As Integer)
	Dim connectIP As String
	
	connectIP = SONOS_IP & id
	
	If DEBUG = 1 Then Print "scanning " & connectIP & ":" & SONOS_PORT
	
	Dim T_Client As UInteger
	Dim BV As Integer = TSNE_Create_Client(T_Client, connectIP, SONOS_PORT, @TSNE_Disconnected, @SONOS_Scan, @TSNE_Scan_NewData, 1, TSNE_INT_StackSize, 0)
	TSNE_WaitClose(T_Client)
	
	If hMutexThreadsOpen <> 0 Then MutexLock(hMutexThreadsOpen)
	THREADS_OPEN = THREADS_OPEN - 1
	If hMutexThreadsOpen <> 0 Then MutexUnlock(hMutexThreadsOpen)
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
	P += "SOAPACTION: ""urn:schemas-upnp-org:service:AVTransport:1#Play""" & CRLF
	P += CRLF
	P += D
	
	If DEBUG = 1 Then
		Print
		Print
		Color 6,0
		Print P
		Color 7,0
		Print
		Print
	EndIf
	
	Print "Sending command PLAY to " & SONOS_IP & ":" & SONOS_PORT & " -> ";
	Dim BV As Integer = TSNE_Data_Send(V_TSNEID, P)
	If BV <> TSNE_Const_NoError Then
		Print "[ERROR] " & TSNE_GetGURUCode(BV)
	'ElseIf 
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
	P += "SOAPACTION: ""urn:schemas-upnp-org:service:AVTransport:1#Pause""" & CRLF
	P += CRLF
	P += D
	
	If DEBUG = 1 Then
		Print
		Print
		Color 6,0
		Print P
		Color 7,0
		Print
		Print
	EndIf
	
	Print "Sending command PAUSE to " & SONOS_IP & ":" & SONOS_PORT & " -> ";
	Dim BV As Integer = TSNE_Data_Send(V_TSNEID, P)
	If BV <> TSNE_Const_NoError Then
		Print "[ERROR] " & TSNE_GetGURUCode(BV)
	End If
End Sub

'##############################################################################################################
Sub SONOS_Volume(ByVal V_TSNEID As UInteger)
	Print "CONNECTED"
	
	Dim CRLF As String = Chr(13, 10)
	Dim D As String
	Dim P As String
	
	D = "<s:Envelope xmlns:s=""http://schemas.xmlsoap.org/soap/envelope/"" s:encodingStyle=""http://schemas.xmlsoap.org/soap/encoding/""><s:Body><u:SetVolume xmlns:u=""urn:schemas-upnp-org:service:RenderingControl:1""><InstanceID>0</InstanceID><Channel>Master</Channel><DesiredVolume>" & SONOS_VOL & "</DesiredVolume></u:SetVolume></s:Body></s:Envelope>"
	
	P += "POST /MediaRenderer/RenderingControl/Control HTTP/1.1" & CRLF
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
		Color 6,0
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
Function ResolveSonosTarget(ByVal target As String) As String
	target = Trim(target)
	If target = "" Then Return ""
	
	Dim iniPath As String = ExePath & "\SonosControl.ini"
	
	' 1. Check if target is a RINCON device ID
	If UCase(Left(target, 6)) = "RINCON" Then
		Dim ip As String = ini.getString("Devices", target, "", iniPath)
		If ip <> "" Then Return ip
	EndIf
	
	' 2. Search [Names] section for matching Room/Zone Name (case-insensitive)
	Dim buffer As ZString * 32768
	Dim res As Long = GetPrivateProfileSection("Names", @buffer, 32768, iniPath)
	If res > 0 Then
		Dim p As ZString Ptr = @buffer
		While *p <> ""
			Dim entry As String = *p
			Dim eqPos As Integer = InStr(entry, "=")
			If eqPos > 0 Then
				Dim rinconId As String = Trim(Left(entry, eqPos - 1))
				Dim roomName As String = Trim(Mid(entry, eqPos + 1))
				If LCase(roomName) = LCase(target) Then
					Dim ip As String = ini.getString("Devices", rinconId, "", iniPath)
					If ip <> "" Then Return ip
				EndIf
			EndIf
			p += Len(entry) + 1
		Wend
	EndIf
	
	' 3. Check if target is directly defined in [Devices]
	Dim directIp As String = ini.getString("Devices", target, "", iniPath)
	If directIp <> "" Then Return directIp
	
	' 4. If target contains dots (e.g. IP address or hostname), return as-is
	If InStr(target, ".") > 0 Then
		Return target
	EndIf
	
	Return ""
End Function

'##############################################################################################################
'##############################################################################################################
'##############################################################################################################
Dim BV As Integer									'Variable fr Statusrckgabe erstellen
Dim rawTarget As String = Command(1)
Dim SonosIP As String = ResolveSonosTarget(rawTarget)
Dim SonosCmd As String = Command(2)

If SonosIP = "" Or SonosCmd = "" Then
	Print
	Print "SonosControl (" & APP_VERSION & ") by M. Lindner"
	Print
	If rawTarget <> "" And SonosIP = "" Then
		Print "Error: Device or Room '" & rawTarget & "' not found in SonosControl.ini"
		Print
	EndIf
	Print "usage: SonosControl <IP, NAME or RINCON_ID> <COMMAND> [VALUE]"
	Print
	Print "example: SonosControl 192.168.178.1 SCAN"
	Print "         (IP = any ip from your network | ip of router)"
	Print
	Print "example: SonosControl Arbeitszimmer PLAY"
	Print "example: SonosControl RINCON_B8E93733EF4001400 PLAY"
	Print "example: SonosControl RINCON_B8E93733EF4001400 PAUSE"
	Print "example: SonosControl RINCON_B8E93733EF4001400 VOLUME 10"
	Print
	Print "press any key to exit..."
	Sleep
	End
EndIf

SONOS_IP = SonosIP
SONOS_PORT = 1400

If UCase(SonosCmd) = "VOLUME" Or UCase(SonosCmd) = "VOL" Then
	Dim rawVol As String = Trim(Command(3))
	If rawVol = "" Then
		Print "Error: Volume level (0-100) is required for command " & SonosCmd
		Print
		Print "usage: SonosControl <IP, NAME or RINCON_ID> VOLUME <0-100>"
		Print
		Print "press any key to exit..."
		Sleep
		End
	EndIf
	
	Dim isValidNumber As Integer = 1
	For vi As Integer = 1 To Len(rawVol)
		Dim ch As String = Mid(rawVol, vi, 1)
		If ch < "0" Or ch > "9" Then
			isValidNumber = 0
			Exit For
		EndIf
	Next vi
	
	Dim volVal As Integer = ValInt(rawVol)
	If isValidNumber = 0 Or volVal < 0 Or volVal > 100 Then
		Print "Error: Invalid volume level '" & rawVol & "' - must be an integer between 0 and 100"
		Print
		Print "usage: SonosControl <IP, NAME or RINCON_ID> VOLUME <0-100>"
		Print
		Print "press any key to exit..."
		Sleep
		End
	EndIf
	
	SONOS_VOL = Trim(Str(volVal))
EndIf

'BV = TSNE_Create_Client(G_Client, "www.google.de", 80, @TSNE_Disconnected, @TSNE_Connected, @TSNE_NewData, 60)

Select Case UCase(SonosCmd)
	Case "SCAN"
		Dim i As Integer
		
		i = InStrRev(SonosIP, ".")
		SONOS_IP = Left(SonosIP, i)
		
		Print "Scanning - please wait..."
		
		If hMutexThreadsOpen = 0 Then hMutexThreadsOpen = MutexCreate()
		If hMutexIniWrite = 0 Then hMutexIniWrite = MutexCreate()
		THREADS_OPEN = 0
		
		For i = 1 To 254
		    If hMutexThreadsOpen <> 0 Then MutexLock(hMutexThreadsOpen)
		    THREADS_OPEN = THREADS_OPEN + 1
		    If hMutexThreadsOpen <> 0 Then MutexUnlock(hMutexThreadsOpen)
		    
		    Dim tHandle As Any Ptr = ThreadCreate(Cast(Any Ptr,@threadSonosScan), Cast(Any Ptr, i))
		    If tHandle = 0 Then
		        If hMutexThreadsOpen <> 0 Then MutexLock(hMutexThreadsOpen)
		        THREADS_OPEN = THREADS_OPEN - 1
		        If hMutexThreadsOpen <> 0 Then MutexUnlock(hMutexThreadsOpen)
		    EndIf
		    Sleep 10
		Next i
		
		Do
		    Sleep 100
		    Dim activeThreads As Integer = 0
		    If hMutexThreadsOpen <> 0 Then MutexLock(hMutexThreadsOpen)
		    activeThreads = THREADS_OPEN
		    If hMutexThreadsOpen <> 0 Then MutexUnlock(hMutexThreadsOpen)
		    If activeThreads = 0 Then Exit Do
		Loop Until Inkey = Chr(27) 
		
		If hMutexThreadsOpen <> 0 Then
			MutexDestroy(hMutexThreadsOpen)
			hMutexThreadsOpen = 0
		EndIf
		If hMutexIniWrite <> 0 Then
			MutexDestroy(hMutexIniWrite)
			hMutexIniWrite = 0
		EndIf
		
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

'	Statusr�ckgabe auswerten
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

