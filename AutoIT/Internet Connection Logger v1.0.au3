#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Resources\phoenix.ico
#AutoIt3Wrapper_Outfile=Builds\Internet Connection Logger v1.0.exe
#AutoIt3Wrapper_Outfile_x64=Builds\Internet Connection Logger v1.0 64-bit(x64).exe
#AutoIt3Wrapper_Compile_Both=n
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Res_Comment=http://www.Phoenix125.com
#AutoIt3Wrapper_Res_Description=Internet Connection Logger
#AutoIt3Wrapper_Res_Fileversion=v1.0.0
#AutoIt3Wrapper_Res_ProductName=Internet Connection Logger
#AutoIt3Wrapper_Res_ProductVersion=v1.0.0
#AutoIt3Wrapper_Res_CompanyName=http://www.Phoenix125.com
#AutoIt3Wrapper_Res_LegalCopyright=http://www.Phoenix125.com
#AutoIt3Wrapper_Res_Icon_Add=Resources\phoenixfaded.ico
#AutoIt3Wrapper_Res_Icon_Add=Resources\phoenixbusy2.ico
#AutoIt3Wrapper_Run_AU3Check=n
#AutoIt3Wrapper_AU3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6
#AutoIt3Wrapper_Run_Au3Stripper=y
#Au3Stripper_Parameters=/mo
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <Date.au3>
#include <Inet.au3>
#include <MsgBoxConstants.au3>
Global $aUtilName = "Internet Connection Logger"
Global $tQuit = False
Global $aIniFile = $aUtilName & ".ini"
Global $aIconFile = @ScriptFullPath
TraySetIcon($aIconFile, 99)
ReadIni()
Opt("TrayMenuMode", 3) ; The default tray menu items will not be shown and items are not checked when selected. These are options 1 and 2 for TrayMenuMode.
Opt("TrayOnEventMode", 1) ; Enable TrayOnEventMode.
Global $iTrayLogWeb[$aWebCount + 1]
$iTrayLogWeb[0] = $aWebCount
Global $aActiveURLs = 0
For $i = 1 To $aWebCount
	If $xWebURL[$i] Not = "" Then
		$aActiveURLs += 1
		If $aActiveURLs = 26 Then ExitLoop
		$iTrayLogWeb[$i] = TrayCreateItem("Open " & $xLogFile[$i])
		TrayItemSetOnEvent(-1, "TrayLogWeb")
	EndIf
Next
TrayCreateItem("") ; Create a separator line.
Local $iTrayLogAll = TrayCreateItem("Open Log All Latest")
TrayItemSetOnEvent(-1, "iTrayLogAll")
Local $iTrayLogFolder = TrayCreateItem("Open Log Folder")
TrayItemSetOnEvent(-1, "iTrayLogFolder")
TrayCreateItem("") ; Create a separator line.
Global $iTrayLastPoll = TrayCreateItem("Last Poll:")
TrayCreateItem("") ; Create a separator line.
Local $iTrayExitCloseY = TrayCreateItem("Exit")
TrayItemSetOnEvent(-1, "iTrayExit")
LogWrite('-------------- PROGRAM STARTED --------------')
Do
	Local $tInit = TimerInit()
	SetStatusBusy()
	PollWeb()
	Local $tAllReply = True
	For $i = 1 To $aWebCount
		If $aWebReply[$i] = "no" Then
			$tAllReply = False
			ExitLoop
		EndIf
	Next
	If $tAllReply Then TraySetIcon($aIconFile, 202)
	SetStatusIdle()
	TrayItemSetText($iTrayLastPoll, "Last Poll: " & _NowCalc())
	Sleep(($aInterval * 1000) - (TimerDiff($tInit)))
	If $aActiveURLs > 3 Then LogWrite("")
Until $tQuit

