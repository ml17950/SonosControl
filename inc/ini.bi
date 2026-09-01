#print "using ini.bi                by M. Lindner | created ??.??.???? | updated 28.02.2018"

'#If __FB_VERSION__ < "1.00"
	'Declare Function fbGetPrivateProfileString Lib "kernel32" Alias "GetPrivateProfileStringA" (ByVal lpApplicationName As String, ByVal lpKeyName As String, ByVal lpDefault As String, ByVal lpReturnedString As String, ByVal nSize As Long, ByVal lpFileName As String) As Long
	'Declare Function fbWritePrivateProfileString Lib "kernel32" Alias "WritePrivateProfileStringA" (ByVal lpApplicationName As String, ByVal lpKeyName As String, ByVal lpString As String, ByVal lpFileName As String) As Long
'#Else
	#Include Once "windows.bi"
'#EndIf

Namespace ini
	Function getString(ByVal sSection As String, ByVal sKey As String, ByVal sDefault As String = "", ByVal sFile As String = "") As String
		Dim tmp As String * 1280
		Dim dflt As String = ""
		Dim file As String
		Dim res As Long
		
		If sFile = "" Then
			file = Left(Command(0), InStrRev(Command(0), ".")) & "ini"
		Else
			file = sFile
		EndIf
		
		res = GetPrivateProfileString(sSection, sKey, dflt, tmp, Len(tmp), file)
		
		If res = 0 Then
			Return sDefault
		Else
			Return Left(tmp, res)
		EndIf
	End Function
	
	Function getInteger(ByVal sSection As String, ByVal sKey As String, ByVal nDefault As Integer = -1, ByVal sFile As String = "") As Integer
		Dim r As String = getString(sSection, sKey, "d", sFile)
		
		If r = "d" Then
			Return nDefault
		Else
			Return CInt(r)
		EndIf
	End Function
	
	Function getSingle(ByVal sSection As String, ByVal sKey As String, ByVal nDefault As Single = -1, ByVal sFile As String = "") As Single
		Dim r As String = getString(sSection, sKey, "d", sFile)
		
		If r = "d" Then
			Return nDefault
		Else
			Return CSng(r)
		EndIf
	End Function
	
	Function getBoolean(ByVal sSection As String, ByVal sKey As String, ByVal nDefault As Byte = 0, ByVal sFile As String = "") As Byte
		Dim r As String = getString(sSection, sKey, "d", sFile)
		
		If r = "d" Then
			Return nDefault
		Else
			Select Case LCase(r)
				Case "1", "true", "wahr", "yes", "ja"
					Return 1
				Case Else
					Return 0
			End Select
		EndIf
	End Function
	
	Sub setString(ByVal sSection As String, ByVal sKey As String, ByVal sValue As String, ByVal sFile As String = "")
		Dim file As String
		
	   If sFile = "" Then
	   	file = Left(Command(0), InStrRev(Command(0), ".")) & "ini"
	   Else
	   	file = sFile
	   EndIf
	   
	   WritePrivateProfileString sSection, sKey, sValue, file
	End Sub
	
	Sub setInteger(ByVal sSection As String, ByVal sKey As String, ByVal nValue As Integer, ByVal sFile As String = "")
		setString(sSection, sKey, Str(nValue), sFile)
	End Sub
	
	Sub setSingle(ByVal sSection As String, ByVal sKey As String, ByVal nValue As Single, ByVal sFile As String = "")
		setString(sSection, sKey, Str(nValue), sFile)
	End Sub
	
	Sub setBoolean(ByVal sSection As String, ByVal sKey As String, ByVal nValue As Byte, ByVal sFile As String = "")
		If nValue = 1 then
			setString(sSection, sKey, "1", sFile)
		Else
			setString(sSection, sKey, "0", sFile)
		EndIf
	End Sub
	
	Sub delKey(ByVal sSection As String, ByVal sKey As String, ByVal sFile As String = "")
		Dim file As String
		
	   If sFile = "" Then
	   	file = Left(Command(0), InStrRev(Command(0), ".")) & "ini"
	   Else
	   	file = sFile
	   EndIf
	   
	   WritePrivateProfileString sSection, sKey, NULL, file
	End Sub
	
	Sub delSection(ByVal sSection As String, ByVal sFile As String = "")
		Dim file As String
		
	   If sFile = "" Then
	   	file = Left(Command(0), InStrRev(Command(0), ".")) & "ini"
	   Else
	   	file = sFile
	   EndIf
	   
	   WritePrivateProfileString sSection, NULL, NULL, file
	End Sub
	
	'Function getValue(ByVal sSection As String, ByVal sKey As String, ByVal sDefault As String, ByVal sFile As String) As String
	'	Dim As Integer f, is_section, p
	'	Dim As String ret, dat, tmp
	'	
	'	ret = sDefault
	'	
	'	f = FreeFile
	'	If Open(sFile For Input As #f) = 0 Then
	'		Do Until Eof(f)
	'			Line Input #f, dat
	'			
	'			If dat <> "" Then
	'				'Print "line: " & dat
	'				Select Case Left(dat, 1)
	'					Case ";", "#"
	'						' comment >> irgnore
	'					
	'					Case "["
	'						' section
	'						tmp = Mid(dat, 2, Len(dat) - 2)
	'						Print "check sec: " & tmp & "/" & sSection
	'						If LCase(tmp) = LCase(sSection) Then
	'							is_section = 1
	'						Else
	'							is_section = 0
	'						EndIf
	'					
	'					Case Else
	'						' value
	'						If is_section = 1 Then
	'							p = InStr(dat, "=")
	'							'Print "value: " & dat & "/" & p
	'							If p > 0 Then
	'								tmp = Left(dat, p-1)
	'								Print "check val: " & tmp & "/" & sKey
	'								'Print "val#1: " & tmp
	'								If LCase(tmp) = LCase(sKey) Then
	'									tmp = Mid(dat, p+1)
	'									Print "set retvl: " & tmp
	'									Print
	'									
	'									ret = tmp
	'								EndIf
	'							EndIf
	'						EndIf
	'				End Select
	'			EndIf
	'		Loop
	'		Close #f
	'	EndIf
	'	
	'	Return ret
	'End Function
End Namespace

