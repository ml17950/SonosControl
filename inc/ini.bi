#print "using ini.bi                by M. Lindner | created ??.??.???? | updated 28.02.2018"

#Include Once "windows.bi"

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
End Namespace