Func PollWeb()
	Local $tText = ""
	For $i = 1 To $aWebCount
		If $xWebURL[$i] Not = "" Then
			$aWebReply[$i] = IniRead($aIniFile, "System Use", "Web " & $i & " Last Reply (YN)", "no")
			Local $tRead = _INetGetSource($xWebURL[$i])
			If @error Or $tRead = "" Then ; NO RESPONSE
				If $aLogDetails = "4" Then
					LogWrite('[Web' & $i & '] [NO REPLY] No reply from website: ' & $xWebURL[$i] & ' "' & StringLeft($tRead, 80) & '"')
				ElseIf $aLogDetails = "3" Then
					LogWrite('[Web' & $i & '] [NO REPLY]')
				ElseIf $aLogDetails = "2" Then
					$tText &= '[Web' & $i & ':NO REPLY] '
				EndIf
				If $aWebReply[$i] = "yes" Or $aWebReply[$i] = "Not Checked Yet" Then
					IniWrite($aIniFile, "System Use", "Web " & $i & " Last Reply (YN)", "no")
					ErrorWriteWeb($i, '[Web' & $i & '] [ERROR] Connection Lost [' & $xWebURL[$i] & ']')
					TraySetIcon($aIconFile, 202)
				EndIf
			Else ; OK RESPONSE
				If $aLogDetails = "4" Then
					LogWrite('[Web' & $i & '] [OK] ' & $xWebURL[$i] & ' "' & StringLeft($tRead, 80) & '"')
				ElseIf $aLogDetails = "3" Then
					LogWrite('[Web' & $i & '] [OK]')
				ElseIf $aLogDetails = "2" Then
					$tText &= '[Web' & $i & ':OK] '
				EndIf
				If $aWebReply[$i] = "no" Or $aWebReply[$i] = "Not Checked Yet" Then
					IniWrite($aIniFile, "System Use", "Web " & $i & " Last Reply (YN)", "yes")
					ErrorWriteWeb($i, '[Web' & $i & '] [OK] Connection Found [' & $xWebURL[$i] & ']')
					TraySetIcon($aIconFile, 99)
				EndIf
			EndIf
		EndIf
	Next
	If $aLogDetails = "2" Then LogWrite($tText)
EndFunc   ;==>PollWeb
Func LogWrite($Msg)
	$aLogFile = $aLogFolder & $aUtilName & "_Log_" & @YEAR & "-" & @MON & "-" & @MDAY & ".txt"
	FileWriteLine($aLogFile, _NowCalc() & " " & $Msg)
EndFunc   ;==>LogWrite
Func ErrorWriteWeb($i, $Msg)
	FileWriteLine($aLogFolder & $xLogFile[$i], _NowCalc() & " " & $Msg)
