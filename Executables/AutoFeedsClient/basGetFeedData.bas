Attribute VB_Name = "basGetFeedData"
Option Explicit

'Private Declare Function GetPrivateProfileString Lib "kernel32.dll" Alias "GetPrivateProfileStringA" (ByVal lpApplicationName As String, ByVal lpKeyName As Any, ByVal lpDefault As String, ByVal lpReturnedString As String, ByVal nSize As Long, ByVal lpFileName As String) As Long

'---------------------------------------------------------------------------------------
' Procedure : Main
' DateTime  : 3/12/2004 16:57
' Author    : CRey
' Purpose   : Calls component
'---------------------------------------------------------------------------------------
Public Sub Main()
  On Error GoTo RunFeedsError

  Dim strEFID As String
  Dim strMsgToUser As String
  Dim blnBadData As Boolean
  'Dim strMode As String
  Dim strUseNewClass As String
  'Dim lngVal As Long

  Const DEFAULT_MODE = "OLD"
  Const INI_FILE = "d:\data\db\AutoFeeds.xml"
  
  'lngVal = GetPrivateProfileString("SELECT_MODE", "MODE", "", strMode, 4, INI_FILE)
  
  'If lngVal = 0 Then strMode = DEFAULT_MODE
  
  strEFID = Command()
  
  If ((InStr(strEFID, ":") > 0) Or (strEFID = "RUNTEST")) Then
    'If UCase(strMode) = "NEW" Then
      Dim clsNewMode As Object
      
      Set clsNewMode = CreateObject("Auto_Feed_Biz.clsScheduler")
      
      clsNewMode.RunTime = strEFID
      
      Call clsNewMode.GetSchedule
      
      Set clsNewMode = Nothing
    'End If
  Else
    'This program gets the autofeedid
    strMsgToUser = "To run this program you must provide an autofeedemedia id or a an emedia id and a client id separated by a dash."
    
    'if the user entered a value to process, verify they are numeric
    If Trim(strEFID) <> "" And Trim(strEFID) <> "CID" Then
    
      'Now see if the user intends to run a single or multiple clients per emedia
      If InStr(strEFID, "-") = 0 Then ' No dash in param means multiple client runs
        If Not IsNumeric(strEFID) Then
          blnBadData = True
        End If
      Else
        'If any of the parts of the param is not a number then there is bad data coming in
        If (Val(Left(strEFID, InStr(strEFID, "-") - 1)) = 0) Or (Not IsNumeric(Mid(strEFID, InStr(strEFID, "-") + 1, Len(strEFID)))) Then
          If (Left(strEFID, 4) <> "TEST") Then blnBadData = True
        End If
      End If
    Else ' The user didn't enter a value
      blnBadData = True
    End If
    
    'If we found bad data coming in as a param then stop the program
    If blnBadData Then
      Err.Raise "-2", App.EXEName, "Bad Parameters passed to run feed" & vbCrLf & "Parameters passed: " & strEFID & vbCrLf & "Line number: " & Erl & vbCrLf & "Date=" & Date & vbCrLf & "Time=" & Time
    End If
    
    Dim clsAutoFeed As Object ' Auto_Feed_Biz.clsTypeOfFeed
    
    'lngVal = GetPrivateProfileString("NEW_CLASS", "USE", "Y", strUseNewClass, 2, INI_FILE)
    
'    If (strUseNewClass = "N") Then
      'Set clsAutoFeed = CreateObject("Auto_Feed_Biz.clsTypeOfFeed")
    'Else
      Set clsAutoFeed = CreateObject("Auto_Feed_Biz.clsTypeOfFeed_New")
    'End If
      
    clsAutoFeed.FromSchedule = False
    clsAutoFeed.RunFeed strEFID
    
    Set clsAutoFeed = Nothing
  End If
  
  Exit Sub

RunFeedsError:
  Dim clsBadData As New SmartPostError.CLog
    
  clsBadData.LogEvent App.EXEName, Err.Number, "Executable RunAutoFeeds", Err.Description, 1, "errors@pubfolders.hodesiq.com", ""
  
  Set clsBadData = Nothing
  Set clsAutoFeed = Nothing
End Sub