EndFunc   ;==>ErrorWriteWeb
Func ReadIni()
	Global $aWebCount = IniRead($aIniFile, $aUtilName, "Number of websites to monitor. Changes require restart for new lines to appear. (1-99)", "2")
	If $aWebCount < 2 Then $aWebCount = 1
	If $aWebCount > 99 Then $aWebCount = 99
	Global $aInterval = IniRead($aIniFile, $aUtilName, "Poll Interval (Seconds)", 60)
	Global $aLogDetails = IniRead($aIniFile, $aUtilName, "Combined Log File: 1-None, 2-Condensed, 3-Basic, 4-Detailed (1,2,3,4)", "2")
	Global $aLogFolder = IniRead($aIniFile, $aUtilName, "Log Folder", @ScriptDir & "\ICL_Logs\")
	Global $aLogFileFull = IniRead($aIniFile, $aUtilName, "Combined Log File Name", "Log Combined.txt")
	Global $xWebURL[$aWebCount + 1]
	$xWebURL[0] = $aWebCount
	For $i = 1 To $aWebCount
		If $i = 1 Then
			$xWebURL[$i] = IniRead($aIniFile, $aUtilName, "Web " & $i & " URL", "www.google.com")
		ElseIf $i = 2 Then
			$xWebURL[$i] = IniRead($aIniFile, $aUtilName, "Web " & $i & " URL", "www.phoenix125.com")
		Else
			$xWebURL[$i] = IniRead($aIniFile, $aUtilName, "Web " & $i & " URL", "")
		EndIf
	Next
	Global $xLogFile[$aWebCount + 1]
	$xLogFile[0] = $aWebCount
	For $i = 1 To $aWebCount
		$xLogFile[$i] = IniRead($aIniFile, $aUtilName, "Web " & $i & " Log Filename", "Log Status Change Web " & $i & ".txt")
	Next
	Global $aWebReply[$aWebCount + 1]
	$aWebReply[0] = $aWebCount
	For $i = 1 To $aWebCount
		$aWebReply[$i] = IniRead($aIniFile, "System Use", "Web " & $i & " Last Reply (YN)", "Not Checked Yet")
		If FileExists($aLogFolder & $xLogFile[$i]) = 0 Then
			$aWebReply[$i] = "Not Checked Yet"
			IniWrite($aIniFile, "System Use", "Web " & $i & " Last Reply (YN)", $aWebReply[$i])
		EndIf
	Next
	Global $iWebCount = IniRead($aIniFile, "System Use", "Last Web Count", "2")

	If FileExists($aLogFolder) = 0 Then
		DirCreate($aLogFolder)
		Local $tFirstRun = True
	Else
		Local $tFirstRun = False
	EndIf
	FileDelete($aIniFile)
	IniWrite($aIniFile, $aUtilName, "Number of websites to monitor. Changes require restart for new lines to appear. (1-99)", $aWebCount)
	IniWrite($aIniFile, $aUtilName, "Poll Interval (Seconds)", $aInterval)
	IniWrite($aIniFile, $aUtilName, "Combined Log File: 1-None, 2-Condensed, 3-Basic, 4-Detailed (1,2,3,4)", $aLogDetails)
	IniWrite($aIniFile, $aUtilName, "Log Folder", $aLogFolder)
	IniWrite($aIniFile, $aUtilName, "Combined Log File Name", $aLogFileFull)
	For $i = 1 To $aWebCount
		IniWrite($aIniFile, $aUtilName, "Web " & $i & " URL", $xWebURL[$i])
	Next
	For $i = 1 To $aWebCount
		IniWrite($aIniFile, $aUtilName, "Web " & $i & " Log Filename", $xLogFile[$i])
	Next
	For $i = 1 To $aWebCount
		IniWrite($aIniFile, "System Use", "Web " & $i & " Last Reply (YN)", $aWebReply[$i])
	Next
	IniWrite($aIniFile, "System Use", "Last Web Count", $aWebCount)
	If $iWebCount <> $aWebCount Then
		Local $tMB = MsgBox($MB_OKCANCEL, $aUtilName, "Number of websites to monitor changed." & @CRLF & @CRLF & _
				"Click [OK] to Exit and open config file" & @CRLF & _
				"Click [CANCEL] to Exit", 60)
		If $tMB = 6 Then             ; YES
		ElseIf $tMB = 7 Then             ; NO
		ElseIf $tMB = 2 Then ; CANCEL
			Exit
		ElseIf $tMB = 1 Then ; OK
			ShellExecute($aIniFile)
			Exit
		ElseIf $tMB = -1 Then             ; TIMEOUT
			Exit
		EndIf
	EndIf
	If $tFirstRun Then
		Local $tMB = MsgBox($MB_OKCANCEL, $aUtilName, "Thank you for trying " & $aUtilName & "." & @CRLF & _
				"Please make changes to the config file and restart program." & @CRLF & @CRLF & _
				"Click [OK] to Exit and open config file" & @CRLF & _
				"Click [CANCEL] to Exit", 60)
		If $tMB = 6 Then             ; YES
		ElseIf $tMB = 7 Then             ; NO
		ElseIf $tMB = 2 Then ; CANCEL
			Exit
		ElseIf $tMB = 1 Then ; OK
			ShellExecute($aIniFile)
			Exit
		ElseIf $tMB = -1 Then             ; TIMEOUT
			Exit
		EndIf
	EndIf
	For $i = 1 To $aWebCount
		If $xWebURL[$i] Not = "" Then
			If StringInStr($xWebURL[$i], "http://") = 0 Then $xWebURL[$i] = "http://" & $xWebURL[$i]
		EndIf
	Next
EndFunc   ;==>ReadIni
Func iTrayLogFolder()
	ShellExecute($aLogFolder)
EndFunc   ;==>iTrayLogFolder
Func iTrayLogAll()
	ShellExecute($aLogFolder & $aUtilName & "_Log_" & @YEAR & "-" & @MON & "-" & @MDAY & ".txt")
EndFunc   ;==>iTrayLogAll
Func iTrayExit()
	$tQuit = True
	Exit
EndFunc   ;==>iTrayExit
Func SetStatusBusy()
	TraySetToolTip("[Busy] " & $aUtilName)
	Local $tAllReply = True
	For $i = 1 To $aWebCount
		If $aWebReply[$i] = "no" Then
			$tAllReply = False
			ExitLoop
		EndIf
	Next
	If $tAllReply Then TraySetIcon($aIconFile, 201)
EndFunc   ;==>SetStatusBusy
Func SetStatusIdle()
	TraySetToolTip("[Idle] " & $aUtilName)
	Local $tAllReply = True
	For $i = 1 To $aWebCount
		If $aWebReply[$i] = "no" Then
			$tAllReply = False
			ExitLoop
		EndIf
	Next
	If $tAllReply Then TraySetIcon($aIconFile, 99)
EndFunc   ;==>SetStatusIdle
Func TrayLogWeb()
	Local $tGID = @TRAY_ID
	For $i = 1 To $aWebCount
		If $tGID = $iTrayLogWeb[$i] Then
			$tClicked = $i
			ExitLoop
		EndIf
	Next
	ShellExecute($aLogFolder & $xLogFile[$i])
EndFunc   ;==>TrayLogWeb
