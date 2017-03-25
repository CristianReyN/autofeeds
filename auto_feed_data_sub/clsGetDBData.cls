VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 3  'UsesTransaction
END
Attribute VB_Name = "clsGetDBData"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = True
'---------------------------------------------------------------------------------------
' Module    : clsGetDBData
' Author    : crey
' Date      : 2/28/2011
' Purpose   :
'---------------------------------------------------------------------------------------

Option Explicit

Private Declare Function CoCreateGuid_Alt Lib "OLE32.DLL" Alias "CoCreateGuid" (pGuid _
    As Any) As Long
Private Declare Function StringFromGUID2_Alt Lib "OLE32.DLL" Alias "StringFromGUID2" _
    (pGuid As Any, ByVal address As Long, ByVal Max As Long) As Long

'Private Declare Function GetPrivateProfileString Lib "kernel32.dll" Alias "GetPrivateProfileStringA" (ByVal lpApplicationName As String, ByVal lpKeyName As Any, ByVal lpDefault As String, ByVal lpReturnedString As String, ByVal nSize As Long, ByVal lpFileName As String) As Long
'Private Declare Function WritePrivateProfileString Lib "KERNEL32" Alias "WritePrivateProfileStringA" (ByVal lpApplicationName As String, ByVal lpKeyName As Any, ByVal lpString As Any, ByVal lpFileName As String) As Long

'User defined type for database connections
'Private Type DB_CONNECTION
'  strDS As String
'  strDB As String
'  strPw As String
'  strUs As String
'  strDP As String
'  intCO As Integer
'  blnPr As Boolean
'End Type
'test
Const FEED_ACTIVE = 0

Const QUEUED As Boolean = True

'Private UDT_DbConnection As DB_CONNECTION

'User Defined Type for list of procs called from this component.
Private Type StoredProcedureList
  strGetCommonData As String
  strGetZip As String
  strUpdateHistory As String
  strUpdateDateSent As String
  strSetJoinedData As String
  strUpdateHistoryFinal As String
  strAutoFeedTest As String
  strGetDescription As String
  strLogEvent As String
  strUpdateEvent As String
  strGetEncodes As String
  strGetFileContent As String
  strSaveFileContent As String
  strDeleteFileContent As String
  strBackUpFileContent As String
  strVerifyProcExists As String
  strGetContactInfo As String
  strUpdateDevDebugVal As String
  strInsertCareerBuilder As String
  strVerifyCBL As String
  strDeleteCareerBuilder As String
End Type

Private Type GuidsList
  strGuidGetJobs As String
  strGuidGetCustomData As String
  strGuidUpdateTable As String
End Type
Private Guids As GuidsList

'API calls used by GetNewGuid()
'***********************************************************
'Private Type GUID
'  Data1 As Long
'  Data2 As Long
'  Data3 As Long
'  Data4(8) As Byte
'End Type
'
'Private Declare Function CoCreateGuid Lib "ole32.dll" ( _
'  pguid As GUID) As Long
'
'Private Declare Function StringFromGUID2 Lib "ole32.dll" ( _
'  rguid As Any, _
'  ByVal lpstrClsId As Long, _
'  ByVal cbMax As Long) As Long
'**********************************************************

Private strCBLGuid As String
Private strListOfExcludedQCodes As String
Private strMachine As String
Private strTroubledEmedia As String
Private lngVal As Long
Private blnDebug As Boolean
'Private strDebug As String '* 6
'Private strDataLog As String '* 1
'Private strDataLogFile As String * 40
Private strKeepSourceList As String
Private strOrderEmediaID As String
'Private strGetFieldValue As String
Private rsMultiSource As ADODB.Recordset ' Used to accumulate the records from all servers.
Private rsJobsRecordset As ADODB.Recordset ' Used to return rsMultisource.
Private blnGetDescription As Boolean
Private intAutoFeedID As Integer
Private blnUsesSlotQtyDelete As Boolean
Private intQtyAllowed As Integer
Private blnUsesSlotQty As Boolean
Private blnSaveAsXML As Boolean
Private strNoConvMediaID As String
Private strExcludedHorgs As String
Private strSplitExcludedHorgs() As String
Private blnNewOrdering As Boolean
Private strRegExNoHTMLComments As String
Private strRegExNoHTMLAttributes As String
Private strRegExExcludedAttribMedia As String
'Private strCheckDups As String ' * 2

Const DEFAULT_DEBUG = "False"
Const DEFAULT_LOG_DATA_SPLIT = "N"
Const DEFAULT_LOG_DATA_FILE = "d:\data\db\AutofeedDataSplitLog.csv"
Const MASTER_SOURCE = "Autofeeds.udl" ' "IQ2.udl" '
Const UDL_PATH = "d:\data\DB\"

Private typProcsList As StoredProcedureList
Private ADORSJN As ADODB.Recordset
Private adocn As ADODB.Connection
Private blnISXML As Boolean
Private blnEncode As Boolean
Private blnPartialHTMLStrip As Boolean
Private blnHTMLStrip As Boolean
Private blnHTMLEncode As Boolean
Private blnConvAreaToHTML As Boolean
Private intCommandTimeOut As Integer
Private blnLogEvent As Boolean
Private strSubType3Source As String
Private blnUseSubID As Boolean
Private lngSubID As Long
Private strFromEmail As String

'Private strSQL As String
Const BY_FILENAME = 0
Const BY_USERNAME = 1
'added for history table additions

Const MONSTER = "3060"
Const MONSTER_10457 = "10457"

Private clsObjXmlSettings As Auto_Feed_XML.clsXMLSettings

Private RSEncode As ADODB.Recordset  ' for Ticket # 124303

Private Function CreateGUID() As String
    Dim res As String, resLen As Long, guid(15) As Byte
    res = Space$(128)
    CoCreateGuid_Alt guid(0)
    resLen = StringFromGUID2_Alt(guid(0), ByVal StrPtr(res), 128)
    CreateGUID = Replace(Replace(Left$(res, resLen - 1), "{", vbNullString), "}", vbNullString)
End Function

Public Function InsertCareerbuilderJobs(ByVal strEmediaID As String) As Integer
        Dim lngRecsAffected As Long
        Dim ADOCM As ADODB.Command
        Dim strMethod As String
        
10      strCBLGuid = CreateGUID()

20      strMethod = "InsertCareerbuilderJobs"

30      Set ADOCM = New ADODB.Command

40      Call SetConnection(MASTER_SOURCE)

50      With ADOCM
60        Set .ActiveConnection = adocn
70        .CommandType = adCmdStoredProc
80        .CommandText = typProcsList.strInsertCareerBuilder
81        .CommandTimeout = CInt(clsObjXmlSettings.GetXMLSettings("TROUBLED_MEDIA", "COMMAND_TIME", "600"))

90        .Parameters.Append .CreateParameter("@EmediaID", adVarChar, adParamInput, 6, strEmediaID)
100       .Parameters.Append .CreateParameter("@Guid", adVarChar, adParamInput, 40, strCBLGuid)

110       .Execute lngRecsAffected

120       InsertCareerbuilderJobs = lngRecsAffected
130     End With

140     Call UnsetConnection

150     Set ADOCM = Nothing
End Function

Public Function DeleteCareerbuilderJobs() As Integer
        Dim lngRecsAffected As Long
        Dim ADOCM As ADODB.Command
        Dim strMethod As String

30      strMethod = "DeleteCareerbuilderJobs"

40      Set ADOCM = New ADODB.Command

50      Call SetConnection(MASTER_SOURCE)

60      With ADOCM
70        Set .ActiveConnection = adocn
80        .CommandType = adCmdStoredProc
90        .CommandText = typProcsList.strDeleteCareerBuilder
91        .CommandTimeout = 600 ' Just in case.

100       .Parameters.Append .CreateParameter("@Guid", adVarChar, adParamInput, 40, strCBLGuid)

110       .Execute lngRecsAffected

120       DeleteCareerbuilderJobs = lngRecsAffected
130     End With

140     Call UnsetConnection

150     Set ADOCM = Nothing
End Function

Public Function VerifyItIsCareerbuilder(ByVal strEmediaID As String) As Byte
        Dim ADOCM As ADODB.Command
        Dim strErrMessage As String
        Dim strMethod As String

30      strMethod = "VerifyItIsCareerbuilder"

40      Set ADOCM = New ADODB.Command

50      Call SetConnection(MASTER_SOURCE)

60      With ADOCM
70        Set .ActiveConnection = adocn
80        .CommandType = adCmdStoredProc
90        .CommandText = typProcsList.strVerifyCBL

100       .Parameters.Append .CreateParameter("@Guid", adVarChar, adParamInput, 6, strEmediaID)
101       .Parameters.Append .CreateParameter("@MediaCount", adInteger, adParamOutput)

110       .Execute

120       VerifyItIsCareerbuilder = ADOCM.Parameters("@MediaCount").Value
130     End With

140     Call UnsetConnection

150     Set ADOCM = Nothing
End Function

Private Sub AdjustJobFormat(ByRef strText As String, ByVal strBreak As String, ByVal intBreakLen As Integer)
        Dim strLines() As String
        Dim strLine As String
        Dim lngLineCounter As Long
        Dim objString As Object
        Dim blnTextStarted As String
        
10      Set objString = CreateObject("Auto_Feed_Members.clsStringBuilder")
20      objString.Supports_Unicode = False
30      objString.Clear
        
40      strLines = Split(strText, vbNewLine)
        
50      blnTextStarted = False
        
60      For lngLineCounter = 0 To UBound(strLines)
70        strLine = Trim$(strLines(lngLineCounter))
          
80        If (UCase(strLine) = strBreak) Then
90          If (blnTextStarted = False) Then
100           strLine = vbNullString
110         End If
120       Else
130         blnTextStarted = True
140       End If
          
'150       If (Right$(strLine, 4) = vbNewLine) Then
'160         strLine = Left$(strLine, Len(strLine) - 4)
'170         strLine = Trim$(strLine) & vbNewLine
'180       End If
          
190       If (UCase(Right$(strLine, intBreakLen)) = strBreak) Then
200         strLine = Left$(strLine, Len(strLine) - intBreakLen)
210         strLine = Trim$(strLine) & strBreak
220       End If
          
320       objString.Append strLine
330     Next lngLineCounter
        
340     strText = objString.Value
        
440     Do While InStrB(UCase(strText), strBreak & strBreak & strBreak) > 0
450       strText = RegExpReplace(strBreak & strBreak & strBreak, strBreak & strBreak, True, True, strText)
460     Loop

230     Do While (InStrB(UCase(strText), "<UL>" & strBreak) > 0)
240       strText = RegExpReplace("<UL>" & strBreak, "<UL>", True, True, strText)
250     Loop
          
260     Do While (InStrB(UCase(strText), "</UL>" & strBreak) > 0)
270       strText = RegExpReplace("</UL>" & strBreak, "</UL>", True, True, strText)
280     Loop
          
290     Do While ((Left$(UCase(strText), 4) = "<LI>") And (InStrB(UCase(strText), strBreak) > 0))
300      strText = RegExpReplace(strBreak, vbNullString, True, True, strText)
310     Loop
          
611     Do While (InStrB(UCase(strText), "<LI><UL>") > 0)
612       strText = RegExpReplace("<LI><UL>", vbNullString, True, True, strText)
613     Loop
        
614     Do While (InStrB(UCase(strText), "<LI>" & strBreak) > 0)
615       strText = RegExpReplace("<LI>" & strBreak, strBreak, True, True, strText)
616     Loop

617     Do While (InStrB(UCase(strText), strBreak & "<UL>") > 0)
618       strText = RegExpReplace(strBreak & "<UL>", "<UL>", True, True, strText)
619     Loop

630     Set objString = Nothing
End Sub

Private Function IsUnicode(ByVal s As String) As Boolean
      If Len(s) = LenB(s) Then
         IsUnicode = False
      Else
         IsUnicode = True
      End If
End Function
Private Function EncodeDescription(ByVal StringToModify As String) As String
        Dim lngCalcLen As Long
        Dim acode As Integer
        Dim repl As String
        
          'Do this only when absolutely neccessary
10        For lngCalcLen = Len(StringToModify) To 1 Step -1
20      acode = AscW(Mid$(StringToModify, lngCalcLen, 1))
30      Select Case True
          Case (((acode >= 32) And (acode <= 127)) Or ((acode = 10) Or (acode = 13)))
              ' don't touch alphanumeric chars, and don't touch CR, LF, CRLF
40        Case Else
50          repl = "&#" & CStr(acode) & ";"
60      End Select
        
70      If Len(repl) Then
80        StringToModify = Left$(StringToModify, lngCalcLen - 1) & repl & Right$(StringToModify, Len(StringToModify) - lngCalcLen)   ' Mid$(StringToModify, i + 1)
90        repl = ""
100     End If
110       Next lngCalcLen
        
120     EncodeDescription = StringToModify
End Function

Private Function EncodeDescriptionChars(ByVal StringToModify As String) As String
10      If (Not (RSEncode.EOF)) Then
20        Do While Not RSEncode.EOF
30          StringToModify = Replace(StringToModify, RSEncode.Fields("TextToEncode").Value, RSEncode.Fields("TextEncoded").Value)
            
40          RSEncode.MoveNext
50        Loop
          
60        RSEncode.MoveFirst
70      End If
        
80      EncodeDescriptionChars = StringToModify
End Function

Private Sub GetContactInfo(ByVal lngRequisitionID As Long, ByRef strContactAddress1 As String, ByRef strContactAddress2 As String, ByRef strContactCity As String, ByRef strContactState As String, ByRef strContactZip As String)
        Dim ADOCM As ADODB.Command

10      Set ADOCM = New ADODB.Command

20      If (Dir(UDL_PATH & MASTER_SOURCE) <> "") Then
30        Call SetConnection(MASTER_SOURCE)

40        With ADOCM
50          Set .ActiveConnection = adocn
60          .CommandType = adCmdStoredProc
70          .CommandText = typProcsList.strGetContactInfo

80          .Parameters.Append .CreateParameter("@requisition_id", adInteger, adParamInput, 4, lngRequisitionID)
90          .Parameters.Append .CreateParameter("@Address1", adVarChar, adParamOutput, 150)
100         .Parameters.Append .CreateParameter("@Address2", adVarChar, adParamOutput, 150)
110         .Parameters.Append .CreateParameter("@City", adVarChar, adParamOutput, 100)
120         .Parameters.Append .CreateParameter("@State", adVarChar, adParamOutput, 100)
130         .Parameters.Append .CreateParameter("@Zip", adVarChar, adParamOutput, 10)

140         .Execute

150          strContactAddress1 = (.Parameters("@Address1").Value)
160          strContactAddress2 = (.Parameters("@Address2").Value)
170          strContactCity = (.Parameters("@City").Value)
180          strContactState = (.Parameters("@State").Value)
190          strContactZip = (.Parameters("@Zip").Value)
200       End With

210       Call UnsetConnection
220     End If

230     Set ADOCM = Nothing
End Sub

Public Property Let SaveAsXML(ByVal blnAsXML As Boolean)
10      blnSaveAsXML = blnAsXML
End Property

Public Property Let SubID(ByVal lngSubsID As Long)
10      lngSubID = lngSubsID
End Property

Public Property Let prpEncodeDescription(ByVal blnEncodeDesc As Boolean)
10      If (blnEncodeDesc = True) Then
20        If (RSEncode Is Nothing) Then Set RSEncode = GetEncodesListRS()
30      End If
        
40      blnEncode = blnEncodeDesc
End Property

Public Property Get IsXML() As Boolean
10      IsXML = blnISXML
End Property

Public Property Let IsXML(ByVal blnXML As Boolean)
10      If (blnXML = True) Then
20        If (RSEncode Is Nothing) Then Set RSEncode = GetEncodesListRS()
30      End If
        
40      blnISXML = blnXML
End Property

Public Property Let ParamUsed(ByVal strUsedParam As String)
  blnNewOrdering = (InStrB(1, clsObjXmlSettings.GetXMLSettings("DEBUG", "FEED_ORDERING", vbNullString, vbNullString, False), "," & strUsedParam & ",") > 0)
  
  If (blnNewOrdering = True) Then
    typProcsList.strGetCommonData = "Auto_feed_component_get_common_data_byfid"
  Else
    typProcsList.strGetCommonData = "Auto_feed_component_get_common_data"
  End If
End Property

Public Function TestClasses() As ADODB.Recordset
  Dim tstConn As ADODB.Connection
  Dim tstComm As ADODB.Command
  Dim tstRec As ADODB.Recordset
  
  Set tstConn = New ADODB.Connection
  Set tstComm = New ADODB.Command
  Set tstRec = New ADODB.Recordset
  
  With tstConn
    .CursorLocation = adUseClient
    .ConnectionString = "File Name=" & UDL_PATH & "autofeeds.udl"
    .Open
  End With
  
  With tstComm
    .ActiveConnection = tstConn
    .CommandType = adCmdStoredProc
    .CommandText = "dbo.Auto_feed_generator_component_Test_Classes"
    
    'tstRec.CursorLocation = adUseClient
    Set tstRec = .Execute()
    
    Set tstRec.ActiveConnection = Nothing
  End With

  Set TestClasses = tstRec

  If tstConn.State = 1 Then tstConn.Close
  Set tstConn = Nothing
  
  Set tstComm = Nothing
End Function

Public Function GetSchedule(ByVal strTimeToRun As String) As ADODB.Recordset
  Dim tstConn As ADODB.Connection
  Dim tstComm As ADODB.Command
  Dim tstRec As ADODB.Recordset
  
  Set tstConn = New ADODB.Connection
  Set tstComm = New ADODB.Command
  Set tstRec = New ADODB.Recordset
  
  With tstConn
    .CursorLocation = adUseClient
    .ConnectionString = "File Name=" & UDL_PATH & "autofeeds.udl"
    .Open
  End With
  
  With tstComm
    .ActiveConnection = tstConn
    .CommandType = adCmdStoredProc
    .CommandText = "dbo.Auto_Feed_Schedule"
    
    If (InStrB(strTimeToRun, ",") = 0) Then
      .Parameters.Append .CreateParameter("@RunTime", adVarChar, adParamInput, 8, strTimeToRun)
    Else
      .Parameters.Append .CreateParameter("@RunTime", adVarChar, adParamInput, 8, Split(strTimeToRun, ",")(0))
      .Parameters.Append .CreateParameter("@DayOfMonth", adInteger, adParamInput, , Split(strTimeToRun, ",")(1))
      .Parameters.Append .CreateParameter("@DayOfWeek", adVarChar, adParamInput, 9, Split(strTimeToRun, ",")(2))
      .Parameters.Append .CreateParameter("@LastDayOfMONTH", adInteger, adParamInput, , Split(strTimeToRun, ",")(3))
    End If
    
    'tstRec.CursorLocation = adUseClient
    Set tstRec = .Execute()
    
    Set tstRec.ActiveConnection = Nothing
  End With

  Set GetSchedule = tstRec

  If tstConn.State = 1 Then tstConn.Close
  Set tstConn = Nothing
  
  Set tstComm = Nothing
End Function

Public Function GetScheduleByMediaID(ByVal strMediaID As String) As ADODB.Recordset
  Dim tstConn As ADODB.Connection
  Dim tstComm As ADODB.Command
  Dim tstRec As ADODB.Recordset
  
  Set tstConn = New ADODB.Connection
  Set tstComm = New ADODB.Command
  Set tstRec = New ADODB.Recordset
  
  With tstConn
    .CursorLocation = adUseClient
    .ConnectionString = "File Name=" & UDL_PATH & "autofeeds.udl"
    .Open
  End With
  
  With tstComm
    .ActiveConnection = tstConn
    .CommandType = adCmdStoredProc
    .CommandText = "dbo.Auto_Feed_Interface_Get_Schedule_By_MediaID"
    
    .Parameters.Append .CreateParameter("@EmediaID", adVarChar, adParamInput, 8, strMediaID)
    
    'tstRec.CursorLocation = adUseClient
    Set tstRec = .Execute()
    
    Set tstRec.ActiveConnection = Nothing
  End With

  Set GetScheduleByMediaID = tstRec

  If tstConn.State = 1 Then tstConn.Close
  Set tstConn = Nothing
  
  Set tstComm = Nothing
End Function
Public Function GetScheduleErrorState() As ADODB.Recordset
  Dim tstConn As ADODB.Connection
  Dim tstComm As ADODB.Command
  Dim tstRec As ADODB.Recordset
  
  Set tstConn = New ADODB.Connection
  Set tstComm = New ADODB.Command
  Set tstRec = New ADODB.Recordset
  
  With tstConn
    .CursorLocation = adUseClient
    .ConnectionString = "File Name=" & UDL_PATH & "autofeeds.udl"
    .Open
  End With
  
  With tstComm
    .ActiveConnection = tstConn
    .CommandType = adCmdStoredProc
    .CommandText = "dbo.Auto_Feed_Schedule_Get_Schedule_Error_State"
    
    'tstRec.CursorLocation = adUseClient
    Set tstRec = .Execute()
    
    Set tstRec.ActiveConnection = Nothing
  End With

  Set GetScheduleErrorState = tstRec

  If tstConn.State = 1 Then tstConn.Close
  Set tstConn = Nothing
  
  Set tstComm = Nothing
End Function

Public Property Let UsesSlotQty(ByVal p_blnUsesSlotQty As Boolean)
10        blnUsesSlotQty = p_blnUsesSlotQty
End Property
Public Property Get UsesSlotQty() As Boolean
10        UsesSlotQty = blnUsesSlotQty
End Property

Public Property Let LogEvent(ByVal blnLog As Boolean)
10      blnLogEvent = blnLog
End Property

Public Property Let AutoFeedID(ByVal intFeedID As Integer)
10      intAutoFeedID = intFeedID
End Property

Public Property Let UsesPartialHTMLStrip(ByVal blnPartialHStrip As Boolean)
10      blnPartialHTMLStrip = blnPartialHStrip
End Property

Public Property Let OkToStripHTML(ByVal blnHStrip As Boolean)
10      blnHTMLStrip = blnHStrip
End Property

Public Property Let OkToConvertToHTML(ByVal blnHConvert As Boolean)
10      blnConvAreaToHTML = blnHConvert
End Property


Public Property Let OkToEncodeHTML(ByVal blnHEncode As Boolean)
10      blnHTMLEncode = blnHEncode
End Property

Public Property Let Machine(ByVal strMachineSource As String)
10      strMachine = strMachineSource
End Property

Public Property Get Machine() As String
10      Machine = strMachine
End Property

Public Property Let UseSubID(ByVal blnUsesSubID As Boolean)
10      blnUseSubID = blnUsesSubID
End Property

Private Function GetSeparateJobDescription(ByVal Rs As ADODB.Recordset, ByVal strEmediaID As String, ByVal strProcName As String) As Boolean
10      On Error GoTo GetSeparateJobDescriptionErr
        Dim strGetField As String
        
20      strGetField = Rs.Fields("header").Value
        
        'No error, there is no need to get the job description separately
30      GetSeparateJobDescription = False
        
40      If (blnGetDescription = True) Then
50        Call EmailMessage(strFromEmail, "crey@hodesiq.com", "Emedia set to get description", "", "", "Emedia id " & strEmediaID & " is set to get the job description separately but the stored procedure " & strProcName & " is returning the job description.", "")
60      End If
        
70      Exit Function
        
GetSeparateJobDescriptionErr:
        'There was an error, we need to get the job description separately
80      If (Err.Number = 3265) Then
90        GetSeparateJobDescription = True
        
100       If (blnGetDescription = False) Then
110         Call EmailMessage(strFromEmail, "crey@hodesiq.com", "Emedia NOT set to get description", "", "", "Emedia id " & strEmediaID & " is not set to get the job description separately but the stored procedure " & strProcName & " is not returning the job description.", "")
120       End If
130     Else
140       Err.Raise Err.Number, "Auto_Feed_Data|clsGetDbData|GetSeparateJobDescription", Err.Description
150     End If
End Function

Private Function TestForXML(ByVal StringToCheck As String) As Boolean
10      On Error GoTo TestForXMLErr
        
        Dim xmlDoc As MSXML2.DOMDocument60
        Dim xmlRoot As IXMLDOMElement
        
20      Set xmlDoc = New MSXML2.DOMDocument60
        
        'Check XML here.
30      Set xmlRoot = xmlDoc.createElement("Testing")
40      xmlRoot.Text = StringToCheck
50      xmlDoc.appendChild xmlRoot
        
60      Set xmlDoc = Nothing
70      Set xmlRoot = Nothing
        'If no error return true
80      TestForXML = True
        
90      Exit Function
TestForXMLErr:
100     Set xmlDoc = Nothing
110     Set xmlRoot = Nothing
        
120     If Err.Number = -2147467259 Then
130       TestForXML = False
140     Else
150       Err.Raise Err.Number, Err.Source, Err.Description
160     End If
End Function

Public Property Let UsesSlotQtyDelete(ByVal p_blnUsesSlotQtyDelete As Boolean)
10        blnUsesSlotQtyDelete = p_blnUsesSlotQtyDelete
End Property

Public Property Let QtyAllowed(ByVal p_intQtyAllowed As Integer)
10        intQtyAllowed = p_intQtyAllowed
End Property

'Private RsHistory As ADODB.Recordset

'Private clsErrCatcher As clsCatchErrors

'This sub is a sub set of its cousin BuildJoinedRecordset, it doesn't use an autofeed id and it was written
'separately to avoid any confusion with the disconnected recordsets being used since the other one is already
'in use in production.
Private Sub BuildJoinedRecordsetMultiSource(ByVal AdoRsSource As ADODB.Recordset, ByVal strUDLName As String, ByVal intParamUsedType As Integer, ByVal blnGetSeparateDescription As Boolean, ByVal strParamUsed As String, ByVal strEmediaID As String, ByVal strParams As String)
        Dim lngLogID As Long
        Dim strLogInformation As String
        Dim intHiringOrgID As Integer
        Dim bytCountExcludedHorgs As Byte

'10      If blnLogEvent Then
'20        strLogInformation = LogAnEvent(App.EXEName & "|clsGetDbData|BuildJoinedRecordsetMultiSource", "N/A", 1, strMachine, strParamUsed, strEmediaID, strParams, intAutoFeedID, 0, 0, intParamUsedType, Guids.strGuidGetJobs)
'30        lngLogID = CLng(Split(strLogInformation, "|")(0))
'40      End If

        Dim intCntr As Integer
        Dim strCollectItems As String
        Dim strItemName As String
        Dim arrCollectItems() As String
        Dim intArrCntr As Integer
        Dim intArrUbound As Integer
        Dim lngKeepReqID As Long
        Dim intOriginalCnt As Integer
        Dim lngFieldSize As Long
        
        Dim RsGetJobDescription As ADODB.Recordset
        Dim blnGotDescription As Boolean
        Dim blnGotContactInfo As Boolean
        
        Dim strContactAddress1 As String
        Dim strContactAddress2 As String
        Dim strContactCity As String
        Dim strContactState As String
        Dim strContactZip As String
        Dim blnGotSeparateDescription As Boolean
        Dim blnIsScraped As Boolean
        Dim bytDeleteQCode As Byte
        'Dim intMediaMode As Integer
        
        Const PROCEDURE = "BuildJoinedRecordsetMultiSource"
        
        bytDeleteQCode = 0
        
              'On Error GoTo errorhandler

50      If (rsMultiSource Is Nothing) Then Set rsMultiSource = New ADODB.Recordset
        
60      If (rsMultiSource.Fields.Count = 0) Then
70        rsMultiSource.CursorLocation = adUseClient
          
80        ReDim arrCollectItems(0)
          
90        arrCollectItems(0) = ""
          
100       For intCntr = 0 To (AdoRsSource.Fields.Count - 1)
110         strItemName = UCase(AdoRsSource.Fields.Item(intCntr).Name)
            
      '80          intArrUbound = UBound(arrCollectItems)
            
            'Repeating item, if a select statement calls the same field twice, then that field will not be appended the second time,
            'it will error out because that item already exists in the collection of fields, in that case we append the counter to the field name the second time so that it becomes an unique field name and it doesn't error out.
120         If (arrCollectItems(0) <> "") Then
130           For intArrCntr = 0 To UBound(arrCollectItems)
140             If (arrCollectItems(intArrCntr) = strItemName) Then
150               strItemName = strItemName & "_" & CStr(intCntr)
160             End If
170           Next intArrCntr
180         End If
            
190         If ((blnConvAreaToHTML = True) Or (blnEncode = True) Or (blnHTMLEncode = True)) Then
200           Select Case True
                Case strItemName = "HEADER", strItemName = "FOOTER", strItemName = "DUTIES", strItemName = "REQUIREMENTS", strItemName = "TITLE", strItemName = "REQUISITION_CODE", strItemName = "CITY_NAME", strItemName = "STATE_NAME", strItemName = "LISTING", strItemName = "PROJECT_PROFILE_CITY", strItemName = "PROJECT_PROFILE_STATE", strItemName = "ADDRESS1", strItemName = "ADDRESS2"
210               lngFieldSize = AdoRsSource.Fields.Item(intCntr).DefinedSize + (AdoRsSource.Fields.Item(intCntr).DefinedSize * 0.5)
220             Case Else
230               lngFieldSize = AdoRsSource.Fields.Item(intCntr).DefinedSize
240           End Select
250         Else
260           lngFieldSize = AdoRsSource.Fields.Item(intCntr).DefinedSize
270         End If
            
280         rsMultiSource.Fields.Append strItemName, AdoRsSource.Fields.Item(intCntr).Type, lngFieldSize, adFldIsNullable + adFldUpdatable

290         strCollectItems = strCollectItems & strItemName & ","
            
300         ReDim arrCollectItems(0 To intCntr)
            
310         arrCollectItems = Split(strCollectItems, ",")
320       Next intCntr

330       If (intParamUsedType = 5) Then
340         If (blnGetSeparateDescription = True) Then
350           rsMultiSource.Fields.Append "header", adLongVarWChar, -1, adFldIsNullable + adFldUpdatable
360           rsMultiSource.Fields.Append "footer", adLongVarWChar, -1, adFldIsNullable + adFldUpdatable
370           rsMultiSource.Fields.Append "duties", adLongVarWChar, -1, adFldIsNullable + adFldUpdatable
380           rsMultiSource.Fields.Append "requirements", adLongVarWChar, -1, adFldIsNullable + adFldUpdatable
390         End If
            
400         rsMultiSource.Fields.Append "DynContactAdd1", adVarChar, 150, adFldIsNullable + adFldUpdatable
410         rsMultiSource.Fields.Append "DynContactAdd2", adVarChar, 150, adFldIsNullable + adFldUpdatable
420         rsMultiSource.Fields.Append "DynContactCity", adVarChar, 100, adFldIsNullable + adFldUpdatable
430         rsMultiSource.Fields.Append "DynContactState", adVarChar, 100, adFldIsNullable + adFldUpdatable
440         rsMultiSource.Fields.Append "DynContactZip", adVarChar, 10, adFldIsNullable + adFldUpdatable
441         rsMultiSource.Fields.Append "DynDeleteJob", adTinyInt, , adFldIsNullable + adFldUpdatable
450       End If

        'Kevin adding this for History table
460     rsMultiSource.Fields.Append "UDLFILE", 200, 100, adFldIsNullable + adFldUpdatable
         
470     End If
        
        
        
480     If rsMultiSource.State = 0 Then rsMultiSource.Open
        
490     intOriginalCnt = (AdoRsSource.Fields.Count)
        
500     If (intParamUsedType = 5) Then ' And (blnGetSesparateDescription = True)) Then
510       intArrUbound = rsMultiSource.Fields.Count - 2 '((AdoRsSource.Fields.Count) + 3)
520     Else
530       intArrUbound = (AdoRsSource.Fields.Count - 1)
540     End If
        
550     Do While Not AdoRsSource.EOF
560       lngKeepReqID = 0

570       rsMultiSource.AddNew
          
580       If (intParamUsedType = 5) Then ' And (blnGetSeparateDescription = True)) Then
590         For intCntr = 0 To intArrUbound
600           If (UCase(rsMultiSource.Fields(intCntr).Name) = "REQUISITION_ID") Then
610             lngKeepReqID = AdoRsSource.Fields("requisition_id").Value

620             Exit For
630           End If
640         Next intCntr
650       End If

660       If ((intParamUsedType = 5) And (lngKeepReqID = 0)) Then
670         Call EmailMessage(strFromEmail, "crey@hodesiq.com;jcamacho@hodesiq.com", "Stored procedure does not have a requisition id", "", "", "Stored procedure doesn't have requisition id" & vbCrLf & vbCrLf & "EmediaID: " & strOrderEmediaID, "")
680       End If
          
690       blnGotDescription = False
700       blnGotContactInfo = False
          
710       strContactAddress1 = vbNullString
720       strContactAddress2 = vbNullString
730       strContactCity = vbNullString
740       strContactState = vbNullString
750       strContactZip = vbNullString
760       blnGotSeparateDescription = False
          
761       blnIsScraped = False
'          intMediaMode = 14 '14 means the proc hasn't have the media mode set
770       For intCntr = 0 To intArrUbound ' (AdoRsSource.Fields.Count - 1)
780         If (intOriginalCnt > intCntr) Then
790           rsMultiSource.Fields(intCntr).Value = GetDynamicRsFieldValue((AdoRsSource.Fields(intCntr).Value & ""), AdoRsSource.Fields(intCntr).Type, AdoRsSource.Fields(intCntr).Name, intParamUsedType, 0, strEmediaID, strUDLName, strParamUsed, strParams, "BuildJoinedRecordsetMultiSource", False)

'800           If (AdoRsSource.Fields(intCntr).Name = "MediaMode") Then
               ' Ticket Number #140760 strEmediaID
                ' Update tbl_auto_feed_emedia by emedia id.
                ' Need to make sure that we can use the emedia id here.
                ' ExecStoredProc_SetRs gets media id passed to it when the proc type is new. I think the best solution is to finish converting the procs to use the new version (1), in the mean time we can update the media table when strEmediaID<>""
                
                'Commenting out for now, I need to test this.
                'intMediaMode = AdoRsSource.Fields(intCntr).Value
                'If strEmediaID <> "" Then
                '  Call UpdateEmediaMediaMode(strEmediaID, intMediaMode)
                'End If
'810           End If
820         End If

830         If ((intOriginalCnt <= intCntr) And (intParamUsedType = 5)) Then
840           If (blnGotContactInfo = False) Then
850             If (lngKeepReqID > 0) Then
860               Call GetContactInfo(lngKeepReqID, strContactAddress1, strContactAddress2, strContactCity, strContactState, strContactZip)
870             Else
880               If (blnGotContactInfo = False) Then
890                 Call EmailMessage(strFromEmail, "crey@hodesiq.com;jcamacho@hodesiq.com", "Feed is not getting the requisition id value.", "", "", "Source: " & "Auto_Feed_Data|clsGetDbData|" & PROCEDURE & vbNewLine & "MediaID: " & strEmediaID & vbNewLine & "FeedID: " & intAutoFeedID, "")
900               End If
910             End If
                
920             blnGotContactInfo = True
930           End If
              
940           If (blnGotContactInfo = True) Then
950             Select Case True
                  Case (rsMultiSource.Fields(intCntr).Name = "DynContactAdd1")
960                 rsMultiSource.Fields(intCntr).Value = strContactAddress1
                    
970                 blnGotSeparateDescription = True
980               Case (rsMultiSource.Fields(intCntr).Name = "DynContactAdd2")
990                 rsMultiSource.Fields(intCntr).Value = strContactAddress2
1000              Case (rsMultiSource.Fields(intCntr).Name = "DynContactCity")
1010                rsMultiSource.Fields(intCntr).Value = strContactCity
1020              Case (rsMultiSource.Fields(intCntr).Name = "DynContactState")
1030                rsMultiSource.Fields(intCntr).Value = strContactState
1040              Case (rsMultiSource.Fields(intCntr).Name = "DynContactZip")
1050                rsMultiSource.Fields(intCntr).Value = strContactZip
1051              Case (rsMultiSource.Fields(intCntr).Name = "DynDeleteJob")
                    If (LenB(strListOfExcludedQCodes) > 0) Then
1052                  If (InStrB(1, strListOfExcludedQCodes, "," & lngKeepReqID & ",") > 0) Then
1053                    rsMultiSource.Fields(intCntr).Value = 1
  
1054                    bytDeleteQCode = 1
'1055                  Else
'1056                    rsMultiSource.Fields(intCntr).Value = 0
1057                  End If
                    End If
1060            End Select
1070          End If

1080          If ((blnGetSeparateDescription = True) And (blnGotSeparateDescription = False)) Then
1090            If blnGotDescription = False Then
1100              Set RsGetJobDescription = GetDescriptionRS(lngKeepReqID, strUDLName)
1110              blnGotDescription = True
1111              blnIsScraped = RsGetJobDescription.Fields("IsScraped").Value
1112              intHiringOrgID = RsGetJobDescription.Fields("Hiring_OrgID").Value

                  If (UBound(strSplitExcludedHorgs) > -1) Then
1113                For bytCountExcludedHorgs = 0 To (UBound(strSplitExcludedHorgs))
1114                  If (CInt(strSplitExcludedHorgs(bytCountExcludedHorgs)) = intHiringOrgID) Then
1115                    Call EmailMessage(strFromEmail, "crey@hodesiq.com;jcamacho@hodesiq.com", "INVALID HIRING ORG ID FOUND: " & intHiringOrgID, vbNullString, vbNullString, "Requisition ID " & lngKeepReqID & " has been pulled for a prohibited hiring org id " & intHiringOrgID, vbNullString)
1116                    Err.Raise SetExcludedHorgErr, "Auto_Feed_Data|clsGetDbData|BuildJoinedRecordsetMultiSource", "Requisition ID " & lngKeepReqID & " has been pulled for a prohibited hiring org id " & intHiringOrgID & vbNewLine & "AutofeedID: " & intAutoFeedID & vbNewLine & "Machine: " & Me.Machine & vbNullString & "SubID: " & lngSubID & vbNewLine & "UseSubID: " & blnUseSubID
1117                  End If
1118                Next bytCountExcludedHorgs
1119              End If
1120            End If
                
1130            Select Case True
                  Case (LCase(rsMultiSource.Fields(intCntr).Name) = "header")
1140                rsMultiSource.Fields(intCntr).Value = GetDynamicRsFieldValue(RsGetJobDescription.Fields("header").Value, RsGetJobDescription.Fields("header").Type, "HEADER", intParamUsedType, lngKeepReqID, strEmediaID, strUDLName, strParamUsed, strParams, "BuildJoinedRecordsetMultiSource", blnIsScraped)
1150              Case (LCase(rsMultiSource.Fields(intCntr).Name) = "footer")
1160                rsMultiSource.Fields(intCntr).Value = GetDynamicRsFieldValue(RsGetJobDescription.Fields("footer").Value, RsGetJobDescription.Fields("footer").Type, "FOOTER", intParamUsedType, lngKeepReqID, strEmediaID, strUDLName, strParamUsed, strParams, "BuildJoinedRecordsetMultiSource", blnIsScraped)
1170              Case (LCase(rsMultiSource.Fields(intCntr).Name) = "duties")
1180                rsMultiSource.Fields(intCntr).Value = GetDynamicRsFieldValue(RsGetJobDescription.Fields("duties").Value, RsGetJobDescription.Fields("duties").Type, "DUTIES", intParamUsedType, lngKeepReqID, strEmediaID, strUDLName, strParamUsed, strParams, "BuildJoinedRecordsetMultiSource", blnIsScraped)
1190              Case (LCase(rsMultiSource.Fields(intCntr).Name) = "requirements")
1200                rsMultiSource.Fields(intCntr).Value = GetDynamicRsFieldValue(RsGetJobDescription.Fields("requirements").Value, RsGetJobDescription.Fields("requirements").Type, "REQUIREMENTS", intParamUsedType, lngKeepReqID, strEmediaID, strUDLName, strParamUsed, strParams, "BuildJoinedRecordsetMultiSource", blnIsScraped)
1210              Case Else
                    'Email here
1220                Call EmailMessage(strFromEmail, "crey@hodesiq.com;jcamacho@hodesiq.com", "No description found", "", "", "No job description found for job " & CStr(lngKeepReqID), "")
1230            End Select
1240          End If
1250        End If
1260      Next intCntr
              
          'If (strEmediaID <> "" And intMediaMode = 14) Then
          '  Call UpdateEmediaMediaMode(strEmediaID, intMediaMode)
          'End If

1270      rsMultiSource.Fields(intCntr).Value = strUDLName
          
1280      AdoRsSource.MoveNext
1290    Loop
        
        If (bytDeleteQCode = 1) Then
          rsMultiSource.Filter = "DynDeleteJob=1"
          
          Do While rsMultiSource.RecordCount > 0
            rsMultiSource.Filter = "DynDeleteJob=1"
            rsMultiSource.Delete
          Loop
          
          rsMultiSource.Filter = vbNullString
        End If
        
1300    If (rsMultiSource.RecordCount > 0) Then rsMultiSource.Update

1310    If AdoRsSource.State = 1 Then AdoRsSource.Close
1320    Set AdoRsSource = Nothing
1330    Set RsGetJobDescription = Nothing
        
'1340    If blnLogEvent Then Call UpdateAnEvent(lngLogID, intParamUsedType)
'              Exit Sub
'errorhandler:
'              Debug.Print Err.Description
End Sub

'Commenting for now, I need to go through this code first.
'Private Sub UpdateEmediaMediaMode(ByVal strEmediaID As String, ByVal intMediaMode As Integer)
'        Dim bytRecsAffected As Byte
'        Dim ADOCM As ADODB.Command
'        Dim strErrMessage As String
'        Dim strMethod As String
'        Dim clsReportErrs As Auto_Feed_Errors.clsAuto_Feed_Errors
        
'10      strMethod = "UpdateEmediaMediaMode"
        
'20      Set ADOCM = New ADODB.Command
        
'30      Call SetConnection(MASTER_SOURCE)
        
'40      With ADOCM
'50        Set .ActiveConnection = adocn
'60        .CommandType = adCmdStoredProc
'70        .CommandText = "Auto_Feed_component_Update_Emedia_ModeType"

'80        .Parameters.Append .CreateParameter("@EmediaID", adVarChar, adParamInput, 5, strEmediaID)
'90        .Parameters.Append .CreateParameter("@ModeType", adInteger, adParamInput, 4, intMediaMode)
'100
'130       .Execute
'140     End With
        
'150     Call UnsetConnection
          
'160
'170     Set ADOCM = Nothing
'End Sub

Private Function CheckUDL(ByVal strUDLFile As String) As Boolean
10      If (Dir(strUDLFile) = "") Then
20        CheckUDL = False
        
          'The udl file doesn't exist, this is a problem.
30        EmailMessage strFromEmail, "crey@hodesiq.com;jcamacho@hodesiq.com", "Connection error", "", "", "Udl file not found " & strUDLFile, ""
40      Else
50        CheckUDL = True
60      End If
End Function

Private Function GetDynamicRsFieldValue(ByVal strGetFieldValue As String, ByVal intFieldType As Integer, ByVal strFieldName As String, ByVal intParamType As Integer, ByVal lngRequisitionID As Long, ByVal strEmediaID As String, ByVal strUDLName As String, ByVal strParamUsed As String, ByVal strParams As String, ByVal strCaller As String, ByVal blnIsScraped As Boolean) As String
            'If blnHTMLStrip is True then blnHTMLEncode and blnConvAreaToHTML should be False
            'If blnHTMLEncode is True then blnHTMLStrip should be false and blnConvAreaToHTML could be true
            'If blnConvAreaToHTML is True then blnHTMLStrip should be false blnHTMLEncode could be true
            Dim blnEncodeField As Boolean
            
            'On Error GoTo GetDynRsValueError

10          blnEncodeField = ((blnISXML = True) Or (blnEncode = True))
20          strFieldName = UCase(strFieldName)
            
            'If the value in the field is null then see what default value we can use.
            'Use our commonly utilized data types.
30          If (LenB(strGetFieldValue) = 0) Then
40            Select Case intFieldType
                Case adChar, adVarChar, adLongVarChar, adLongVarWChar
50                strGetFieldValue = vbNullString
60              Case adDate, adDBDate
70                strGetFieldValue = Format(CStr(Date), "mm/dd/yyyy")
80              Case adDBTime
90                strGetFieldValue = Format(CStr(Time), "hh:mm:ss")
100             Case adNumeric, adTinyInt, adDouble, adSingle, adInteger, adSmallInt, adUnsignedInt, adUnsignedBigInt, adUnsignedSmallInt, adUnsignedTinyInt, adBoolean
110               strGetFieldValue = "0"
120             Case Else
130               strGetFieldValue = vbNullString
140           End Select
150         Else ' LenB(strGetFieldValue) = 0
160           If (intParamType = 5) Then ' When intParamType is 5 then the proc pulls the actual jobs.
240             If ((Not (IsNumeric(strGetFieldValue))) And ((intFieldType = adChar) Or (intFieldType = adVarChar) Or (intFieldType = adLongVarChar) Or (intFieldType = adLongVarWChar) Or (intFieldType = adVarWChar))) Then
250               Select Case True
                    Case strFieldName = "HEADER", strFieldName = "FOOTER", strFieldName = "DUTIES", strFieldName = "REQUIREMENTS", strFieldName = "TITLE", strFieldName = "REQUISITION_CODE", strFieldName = "CITY_NAME", strFieldName = "STATE_NAME", strFieldName = "LISTING", strFieldName = "PROJECT_PROFILE_CITY", strFieldName = "PROJECT_PROFILE_STATE", strFieldName = "ADDRESS1", strFieldName = "ADDRESS2"
260                   If (blnEncodeField = True) Then
270                     strGetFieldValue = ScanDescription(strGetFieldValue)
280                   End If
290               End Select
                
300               If (blnHTMLStrip = True) Then
310                 Select Case True
                      Case strFieldName = "LISTING", strFieldName = "TITLE", strFieldName = "HEADER", strFieldName = "FOOTER", strFieldName = "REQUIREMENTS", strFieldName = "DUTIES"
320                     If ((strFieldName = "HEADER") Or (strFieldName = "FOOTER") Or (strFieldName = "REQUIREMENTS") Or (strFieldName = "DUTIES")) Then
330                       If (blnPartialHTMLStrip = True) Then
340                         strGetFieldValue = StripOffEndingBrake(strGetFieldValue)
350                       End If
360                     End If
                        
370                     If ((strFieldName = "HEADER") Or (strFieldName = "FOOTER") Or (strFieldName = "REQUIREMENTS") Or (strFieldName = "DUTIES")) Then
                          'If ((InStrB(strGetFieldValue, Chr(60)) = 0) Or (InStrB(strGetFieldValue, Chr(62)) = 0)) Then
380                         If (blnPartialHTMLStrip = True) Then
390                           If (strNoConvMediaID = "N") Then strGetFieldValue = ConvertTextAreaToHTML(strGetFieldValue)
400                         End If
                          'End If
410                     End If
420                 End Select
                  
430                 If ((InStrB(strGetFieldValue, Chr(60)) > 0) And (InStrB(strGetFieldValue, Chr(62)) > 0)) Then
440                   Select Case True
                        Case strFieldName = "TITLE", strFieldName = "HEADER", strFieldName = "FOOTER", strFieldName = "REQUIREMENTS", strFieldName = "DUTIES"
450                       strGetFieldValue = StripHTML(strGetFieldValue, lngRequisitionID, strFieldName, strEmediaID, strUDLName, strParamUsed, strParams, intParamType, strCaller)
460                   End Select
470                 End If
                    
530               Else  ' blnHTMLStrip = True
540                 Select Case True
                      Case strFieldName = "HEADER", strFieldName = "FOOTER", strFieldName = "REQUIREMENTS", strFieldName = "DUTIES"
550                     If (blnConvAreaToHTML = True) Then
560                       strGetFieldValue = ConvertTextAreaToHTML(strGetFieldValue)
570                     End If
630                 End Select
640               End If ' If (blnHTMLStrip = True)
650             End If ' Not (IsNumeric(strGetFieldValue ...

170             If (blnIsScraped = True) Then
180               Select Case True
                    Case strFieldName = "HEADER", strFieldName = "FOOTER", strFieldName = "DUTIES", strFieldName = "REQUIREMENTS", strFieldName = "TITLE"
190                   If ((InStrB(strGetFieldValue, Chr(60)) > 0) And (InStrB(strGetFieldValue, Chr(62)) > 0)) Then
200                     Call AdjustJobFormat(strGetFieldValue, "</BR>", 5)
201                     Call AdjustJobFormat(strGetFieldValue, "<BR>", 4)
210                   End If
220               End Select
230             End If

480             If ((strFieldName = "LISTING") Or (strFieldName = "TITLE") Or (strFieldName = "HEADER") Or (strFieldName = "FOOTER") Or (strFieldName = "REQUIREMENTS") Or (strFieldName = "DUTIES")) Then
490               If (blnHTMLEncode = True) Then
                    If ((InStrB(strGetFieldValue, Chr(60)) > 0) And (InStrB(strGetFieldValue, Chr(62)) > 0)) Then
500                   strGetFieldValue = HTMLEncode(strGetFieldValue)
                    End If
510               End If
520             End If
660           End If ' intParamType = 5
670         End If ' LenB(strGetFieldValue) = 0

680         GetDynamicRsFieldValue = strGetFieldValue
            
      'Exit Function
      'GetDynRsValueError:
      '            Debug.Print Err.Description
End Function
  'When calling html encode, there is the option to take out illigal characters as well
  Private Function HTMLEncode(ByVal StringToModify As String) As String
10        StringToModify = RegExpReplace("&", "&amp;", True, True, StringToModify)
20        StringToModify = RegExpReplace("<", "&lt;", True, True, StringToModify)
30        StringToModify = RegExpReplace(">", "&gt;", True, True, StringToModify)
40        StringToModify = RegExpReplace("""", "&quot;", True, True, StringToModify)
        
50        HTMLEncode = StringToModify
      '        StringToModify = Replace(StringToModify, "&", "&amp;")
      '48860   StringToModify = Replace(StringToModify, "<", "&lt;")
      '48870   StringToModify = Replace(StringToModify, ">", "&gt;")
      '48690   StringToModify = Replace(StringToModify, """", "&quot;")
      '48700   StringToModify = Replace(StringToModify, "”", "&quot;")
      '48710   StringToModify = Replace(StringToModify, "“", "&quot;")
  End Function

  Private Function ConvertTextAreaToHTML(ByVal strTextArea As String) As String ', ByVal strHTML As String) As String
                  Dim strConverted As String
                  
10                strConverted = RegExpReplace("\r\n", " <BR>", True, True, strTextArea)
20                strConverted = RegExpReplace("\r", " <BR>", True, True, strConverted)
30                strConverted = RegExpReplace("\n", " <BR>", True, True, strConverted)
40                strConverted = RegExpReplace("\t", Chr(32) & Chr(32) & Chr(32) & Chr(32), True, True, strConverted)
50                strConverted = RegExpReplace("\v", "", True, True, strConverted)
      '48170       strConverted = RegExpReplace("[\f\n\r\t\v]", "", True, True, strConverted)

60                ConvertTextAreaToHTML = strConverted
      '48170       ConvertTextAreaToHTML = RegExpReplace("[\f\n\r\t\v]", "", True, True, RegExpReplace("\n", " <BR>", True, True, RegExpReplace("\r\n", " <BR>", True, True, strTextArea)))
  End Function
  Private Function RegExpReplace(strPattern, strReplaceWith, blnGlobal, blnIgnoreCase, strSource) As String
          Dim objRegExp As RegExp

          'create the Regular Expression object
10        Set objRegExp = New RegExp

20        With objRegExp
            'ignore the case
30          .IgnoreCase = blnIgnoreCase
            
            'global replace
40          .Global = blnGlobal

            'set the pattern to search for
50          .Pattern = strPattern
            
            'replace the pattern with the new string
60          RegExpReplace = .Replace(strSource, strReplaceWith)
70        End With

          'clean up
80        If Not objRegExp Is Nothing Then
90            Set objRegExp = Nothing
100       End If
  End Function
Public Function GetJoinedRecords(ByVal ADORS_JOINED As ADODB.Recordset, ByVal bytOrder As Byte) As Scripting.Dictionary
        Dim strKeepFileName As String
        Dim strKeepUserName As String
        Dim strKeepPwd As String
        Dim intKeepFeedID As Integer
        Dim blnJoin As Boolean
        Dim blnEvalVals As Boolean
        Dim dicJoin As Scripting.Dictionary
        Dim intCntRecord As Integer
        
10      Set dicJoin = New Scripting.Dictionary
        
        'Do While Not ADORS_JOINED.EOF
20      For intCntRecord = 0 To ADORS_JOINED.RecordCount
30        If ADORS_JOINED.EOF Then Exit For
          
31        If (blnNewOrdering = True) Then
32          blnJoin = (intKeepFeedID <> ADORS_JOINED.Fields("AutoFeedID").Value)
33        Else
40          If bytOrder = BY_FILENAME Then
50            blnJoin = (strKeepFileName <> ADORS_JOINED.Fields("FileName").Value)
60          Else
70            blnJoin = ((strKeepUserName <> ADORS_JOINED.Fields("UserName").Value) Or (strKeepPwd <> ADORS_JOINED.Fields("Pwd").Value))
80          End If
81        End If

90        If intCntRecord > 0 Then
100         dicJoin.Add CStr(intCntRecord) & "_" & CStr(intKeepFeedID), Not (blnJoin)
110       End If
        
111       If (blnNewOrdering = False) Then
120         strKeepFileName = ADORS_JOINED.Fields("FileName").Value
130         strKeepUserName = ADORS_JOINED.Fields("UserName").Value
140         strKeepPwd = ADORS_JOINED.Fields("Pwd").Value
141       End If
          
150       intKeepFeedID = ADORS_JOINED.Fields("AutoFeedID").Value
          
          'intCntRecord = intCntRecord + 1

160       ADORS_JOINED.MoveNext
170     Next intCntRecord
        'Loop
        
180     If ADORS_JOINED.RecordCount > 0 Then ADORS_JOINED.MoveFirst

190     Set GetJoinedRecords = dicJoin
        
200     Set dicJoin = Nothing
210     Set ADORS_JOINED = Nothing
End Function

'This function will create a disconnected recordset to fill it up with data to later have it all sorted by a criteria.
Public Sub BuildJoinedRecordSet(ByVal AdoRsSource As ADODB.Recordset, ByVal intFeedID As Integer, Optional ByVal blnSlotQty As Boolean = False, Optional ByVal blnForDeletes As Boolean = False) 'As ADODB.Recordset
        Dim intCntr As Integer
        Dim intCntr2 As Integer
        Dim lngGetJobs As Long
        
10      If (blnForDeletes = True) Then
20        lngGetJobs = AdoRsSource.RecordCount
30      Else
          'Filter out deletes.
40        If (blnSlotQty = True) Then AdoRsSource.Filter = "JobAction<>'D'"
        
50        If (intQtyAllowed = 0) Then
60          lngGetJobs = AdoRsSource.RecordCount
70        Else
80          If (intQtyAllowed > AdoRsSource.RecordCount) Then
90            lngGetJobs = AdoRsSource.RecordCount
100         Else
110           lngGetJobs = intQtyAllowed
120         End If
130       End If
          
140       If (ADORSJN Is Nothing) Then Set ADORSJN = New ADODB.Recordset
        
        
150       If (ADORSJN.Fields.Count = 0) Then
160         ADORSJN.CursorLocation = adUseClient
            
170         For intCntr = 0 To (AdoRsSource.Fields.Count - 1)
180           ADORSJN.Fields.Append AdoRsSource.Fields.Item(intCntr).Name, AdoRsSource.Fields.Item(intCntr).Type, AdoRsSource.Fields.Item(intCntr).DefinedSize, adFldIsNullable + adFldUpdatable
190         Next intCntr
            
            'Now let's add the feed id.
200         If (intQtyAllowed = 0) Then ADORSJN.Fields.Append "Auto_Feed_ID", adInteger, 5, adFldIsNullable + adFldUpdatable       ', intFeedID
210       End If
220     End If ' If (blnForDeletes = True) Then
        
230     If ADORSJN.State = 0 Then ADORSJN.Open
        
240     For intCntr2 = 0 To lngGetJobs - 1
        'Do While Not AdoRsSource.EOF
250       ADORSJN.AddNew
          
260       For intCntr = 0 To (AdoRsSource.Fields.Count - 1)
270         ADORSJN.Fields(intCntr).Value = GetDynamicRsFieldValue((AdoRsSource.Fields(intCntr).Value & ""), AdoRsSource.Fields(intCntr).Type, AdoRsSource.Fields(intCntr).Name, 0, 0, vbNullString, vbNullString, vbNullString, vbNullString, "BuildJoinedRecordSet", False) ' strFieldValue = (AdoRsSource.Fields(intCntr).Value & "")
            
      '460         ADORSJN.Fields(intCntr).Value = strFieldValue
280       Next intCntr
          
290       If (intQtyAllowed = 0) Then ADORSJN.Fields(ADORSJN.Fields.Count - 1).Value = intFeedID

300       AdoRsSource.MoveNext
        'Loop
310     Next intCntr2
        
320     If Not (ADORSJN.EOF) Then ADORSJN.Update

330     If ((blnForDeletes = False) And (blnSlotQty = True)) Then
          ' Change filter.
340       AdoRsSource.Filter = "((JobAction<>'A') And (JobAction<>'U'))"
          
350       If (AdoRsSource.RecordCount > 0) Then
360         Call BuildJoinedRecordSet(AdoRsSource, intFeedID, False, True) ' Call ProcessJoinedRecordsetForDeletes(AdoRsSource, intFeedID)
370       End If
380     End If

390     If AdoRsSource.State = 1 Then AdoRsSource.Close
400     Set AdoRsSource = Nothing
End Sub

'This property returns a built recordset.
Public Property Get GetDynamicRecordset() As ADODB.Recordset
10      If (ADORSJN Is Nothing) Then
20        Set GetDynamicRecordset = Nothing
          
30        Exit Property
40      End If
        
50      If (ADORSJN.State = 0) Then
60        Set GetDynamicRecordset = Nothing
          
70        Exit Property
80      End If
        
90      If ADORSJN.RecordCount > 0 Then
100       Set GetDynamicRecordset = ADORSJN
110     End If
End Property



'This sub runs any stored procedure.
'All that needs to be done is pass the stored proc name and the parameters in the order the
'stored proc expects them.
Public Sub CollectAndProcessJobs(ByVal strStoredProc As String, ByVal strParams As String, Optional blnOverrideSource As Boolean = False, Optional strEmediaID As String = "", Optional ByVal strParamUsed As String = "", Optional ByVal intParamUsedType As Integer = 0, Optional ByVal strSQL As String = "") 'As Recordset
        Dim adors As ADODB.Recordset
        Dim ADOCM As ADODB.Command
        Dim clsReportErrs As Auto_Feed_Errors.clsAuto_Feed_Errors
        Dim strSplitParams() As String
        Dim strDataSources As String '* 71
        Dim strTrimDataSources As String
        Dim intDelim As Integer
        Dim strCurrentSource As String
        Dim strMethod As String
        Dim strErrMessage As String
        Dim strCommandTimeOut As String ' * 5
        Dim strTroubledMedia As String ' * 100
        Dim strSplitTroubleMedia() As String
        Dim strGetEmIDOrder As String ' * 200
        Dim intCntTroubleMedia As Integer
        Dim blnTroubledMedia As Boolean
        Dim strServerSource As String ' * 2
        Dim strServerCount As String ' * 15
        Dim strGetSourceCount As String
        Dim strWriteSourceCount As String
        Dim strFormatSource As String
        Dim lngServerCount As Long
        Dim lngJobCount As Long
        Dim blnGetJobDesc As Boolean
        Dim lngLogID As Long
        Dim strLogInformation As String
        Dim strTempSQLForSubID As String
        
        Static strIterationSources As String
        Static blnIteration As Boolean
        
        Dim jobsCnn As ADODB.Connection
        
        Dim strCheckStartValue As String
        Dim strMsg As String
        
        '**********************************************************
        If (blnDebug = False) Then
          If (InStrB(LCase(strMachine), "nyc") > 0) Then
            strCheckStartValue = strMachine & "_START_VALUE_" & Format(Now, "mm_dd_yyyy_hh")
            
            If (clsObjXmlSettings.GetXMLSettings("DEVELOPERS", strCheckStartValue, vbNullString) = vbNullString) Then
              strMsg = "Developer " & strMachine & " has debug (START) value set to False." & vbNewLine & "Date: " & Now & vbNewLine & "AutofeedID: " & intAutoFeedID
              
              Call clsObjXmlSettings.InsertUpdateXMLSettings("DEVELOPERS", strCheckStartValue, "Y")
              
              Call EmailMessage("crey@hodesiq.com", "crey@hodesiq.com;jcamacho@hodesiq.com", "Developer " & strMachine & " has debug (START) value set to False", vbNullString, vbNullString, strMsg, vbNullString)
              
              Call ReportDebugValueForDeveloper(strMachine, strMsg)
            End If
          End If
        End If
        '**********************************************************
        
10      blnTroubledMedia = False
        
30      If ((strOrderEmediaID = MONSTER) Or (strOrderEmediaID = MONSTER_10457)) Then
40        strGetEmIDOrder = clsObjXmlSettings.GetXMLSettings("EMEDIA_ORDERING", "E_" & strOrderEmediaID, "")  'lngVal = GetPrivateProfileString("EMEDIA_ORDERING", "E_" & strOrderEmediaID, "", strGetEmIDOrder, 200, "d:\data\db\AutoFeeds.ini")
          'If lngVal > 0 Then strGetEmIDOrder = Left(strGetEmIDOrder, lngVal)
50      End If
        
60      strTroubledMedia = clsObjXmlSettings.GetXMLSettings("TROUBLED_MEDIA", "EMEDIA_IDS", "") 'lngVal = GetPrivateProfileString("TROUBLED_MEDIA", "EMEDIA_IDS", "",  strTroubledMedia, 100, "d:\data\db\AutoFeeds.ini")
          
70      If Len(strTroubledEmedia) > 0 Then
80        strSplitTroubleMedia = Split(strTroubledMedia, ",")
            
90        If (UBound(strSplitTroubleMedia) > -1) Then
100         For intCntTroubleMedia = 0 To UBound(strSplitTroubleMedia)
110           If (strTroubledEmedia = Trim(strSplitTroubleMedia(intCntTroubleMedia))) Then
120             blnTroubledMedia = True
                
130             strCommandTimeOut = clsObjXmlSettings.GetXMLSettings("TROUBLED_MEDIA", "COMMAND_TIME", "600") '                  lngVal = GetPrivateProfileString("TROUBLED_MEDIA", "COMMAND_TIME", "600", strCommandTimeOut, 5, "d:\data\db\AutoFeeds.ini")
                  
140             Exit For
150           End If
160         Next intCntTroubleMedia
170       End If
180     End If
        
200     strMethod = "CollectAndProcessJobs"
        
210     strSplitParams = Split(strParams, ",")
        
220     Set adors = New ADODB.Recordset
        
230     If (blnOverrideSource = False) Then
240       If (Not blnIteration) Then
250          strDataSources = clsObjXmlSettings.GetXMLSettings("DATA_SOURCES", "SOURCES", MASTER_SOURCE) ' lngVal = GetPrivateProfileString("DATA_SOURCES", "SOURCES", MASTER_SOURCE, strDataSources, 71, "d:\data\db\AutoFeeds.ini")
260       Else
            'If this function is getting called from itself then just read the strIteration variable to keep getting the next sources.
270         strDataSources = strIterationSources
            
280         strIterationSources = ""
290         blnIteration = False
300       End If
310     Else
320       strDataSources = MASTER_SOURCE & ","
330     End If
        
340     intDelim = InStr(strDataSources, ",")
        
350     strTrimDataSources = strDataSources
        
360     strKeepSourceList = strTrimDataSources
        
370     On Error GoTo ExecStoredProc_Error
        
380     Do While Len(strTrimDataSources) > 0
390       Set ADOCM = New ADODB.Command
        
400       If intDelim > 0 Then
410         strCurrentSource = Left(strTrimDataSources, intDelim - 1)
            
420         strTrimDataSources = Right(strTrimDataSources, Len(strTrimDataSources) - intDelim)
430       Else
440         strCurrentSource = strTrimDataSources
            
450         strTrimDataSources = ""
460       End If
          
470       intDelim = InStr(strTrimDataSources, ",")
          
490       Set jobsCnn = New ADODB.Connection
        
491       With jobsCnn
492         .CursorLocation = adUseClient
493         .ConnectionString = "File Name=" & UDL_PATH & strCurrentSource
494         .Open
495       End With
  
500       With ADOCM
510         Set .ActiveConnection = jobsCnn
511         .CommandType = adCmdStoredProc

520         If (LenB(strSQL) > 0) Then
620           .CommandText = strSQL
630         Else
650           .CommandText = strStoredProc
            End If
           
660         If ((blnTroubledMedia = True) And (Len(Trim(strTroubledMedia)) > 0)) Then
670           .CommandTimeout = IIf(IsNumeric(strCommandTimeOut), CLng(strCommandTimeOut), 600)
680         Else
690           .CommandTimeout = intCommandTimeOut 'Just in case
700         End If
              
710         If Len(strParams) > 0 Then .Parameters.Append .CreateParameter("@CIDlist", adVarChar, adParamInput, 4000, strSplitParams(0))
              'this is used by system email to pass the emediaID in addition to the clientID
720         If Len(strEmediaID) > 0 Then .Parameters.Append .CreateParameter("@EmediaID", adVarChar, adParamInput, 10, strEmediaID)
            
740         If (blnUseSubID = True) Then
750           .Parameters.Append .CreateParameter("@Exclude", adInteger, adParamInput, , 0)
760           .Parameters.Append .CreateParameter("@SubID", adInteger, adParamInput, , lngSubID)

              If (LenB(strCBLGuid) > 0) Then
                .Parameters.Append .CreateParameter("@Guid", adVarChar, adParamInput, 40, strCBLGuid)
              End If
770         Else
              If (LenB(strCBLGuid) > 0) Then
780             If (UBound(strSplitParams) = 1) Then
                  .Parameters.Append .CreateParameter("@Exclude", adInteger, adParamInput, , CLng(strSplitParams(1)))
                Else
                  .Parameters.Append .CreateParameter("@Exclude", adInteger, adParamInput, , 0)
                End If
                
                .Parameters.Append .CreateParameter("@SubID", adInteger, adParamInput, , 0)
                .Parameters.Append .CreateParameter("@Guid", adVarChar, adParamInput, 40, strCBLGuid)
              Else
                If (UBound(strSplitParams) = 1) Then
                  .Parameters.Append .CreateParameter("@Exclude", adInteger, adParamInput, , CLng(strSplitParams(1)))
                End If
              End If
790         End If
                                
'820         adors.CursorLocation = adUseClient

            'If we are testing let's just get 10 records
830         If (blnDebug = True) Then
840           jobsCnn.Execute "set rowcount 10"
850         End If
                                
910         Set adors = .Execute
              
930         Set adors.ActiveConnection = Nothing
940       End With
        
950       If jobsCnn.State = 1 Then jobsCnn.Close
951       Set jobsCnn = Nothing
        
960       lngJobCount = adors.RecordCount
            
970       If lngJobCount = 0 Then
980         adors.Close
990       Else
            If (LenB(strEmediaID) > 0) Then
1001          strNoConvMediaID = clsObjXmlSettings.GetXMLSettings("HTML", "AVOID_CONVERT_TO_HTML_E_" & strEmediaID, "N")
            End If
                
1010        blnGetJobDesc = GetSeparateJobDescription(adors, strEmediaID, strStoredProc)

1020        Call BuildJoinedRecordsetMultiSource(adors, strCurrentSource, intParamUsedType, blnGetJobDesc, strParamUsed, strEmediaID, strParams)
1060      End If

1080      strFormatSource = UCase(Replace(strCurrentSource, ".udl", "", 1, -1, vbTextCompare))
1090      strGetSourceCount = "S_" & strFormatSource & "_GET_COUNT"

1100      strServerSource = clsObjXmlSettings.GetXMLSettings("SERVERS_COUNT", strGetSourceCount, "") 'lngVal = GetPrivateProfileString("SERVERS_COUNT", strGetSourceCount, "", strServerSource, 2, "d:\data\db\AutoFeeds.ini")

1110      If (Trim(strServerSource) = "Y") Then
1120        strWriteSourceCount = "S_" & strFormatSource & "_" & Format(Date, "mmddyy") & "_COUNT"

1130        strServerCount = clsObjXmlSettings.GetXMLSettings("SERVERS_COUNT", strWriteSourceCount, "0") ' lngVal = GetPrivateProfileString("SERVERS_COUNT", strWriteSourceCount, "0", strServerCount, 15, "d:\data\db\AutoFeeds.ini")

1140        lngServerCount = IIf(IsNumeric(strServerCount), CLng(strServerCount), 0)

1150        lngServerCount = lngServerCount + lngJobCount
                
1160        Call clsObjXmlSettings.InsertUpdateXMLSettings("SERVERS_COUNT", strWriteSourceCount, CStr(lngServerCount))   ' Call WritePrivateProfileString("SERVERS_COUNT", strWriteSourceCount, CStr(lngServerCount), "d:\data\db\AutoFeeds.ini")
1170      End If

1220      Set ADOCM = Nothing
1230    Loop
        
        'rsMultiSource is a module level variable.
1240    If (rsMultiSource Is Nothing) Then
1250      Set JobsRecordset = Nothing
1260    Else
1270      If Not rsMultiSource.EOF Then
            'This needs to be back when ready for datasplit.
            'With this all stored procs need these fields to be in the select clause.
            '**rsMultiSource.Sort = "postdate desc, requisition_id, req_emediaID DESC" ', TransactionID desc, operation_status asc"
          
1280        If (Not (rsMultiSource Is Nothing)) Then
1290          If (rsMultiSource.RecordCount > 0) Then
                'Sorting for Monster (3060) is done here to avoid an error from the db, this error has to do with ordering and some jobs's length exceeding the limit of 8092.
1300            If (((strOrderEmediaID = MONSTER) Or (strOrderEmediaID = MONSTER_10457))) Then rsMultiSource.Sort = strGetEmIDOrder

1310            rsMultiSource.MoveFirst
1320          End If
1330        End If

            'Set ExecStoredProc = rsMultiSource
1340        Set JobsRecordset = rsMultiSource
1350      Else
1360        Set JobsRecordset = Nothing
1370      End If
1380    End If
        
      '880     Set ADOCM = Nothing
        
        'ADORS.Close
1390    Set adors = Nothing
1400    Set rsMultiSource = Nothing
        
1410    Exit Sub
        
ExecStoredProc_Error:
1420    If (Not (jobsCnn Is Nothing)) Then
          If jobsCnn.State = 1 Then jobsCnn.Close
        End If
        
1421    Set jobsCnn = Nothing

1430    If (Not (adors Is Nothing)) Then
1440      If adors.State = 1 Then adors.Close
1450      Set adors = Nothing
1460    End If

1470    If (Not (rsMultiSource Is Nothing)) Then
1480      If rsMultiSource.State = 1 Then rsMultiSource.Close
1490      Set rsMultiSource = Nothing
1500    End If
        
1510    If (Not (JobsRecordset Is Nothing)) Then
1520      If JobsRecordset.State = 1 Then rsMultiSource.Close
1530      Set JobsRecordset = Nothing
1540    End If
        
1550    Set ADOCM = Nothing

1560    Set clsReportErrs = New Auto_Feed_Errors.clsAuto_Feed_Errors
        
1570    strErrMessage = "An error has occurred" & "<br>" & _
                      "Error number: " & Err.Number & "<br>" & _
                      "Error description: " & Err.Description & "<br>" & _
                      "In function or sub: " & strMethod & "<br>" & _
                      "In line: " & Erl & "<br>" & _
                      "Stored Proc: " & strStoredProc & "<br>" & _
                      "Parameters: " & strParams & "<br>" & _
                      "EmediaID " & strEmediaID & "<br>" & _
                      "OverRide: " & blnOverrideSource & "<br>" & _
                      "UDL file name: " & strCurrentSource & "<br>" & _
                      "Method name: " & strMethod & "<br>" & _
                      "Date: " & Format(Date, "mm/dd/yyyy") & "<br>" & _
                      "Time: " & Format(Time, "hh:mm:ss") & "<br>" & _
                      "Last param: " & strParamUsed

1580    Call clsReportErrs.ReportErrors("No extra information", _
                                    "AUTO_FEED_DATA|clsGetDBData|" & strMethod, _
                                    Err.Source & "<br><br>" & Err.Description & "<br><br>" & strErrMessage, _
                                    Erl, _
                                    Err.Number, _
                                    0, _
                                    strCurrentSource, _
                                    "N/A", _
                                    intAutoFeedID, _
                                    strEmediaID, _
                                    strParams, _
                                    "N/A", _
                                    "N/A", _
                                    "N/A", _
                                    "N/A", _
                                    strParamUsed, _
                                    0, _
                                    0, _
                                    strMachine, _
                                    strStoredProc, _
                                    intParamUsedType, _
                                    3, _
                                    IIf(intParamUsedType = 5, 1, 0), _
                                    vbNullString, _
                                    blnUseSubID, lngSubID)
                                    

1590    Set clsReportErrs = Nothing
End Sub


'
'This sub runs any stored procedure.
'All that needs to be done is pass the stored proc name and the parameters in the order the
'stored proc expects them.
Public Sub ExecStoredProc_SetRs(ByVal strStoredProc As String, ByVal strParams As String, Optional blnOverrideSource As Boolean = False, Optional strEmediaID As String = "", Optional ByVal strParamUsed As String = "", Optional ByVal intParamUsedType As Integer = 0, Optional ByVal strSQL As String = "") 'As Recordset
        Dim adors As ADODB.Recordset
        Dim ADOCM As ADODB.Command
        Dim clsReportErrs As Auto_Feed_Errors.clsAuto_Feed_Errors
        Dim strSplitParams() As String
        Dim strDataSources As String '* 71
        Dim strTrimDataSources As String
        Dim intDelim As Integer
        Dim strCurrentSource As String
        Dim strMethod As String
        Dim strErrMessage As String
        Dim strCommandTimeOut As String ' * 5
        Dim strTroubledMedia As String ' * 100
        Dim strSplitTroubleMedia() As String
        Dim strGetEmIDOrder As String ' * 200
        Dim intCntTroubleMedia As Integer
        Dim blnTroubledMedia As Boolean
        Dim strServerSource As String ' * 2
        Dim strServerCount As String ' * 15
        Dim strGetSourceCount As String
        Dim strWriteSourceCount As String
        Dim strFormatSource As String
        Dim lngServerCount As Long
        Dim lngJobCount As Long
        Dim blnGetJobDesc As Boolean
        Dim lngLogID As Long
        Dim strLogInformation As String
        Dim strTempSQLForSubID As String
        
        Static strIterationSources As String
        Static blnIteration As Boolean
        
10      blnTroubledMedia = False
        
        
20      If (intParamUsedType = 5) Then
30        If ((strOrderEmediaID = MONSTER) Or (strOrderEmediaID = MONSTER_10457)) Then
40          strGetEmIDOrder = clsObjXmlSettings.GetXMLSettings("EMEDIA_ORDERING", "E_" & strOrderEmediaID, "")  'lngVal = GetPrivateProfileString("EMEDIA_ORDERING", "E_" & strOrderEmediaID, "", strGetEmIDOrder, 200, "d:\data\db\AutoFeeds.ini")
            'If lngVal > 0 Then strGetEmIDOrder = Left(strGetEmIDOrder, lngVal)
50        End If
        
60        strTroubledMedia = clsObjXmlSettings.GetXMLSettings("TROUBLED_MEDIA", "EMEDIA_IDS", "") 'lngVal = GetPrivateProfileString("TROUBLED_MEDIA", "EMEDIA_IDS", "",  strTroubledMedia, 100, "d:\data\db\AutoFeeds.ini")
          
70        If Len(strTroubledEmedia) > 0 Then
            'strTroubledMedia = ""
          'Else
            'strTroubledMedia = Left(strTroubledMedia, lngVal)
            
80          strSplitTroubleMedia = Split(strTroubledMedia, ",")
            
90          If (UBound(strSplitTroubleMedia) > -1) Then
100           For intCntTroubleMedia = 0 To UBound(strSplitTroubleMedia)
110             If (strTroubledEmedia = Trim(strSplitTroubleMedia(intCntTroubleMedia))) Then
120               blnTroubledMedia = True
                  
130               strCommandTimeOut = clsObjXmlSettings.GetXMLSettings("TROUBLED_MEDIA", "COMMAND_TIME", "600") '                  lngVal = GetPrivateProfileString("TROUBLED_MEDIA", "COMMAND_TIME", "600", strCommandTimeOut, 5, "d:\data\db\AutoFeeds.ini")
                  'strCommandTimeOut = Left(strCommandTimeOut, lngVal)
                  
140               Exit For
150             End If
160           Next intCntTroubleMedia
170         End If
180       End If
190     End If
        
200     strMethod = "ExecStoredProc_SetRs"
        
210     strSplitParams = Split(strParams, ",")
        
220     Set adors = New ADODB.Recordset
        
230     If (blnOverrideSource = False) Then
240       If (Not blnIteration) Then
250          strDataSources = clsObjXmlSettings.GetXMLSettings("DATA_SOURCES", "SOURCES", MASTER_SOURCE) ' lngVal = GetPrivateProfileString("DATA_SOURCES", "SOURCES", MASTER_SOURCE, strDataSources, 71, "d:\data\db\AutoFeeds.ini")
        
      '70          If (Len(strDataSources) = 0) Then
      '80            strDataSources = MASTER_SOURCE & ","
      '90          Else
      '100           strDataSources = Left(strDataSources, lngVal)
      '110         End If
260       Else
            'If this function is getting called from itself then just read the strIteration variable to keep getting the next sources.
270         strDataSources = strIterationSources
            
280         strIterationSources = ""
290         blnIteration = False
300       End If
310     Else
320       strDataSources = MASTER_SOURCE & ","
330     End If
        
340     intDelim = InStr(strDataSources, ",")
        
350     strTrimDataSources = strDataSources
        
      '220     strTrimDataSources = Trim(strTrimDataSources)
360     strKeepSourceList = strTrimDataSources
        
370     On Error GoTo ExecStoredProc_Error
        
380     Do While Len(strTrimDataSources) > 0
390       Set ADOCM = New ADODB.Command
        
400       If intDelim > 0 Then
410         strCurrentSource = Left(strTrimDataSources, intDelim - 1)
            
420         strTrimDataSources = Right(strTrimDataSources, Len(strTrimDataSources) - intDelim)
430       Else
440         strCurrentSource = strTrimDataSources
            
450         strTrimDataSources = ""
460       End If
          
470       intDelim = InStr(strTrimDataSources, ",")
          
480       If (CheckUDL(UDL_PATH & strCurrentSource)) Then
490         Call SetConnection(strCurrentSource)
            
            
500       With ADOCM
510         Set .ActiveConnection = adocn
511         .CommandType = adCmdStoredProc

520         If ((LenB(strSQL) > 0) And (intParamUsedType = 5)) Then
620           .CommandText = strSQL
630         Else
650           .CommandText = strStoredProc
            End If
           
660         If ((blnTroubledMedia = True) And (Len(Trim(strTroubledMedia)) > 0)) Then
670           .CommandTimeout = IIf(IsNumeric(strCommandTimeOut), CLng(strCommandTimeOut), 600)
680         Else
690           .CommandTimeout = intCommandTimeOut 'Just in case
700         End If
              
710         If Len(strParams) > 0 Then .Parameters.Append .CreateParameter("@CIDlist", adVarChar, adParamInput, 4000, strSplitParams(0))
              'this is used by system email to pass the emediaID in addition to the clientID
720         If Len(strEmediaID) > 0 Then .Parameters.Append .CreateParameter("@EmediaID", adVarChar, adParamInput, 10, strEmediaID)
            
730         If ((intParamUsedType = 5) Or (intParamUsedType = 1)) Then
740           If ((intParamUsedType = 5) And (blnUseSubID = True)) Then
750             .Parameters.Append .CreateParameter("@Exclude", adInteger, adParamInput, , Null)
760             .Parameters.Append .CreateParameter("@SubID", adInteger, adParamInput, , lngSubID)
770           Else
780             If (UBound(strSplitParams) = 1) Then .Parameters.Append .CreateParameter("@Exclude", adInteger, adParamInput, , CLng(strSplitParams(1)))
790           End If
800         End If
810        'End If
                                
'820        adors.CursorLocation = adUseClient
              'If we are testing let's just get 10 records
830        If (blnDebug = True) Then
840          adocn.Execute "set rowcount 10"
850        End If
                                
'860       If blnLogEvent Then
'870         strLogInformation = LogAnEvent(App.EXEName & "|clsGetDbData|ExecStoredProc_SetRs", strStoredProc, 1, strMachine, strParamUsed, strEmediaID, strParams, intAutoFeedID, 0, 0, intParamUsedType)
'880         lngLogID = CLng(Split(strLogInformation, "|")(0))
'890         Guids.strGuidGetJobs = Split(strLogInformation, "|")(1)
'900       End If
          
910       Set adors = .Execute

'920       If blnLogEvent Then Call UpdateAnEvent(lngLogID, intParamUsedType)
              
930       Set adors.ActiveConnection = Nothing
940       End With
        
            'ADORS.Open "Exec " & strStoredProc & " " & strParams, ADOCN, adOpenForwardOnly, adLockReadOnly ', adCmdStoredProc
950         Call UnsetConnection
        
960         lngJobCount = adors.RecordCount
            
            
970         If lngJobCount = 0 Then
980           adors.Close
990         Else
1000          If (intParamUsedType = 5) Then
                If (LenB(strEmediaID) > 0) Then
1001              strNoConvMediaID = clsObjXmlSettings.GetXMLSettings("HTML", "AVOID_CONVERT_TO_HTML_E_" & strEmediaID, "N")
                End If
                
1010            blnGetJobDesc = GetSeparateJobDescription(adors, strEmediaID, strStoredProc)

1020            Call BuildJoinedRecordsetMultiSource(adors, strCurrentSource, intParamUsedType, blnGetJobDesc, strParamUsed, strEmediaID, strParams)
1030          Else
1040            Call BuildJoinedRecordsetMultiSource(adors, strCurrentSource, intParamUsedType, False, strParamUsed, strEmediaID, strParams)
1050          End If
1060        End If

1070        If (intParamUsedType = 5) Then
1080          strFormatSource = UCase(Replace(strCurrentSource, ".udl", "", 1, -1, vbTextCompare))
1090          strGetSourceCount = "S_" & strFormatSource & "_GET_COUNT"

1100          strServerSource = clsObjXmlSettings.GetXMLSettings("SERVERS_COUNT", strGetSourceCount, "") 'lngVal = GetPrivateProfileString("SERVERS_COUNT", strGetSourceCount, "", strServerSource, 2, "d:\data\db\AutoFeeds.ini")
      '533           If lngVal > 0 Then strServerSource = Left(strServerSource, lngVal)

1110          If (Trim(strServerSource) = "Y") Then
1120            strWriteSourceCount = "S_" & strFormatSource & "_" & Format(Date, "mmddyy") & "_COUNT"

1130            strServerCount = clsObjXmlSettings.GetXMLSettings("SERVERS_COUNT", strWriteSourceCount, "0") ' lngVal = GetPrivateProfileString("SERVERS_COUNT", strWriteSourceCount, "0", strServerCount, 15, "d:\data\db\AutoFeeds.ini")
      '537             If lngVal > 0 Then strServerCount = Left(strServerCount, lngVal)

1140            lngServerCount = IIf(IsNumeric(strServerCount), CLng(strServerCount), 0)

1150            lngServerCount = lngServerCount + lngJobCount
                
1160            Call clsObjXmlSettings.InsertUpdateXMLSettings("SERVERS_COUNT", strWriteSourceCount, CStr(lngServerCount))   ' Call WritePrivateProfileString("SERVERS_COUNT", strWriteSourceCount, CStr(lngServerCount), "d:\data\db\AutoFeeds.ini")
1170          End If
1180        End If

1190      Else
            'Udl file not found
            '***
1200        EmailMessage strFromEmail, "crey@hodesiq.com;jcamacho@hodesiq.com", "UDL file not found", "", "", "The following udl file was not found: " & strCurrentSource, ""
1210      End If
          
1220      Set ADOCM = Nothing
1230    Loop
        
        'rsMultiSource is a module level variable.
1240    If (rsMultiSource Is Nothing) Then
1250      Set JobsRecordset = Nothing
1260    Else
1270      If Not rsMultiSource.EOF Then
            'This needs to be back when ready for datasplit.
            'With this all stored procs need these fields to be in the select clause.
            '**rsMultiSource.Sort = "postdate desc, requisition_id, req_emediaID DESC" ', TransactionID desc, operation_status asc"
          
1280        If (Not (rsMultiSource Is Nothing)) Then
1290          If (rsMultiSource.RecordCount > 0) Then
                'Sorting for Monster (3060) is done here to avoid an error from the db, this error has to do with ordering and some jobs's length exceeding the limit of 8092.
1300            If (((strOrderEmediaID = MONSTER) Or (strOrderEmediaID = MONSTER_10457)) And (intParamUsedType = 5)) Then rsMultiSource.Sort = strGetEmIDOrder

1310            rsMultiSource.MoveFirst
1320          End If
1330        End If

            'Set ExecStoredProc = rsMultiSource
1340        Set JobsRecordset = rsMultiSource
1350      Else
1360        Set JobsRecordset = Nothing
1370      End If
1380    End If
        
      '880     Set ADOCM = Nothing
        
        'ADORS.Close
1390    Set adors = Nothing
1400    Set rsMultiSource = Nothing
        
1410    Exit Sub
        
ExecStoredProc_Error:
1420    Call UnsetConnection

1430    If (Not (adors Is Nothing)) Then
1440      If adors.State = 1 Then adors.Close
1450      Set adors = Nothing
1460    End If

1470    If (Not (rsMultiSource Is Nothing)) Then
1480      If rsMultiSource.State = 1 Then rsMultiSource.Close
1490      Set rsMultiSource = Nothing
1500    End If
        
1510    If (Not (JobsRecordset Is Nothing)) Then
1520      If JobsRecordset.State = 1 Then rsMultiSource.Close
1530      Set JobsRecordset = Nothing
1540    End If
        
1550    Set ADOCM = Nothing

1560    Set clsReportErrs = New Auto_Feed_Errors.clsAuto_Feed_Errors
        
1570    strErrMessage = "An error has occurred" & "<br>" & _
                      "Error number: " & Err.Number & "<br>" & _
                      "Error description: " & Err.Description & "<br>" & _
                      "In function or sub: " & strMethod & "<br>" & _
                      "In line: " & Erl & "<br>" & _
                      "Stored Proc: " & strStoredProc & "<br>" & _
                      "Parameters: " & strParams & "<br>" & _
                      "EmediaID " & strEmediaID & "<br>" & _
                      "OverRide: " & blnOverrideSource & "<br>" & _
                      "UDL file name: " & strCurrentSource & "<br>" & _
                      "Method name: " & strMethod & "<br>" & _
                      "Date: " & Format(Date, "mm/dd/yyyy") & "<br>" & _
                      "Time: " & Format(Time, "hh:mm:ss") & "<br>" & _
                      "Last param: " & strParamUsed

      '790     Call EmailMessage("Autofeeds", "crey@hodesiq.com", "Error in " & strMethod, "", "", strErrMessage, "")
1580    Call clsReportErrs.ReportErrors("No extra information", _
                                    "AUTO_FEED_DATA|clsGetDBData|" & strMethod, _
                                    Err.Source & "<br><br>" & Err.Description & "<br><br>" & strErrMessage, _
                                    Erl, _
                                    Err.Number, _
                                    0, _
                                    strCurrentSource, _
                                    "N/A", _
                                    intAutoFeedID, _
                                    strEmediaID, _
                                    strParams, _
                                    "N/A", _
                                    "N/A", _
                                    "N/A", _
                                    "N/A", _
                                    strParamUsed, _
                                    0, _
                                    0, _
                                    strMachine, _
                                    strStoredProc, _
                                    intParamUsedType, _
                                    3, _
                                    IIf(intParamUsedType = 5, 1, 0), _
                                    vbNullString, _
                                    blnUseSubID, lngSubID)
                                    

1590    Set clsReportErrs = Nothing

        
      '        'If (strDataLog = "Y") Then
      '          'Call WriteToLogFile(strErrMessage)
      '        'End If
      '
      '        'If the database we are connecting to is different than IQ2, then report the error and clear it, try to continue just in case there is a recordset to return.
      '        'An error can be caused by for example, the "Randstad" database not having some stored procs that should not have.
      '        'Since the autofeeds doesn't care about where the data comes from then we need to catch the error and act appropriately.
      '800     Err.Clear
      '
      '        'There was an error, this error is probably due to one of the other servers not containing a required object, like a stored proc.
      '        'In this case if the strTrimDataSources is empty it means we have gone through all of the sources, let's then return the recordset with whatever jobs we found.
      '810     If (Len(strTrimDataSources) = 0) Then
      '820       If (Not (rsMultiSource Is Nothing)) Then
      '830         If (rsMultiSource.RecordCount > 0) Then
      '              'Sorting for Monster (3060) is done here to avoid an error from the db, this error has to do with ordering and some jobs's length exceeding the limit of 8092.
      '831           If ((strOrderEmediaID = MONSTER) And (intParamUsedType = 5)) Then rsMultiSource.Sort = strGetEmIDOrder
      '
      '840           rsMultiSource.MoveFirst
      '850         End If
      '860       End If
      '
      '870       Set JobsRecordset = rsMultiSource
      '880     Else
      '          'If strTrimDataSources is not empty it means we are not done going through all the databases, we need to call this proc
      '          'again in that case.
      '890       blnIteration = True
      '900       strIterationSources = strTrimDataSources
      '
      '910       Call ExecStoredProc_SetRs(strStoredProc, strParams, blnOverrideSource, strEmediaID, strParamUsed, intParamUsedType)
      '
      '          'If (Not rsMultiSource Is Nothing) Then
      '          '  Set ExecStoredProc = rsMultiSource
      '          'End If
      '920     End If
      '
      '930     Set AdoRs = Nothing
      '940     Set rsMultiSource = Nothing
End Sub


'This function runs any stored procedure.
'All that needs to be done is pass the stored proc name and the parameters in the order the
'stored proc expects them.
'Public Function ExecStoredProc(ByVal strStoredProc As String, ByVal strParams As String, Optional blnOverrideSource As Boolean = False) As Recordset
'        Dim AdoRs As ADODB.Recordset
'        Dim ADOCM As ADODB.Command
'        Dim strSplitParams() As String
'        Dim strDataSources As String * 71
'        Dim strTrimDataSources As String
'        Dim intDelim As Integer
'        Dim strCurrentSource As String
'
'        strSplitParams = Split(strParams, ",")
'
'        Set AdoRs = New ADODB.Recordset
'
'        If (blnOverrideSource = False) Then
'          lngVal = GetPrivateProfileString("DATA_SOURCES", "SOURCES", MASTER_SOURCE, strDataSources, 71, "d:\data\db\AutoFeeds.ini")
'
'          If lngVal = 0 Then
'            strDataSources = MASTER_SOURCE & ","
'          Else
'            strDataSources = Left(strDataSources, lngVal)
'          End If
'        Else
'          strDataSources = MASTER_SOURCE & ","
'        End If
'
'        intDelim = InStr(strDataSources, ",")
'
'        strTrimDataSources = strDataSources
'
'        strTrimDataSources = Trim(strTrimDataSources)
'        strKeepSourceList = strTrimDataSources
'
'        Do While Len(strTrimDataSources) > 0
'          Set ADOCM = New ADODB.Command
'
'          If intDelim > 0 Then
'            strCurrentSource = Left(strTrimDataSources, intDelim - 1)
'
'            strTrimDataSources = Right(strTrimDataSources, Len(strTrimDataSources) - intDelim)
'          Else
'            strCurrentSource = strTrimDataSources
'
'            strTrimDataSources = ""
'          End If
'
'          intDelim = InStr(strTrimDataSources, ",")
'
'          If (CheckUDL(UDL_PATH & strCurrentSource)) Then
'            Call SetConnection(strCurrentSource)
'
'            With ADOCM
'              Set .ActiveConnection = ADOCN
'              .CommandType = adCmdStoredProc
'              .CommandText = strStoredProc
'              .CommandTimeout = 200 'Just in case
'
'              If Len(strParams) > 0 Then .Parameters.Append .CreateParameter("@CIDlist", adVarChar, adParamInput, 4000, strSplitParams(0))
'
'              If UBound(strSplitParams) = 1 Then
'                .Parameters.Append .CreateParameter("@Exclude", adTinyInt, adParamInput, , CInt(strSplitParams(1)))
'              End If
'
'              AdoRs.CursorLocation = adUseClient
'
'              Set AdoRs = .Execute
'              Set AdoRs.ActiveConnection = Nothing
'            End With
'
'            'ADORS.Open "Exec " & strStoredProc & " " & strParams, ADOCN, adOpenForwardOnly, adLockReadOnly ', adCmdStoredProc
'            Call UnsetConnection
'
'            If AdoRs.RecordCount = 0 Then
'              AdoRs.Close
'            Else
'              Call BuildJoinedRecordsetMultiSource(AdoRs)
'            End If
'          End If
'
'          Set ADOCM = Nothing
'        Loop
'
'        'rsMultiSource is a module level variable.
'        If (rsMultiSource Is Nothing) Then
'          Set ExecStoredProc = Nothing
'        Else
'          If Not rsMultiSource.EOF Then
'            'This needs to be back when ready for datasplit.
'            'With this all stored procs need these fields to be in the select clause.
'            '**rsMultiSource.Sort = "postdate desc, requisition_id, req_emediaID DESC" ', TransactionID desc, operation_status asc"
'
'            rsMultiSource.MoveFirst
'
'            Set ExecStoredProc = rsMultiSource
'          Else
'            Set ExecStoredProc = Nothing
'          End If
'        End If
'
''880     Set ADOCM = Nothing
'
'        'ADORS.Close
'        Set AdoRs = Nothing
'        Set rsMultiSource = Nothing
'End Function


'This function is a copy of the function in auto_feed_biz.clscommonfeedmembers.EmailMessage() but it is rather
'copied here than having a circual reference going on.  In other words, auto_feed_biz is already referencing this dll to use it, I don't
'want this dll to have to reference back to the biz component.
Private Function EmailMessage(ByVal strFrom As String, _
                           ByVal strTo As String, _
                           ByVal strSubject As String, _
                           ByVal strCC As String, _
                           ByVal strBcc As String, _
                           ByVal strBody As String, _
                           ByVal strError As String) As Boolean
10            On Error GoTo EmailMessageError
              
              Dim clsCDOEmail As CDO.Message
              
20            Set clsCDOEmail = New CDO.Message

30            With clsCDOEmail
40              .From = strFrom
50              .To = strTo
60              .CC = strCC
70              .BCC = strBcc
80              .Subject = strSubject
90              .TextBody = strBody
                
100             .Send
110           End With
              
120           EmailMessage = True
              
130           Set clsCDOEmail = Nothing
              
140           Exit Function
              
EmailMessageError:
150           EmailMessage = False
              
              Dim clsSmart As SmartPostError.CLog
              
160           Set clsSmart = New SmartPostError.CLog
              
170           clsSmart.LogEvent App.EXEName, Err.Number, Err.Source, strError & vbCrLf & Err.Description, 1, "crey@hodesiq.com;errors@pubfolders.hodesiq.com", ""
              
180           Set clsSmart = Nothing
End Function

'Public Function CollectClientsForBHGFeed(ByVal strFilename As String, ByVal strUsername As String, ByVal strPwd As String) As String
'  Dim ADORS As ADODB.Recordset
'  Dim strCollectIDs As String
'
'  Set ADORS = New ADODB.Recordset
'
'  strSQL = "select clientid from tbl_auto_feed_clients where emediaid in (select Top 1 emediaid from tbl_auto_feed where Filename='" & strFilename & "' And Username='" & strUsername & "' And Pwd = '" & strPwd & "') And Active=0"
'
'  ADORS.Open strSQL, ADOCN, adOpenForwardOnly, adLockReadOnly, adCmdText
'
'  If Not ADORS.EOF Then
'    Do While Not ADORS.EOF
'      strCollectIDs = strCollectIDs & ADORS.Fields("ClientID").Value & "-"
'
'      ADORS.MoveNext
'    Loop
'
'    strCollectIDs = Left(strCollectIDs, Len(strCollectIDs) - 1)
'
'    CollectClientsForBHGFeed = strCollectIDs
'  Else
'    CollectClientsForBHGFeed = ""
'  End If
'
'  ADORS.Close
'  Set ADORS = Nothing
'End Function

Public Function GetCommonData(ByVal strFeedCriteria As String) As ADODB.Recordset ' , ByVal blnBHGFeed As Boolean) As ADODB.Recordset
        Dim adors As ADODB.Recordset
        Dim ADOCM As ADODB.Command
        Dim strSplitParams() As String
        Dim intTestID As Integer
          
10      strSplitParams = Split(strFeedCriteria, ",")
        
20      Set adors = New ADODB.Recordset
30      Set ADOCM = New ADODB.Command
        
40      Call SetConnection(MASTER_SOURCE)
        
50      With ADOCM
60        Set .ActiveConnection = adocn
70        .CommandType = adCmdStoredProc
          
80        If (Left(strFeedCriteria, 4) = "TEST") Then
90          intTestID = CInt(Mid(strFeedCriteria, InStr(strFeedCriteria, "-") + 1, Len(strFeedCriteria)))

100         .CommandText = typProcsList.strAutoFeedTest
110       Else
120         .CommandText = typProcsList.strGetCommonData
130       End If

140       .CommandTimeout = intCommandTimeOut ' 200 'Just in case
          
150       If (Left(strFeedCriteria, 4) = "TEST") Then
160         .Parameters.Append .CreateParameter("@intAutoFeedTestID", adInteger, adParamInput, , intTestID)
170       Else
180         .Parameters.Append .CreateParameter("@intAutoFeedID", adVarChar, adParamInput, 4000, CInt(strSplitParams(0)))
190         .Parameters.Append .CreateParameter("@intClientID", adInteger, adParamInput, , CInt(strSplitParams(1)))
200         .Parameters.Append .CreateParameter("@intAutoFeedMediaID", adInteger, adParamInput, , CLng(strSplitParams(2)))
            
210         If UBound(strSplitParams) = 3 Then
220           .Parameters.Append .CreateParameter("@intBhgFeed", adInteger, adParamInput, , CInt(strSplitParams(3)))
230         End If
240       End If
          
'250       adors.CursorLocation = adUseClient
          
260       Set adors = .Execute
270       Set adors.ActiveConnection = Nothing
280     End With

        'ADORS.Open "Exec " & strStoredProc & " " & strParams, ADOCN, adOpenForwardOnly, adLockReadOnly ', adCmdStoredProc
290     Call UnsetConnection
        
300     If Not adors.EOF Then
310       strOrderEmediaID = (adors.Fields("EmediaID").Value & "")

320       Set GetCommonData = adors
330     Else
340       Set GetCommonData = Nothing
350     End If
        
360     Set ADOCM = Nothing
        
        'ADORS.Close
370     Set adors = Nothing
End Function

Public Function LogAnEvent(ByVal strEventSource As String, ByVal strEventAction As String, ByVal intEventName As Integer, ByVal strMachineName As String, ByVal strParam As String, ByVal strEmediaID As String, ByVal strClientID As String, ByVal strFeedID As String, ByVal lngReqEmID As Long, ByVal lngAbsPos As Long, ByVal intParamUsedType As Integer, ByVal strScheduledTime As String, Optional ByVal strUniqueID As String) As String ' Long
'10      If (blnLogEvent = False) Then Exit Function
        
        Dim lngRecsAffected As Long
        Dim ADOCM As ADODB.Command
        Dim strErrMessage As String
        Dim strMethod As String
        Dim clsReportErrs As Auto_Feed_Errors.clsAuto_Feed_Errors
        
20      On Error GoTo ExecStoredProc_Ret_Err
        
30      strMethod = "LogAnEvent"
        
40      Set ADOCM = New ADODB.Command
        
50      Call SetConnection(MASTER_SOURCE)
        
60      With ADOCM
70        Set .ActiveConnection = adocn
80        .CommandType = adCmdStoredProc
90        .CommandText = typProcsList.strLogEvent

100       .Parameters.Append .CreateParameter("@return", adInteger, adParamReturnValue)

110       .Parameters.Append .CreateParameter("@EventSource", adVarChar, adParamInput, 50, Left(strEventSource, 50))
120       .Parameters.Append .CreateParameter("@EventAction", adVarChar, adParamInput, 250, Left(strEventAction, 250))
130       .Parameters.Append .CreateParameter("@EventName", adInteger, adParamInput, , intEventName)
140       .Parameters.Append .CreateParameter("@EventIP", adVarChar, adParamInput, 50, Left(strMachine, 50))

150       If (Len(strParam) > 0) Then
160         .Parameters.Append .CreateParameter("@EventParam", adVarChar, adParamInput, 20, Left(strParam, 20))
170       Else
180         .Parameters.Append .CreateParameter("@EventParam", adVarChar, adParamInput, 20, Null)
190       End If

200       If (Len(strEmediaID) > 0) Then
210         .Parameters.Append .CreateParameter("@EventMediaID", adVarChar, adParamInput, 10, Left(strEmediaID, 10))
220       Else
230         .Parameters.Append .CreateParameter("@EventMediaID", adVarChar, adParamInput, 10, Null)
240       End If
          
250       If (Len(strClientID) > 0) Then
260         .Parameters.Append .CreateParameter("@EventClientID", adInteger, adParamInput, , CLng(strClientID))
270       Else
280         .Parameters.Append .CreateParameter("@EventClientID", adInteger, adParamInput, , Null)
290       End If

300       If (Len(strFeedID) > 0) Then
310         .Parameters.Append .CreateParameter("@EventFeedID", adInteger, adParamInput, , CInt(strFeedID))
320       Else
330         .Parameters.Append .CreateParameter("@EventFeedID", adInteger, adParamInput, , Null)
340       End If

350       If (lngAbsPos = 0) Then
360         .Parameters.Append .CreateParameter("@AbsolutePos", adInteger, adParamInput, , Null)
370       Else
380         .Parameters.Append .CreateParameter("@AbsolutePos", adInteger, adParamInput, , lngAbsPos)
390       End If

400       If (lngReqEmID = 0) Then
410         .Parameters.Append .CreateParameter("@ReqEmID", adInteger, adParamInput, , Null)
420       Else
430         .Parameters.Append .CreateParameter("@ReqEmID", adInteger, adParamInput, , lngReqEmID)
440       End If

401       If (LenB(strScheduledTime) = 0) Then
402         .Parameters.Append .CreateParameter("@ScheduledParam", adVarChar, adParamInput, 10, Null)
403       Else
404         .Parameters.Append .CreateParameter("@ScheduledParam", adVarChar, adParamInput, 10, strScheduledTime)
405       End If

450       If (LenB(strUniqueID) = 0) Then
460         .Parameters.Append .CreateParameter("@EventGuid", adGUID, adParamOutput, , Null)
470       Else
480         .Parameters.Append .CreateParameter("@EventGuid", adGUID, adParamInput, , strUniqueID)
490       End If

      '142       If (Len(strEventType) > 0) Then
      '143         .Parameters.Append .CreateParameter("@EventType", adChar, adParamInput, 1, Left(strEventType, 1))
      '144       Else
      '145         .Parameters.Append .CreateParameter("@EventType", adChar, adParamInput, 1, Null)
      '146       End If
      '
      '147       If (Len(strEventStartEnd) > 0) Then
      '148         .Parameters.Append .CreateParameter("@EventStartEnd", adInteger, adParamInput, , CInt(strEventStartEnd))
      '149       Else
      '150         .Parameters.Append .CreateParameter("@EventStartEnd", adInteger, adParamInput, , Null)
      '151       End If

500       .Execute lngRecsAffected

510       LogAnEvent = .Parameters("@Return").Value & "|" & .Parameters("@EventGuid").Value
520     End With

        'ADORS.Open "Exec " & strStoredProc & " " & strParams, ADOCN, adOpenForwardOnly, adLockReadOnly ', adCmdStoredProc
530     Call UnsetConnection
          
540     Set ADOCM = Nothing

550     Exit Function

ExecStoredProc_Ret_Err:
560     Call UnsetConnection
570     Set ADOCM = Nothing
        
580     Set clsReportErrs = New Auto_Feed_Errors.clsAuto_Feed_Errors
        
590     strErrMessage = "An error has occurred" & "<br>" & _
                      "Error number: " & Err.Number & "<br>" & _
                      "Error description: " & Err.Description & "<br>" & _
                      "In function or sub: " & strMethod & "<br>" & _
                      "In line: " & Erl & "<br>" & _
                      "Stored Proc: " & "" & "<br>" & _
                      "Parameters list: " & strParam & "<br>" & _
                      "UDL file name: " & MASTER_SOURCE & "<br>" & _
                      "Method name: " & strMethod & "<br>" & _
                      "Date: " & Format(Date, "mm/dd/yyyy") & "<br>" & _
                      "Time: " & Format(Time, "hh:mm:ss") & "<br>"

      '790     Call EmailMessage("Autofeeds", "crey@hodesiq.com", "Error in " & strMethod, "", "", strErrMessage, "")
600     Call clsReportErrs.ReportErrors("No extra information", _
                                    "AUTO_FEED_DATA|clsGetDBData|" & strMethod, _
                                    Err.Description & "<br><br>" & strErrMessage, _
                                    Erl, _
                                    Err.Number, _
                                    0, _
                                    MASTER_SOURCE, _
                                    "N/A", _
                                    intAutoFeedID, _
                                    "N/A", _
                                    "N/A", _
                                    "N/A", _
                                    "N/A", _
                                    "N/A", _
                                    "N/A", _
                                    "N/A", _
                                    0, _
                                    0, _
                                    strMachine, _
                                    typProcsList.strLogEvent, _
                                    intParamUsedType, _
                                    3, _
                                    0, _
                                    vbNullString, _
                                    blnUseSubID, lngSubID)
                                    
610     Err.Clear
                                    

620     Set clsReportErrs = Nothing

630     LogAnEvent = "-1"
End Function

Public Function UpdateAnEvent(ByVal lngLogID As Long, ByVal intParamUsedType As Integer) As Long
'10      If (blnLogEvent = False) Then Exit Function
        
        Dim lngRecsAffected As Long
        Dim ADOCM As ADODB.Command
        Dim strErrMessage As String
        Dim strMethod As String
        Dim clsReportErrs As Auto_Feed_Errors.clsAuto_Feed_Errors

20      On Error GoTo ExecStoredProc_Ret_Err

30      strMethod = "UpdateAnEvent"

40      Set ADOCM = New ADODB.Command

50      Call SetConnection(MASTER_SOURCE)

60      With ADOCM
70        Set .ActiveConnection = adocn
80        .CommandType = adCmdStoredProc
90        .CommandText = typProcsList.strUpdateEvent

100       .Parameters.Append .CreateParameter("@LogID", adInteger, adParamInput, , lngLogID)

110       .Execute lngRecsAffected

120       UpdateAnEvent = lngRecsAffected
130     End With

140     Call UnsetConnection

150     Set ADOCM = Nothing

160     Exit Function

ExecStoredProc_Ret_Err:
170     Call UnsetConnection
180     Set ADOCM = Nothing

190     Set clsReportErrs = New Auto_Feed_Errors.clsAuto_Feed_Errors

200     strErrMessage = "An error has occurred" & "<br>" & _
                      "Error number: " & Err.Number & "<br>" & _
                      "Error description: " & Err.Description & "<br>" & _
                      "In function or sub: " & strMethod & "<br>" & _
                      "In line: " & Erl & "<br>" & _
                      "Stored Proc: " & typProcsList.strUpdateEvent & "<br>" & _
                      "Parameters list: LogID=" & CStr(lngLogID) & "<br>" & _
                      "UDL file name: " & MASTER_SOURCE & "<br>" & _
                      "Method name: " & strMethod & "<br>" & _
                      "Date: " & Format(Date, "mm/dd/yyyy") & "<br>" & _
                      "Time: " & Format(Time, "hh:mm:ss") & "<br>"

      '790     Call EmailMessage("Autofeeds", "crey@hodesiq.com", "Error in " & strMethod, "", "", strErrMessage, "")
210     Call clsReportErrs.ReportErrors("No extra information", _
                                    "AUTO_FEED_DATA|clsGetDBData|" & strMethod, _
                                    Err.Description & "<br><br>" & strErrMessage, _
                                    Erl, _
                                    Err.Number, _
                                    0, _
                                    MASTER_SOURCE, _
                                    "N/A", _
                                    intAutoFeedID, _
                                    "N/A", _
                                    "N/A", _
                                    "N/A", _
                                    "N/A", _
                                    "N/A", _
                                    "N/A", _
                                    "N/A", _
                                    0, _
                                    0, _
                                    strMachine, _
                                    typProcsList.strUpdateEvent, _
                                    intParamUsedType, _
                                    3, _
                                    0, _
                                    vbNullString, _
                                    blnUseSubID, lngSubID)

220     Err.Clear


230     Set clsReportErrs = Nothing

240     UpdateAnEvent = -1
End Function







Public Function GetZip(ByVal lngCityID As Long) As String
        Dim adors As ADODB.Recordset
        Dim ADOCM As ADODB.Command
        Dim strAllDataSources As String
        Dim strZip As String
        Dim strCurrentSource As String
        Dim intDelim As Integer
        
10      strAllDataSources = strKeepSourceList
        
20      Set adors = New ADODB.Recordset

30      intDelim = InStr(strAllDataSources, ",")

40      Do While Len(strAllDataSources) > 0
50        Set ADOCM = New ADODB.Command
        
60        If intDelim > 0 Then
70          strCurrentSource = Left(strAllDataSources, intDelim - 1)
            
80          strAllDataSources = Right(strAllDataSources, Len(strAllDataSources) - intDelim)
90        Else
100         strCurrentSource = strAllDataSources
            
110         strAllDataSources = ""
120       End If
          
130       intDelim = InStr(strAllDataSources, ",")
          
140       If (Dir(UDL_PATH & strCurrentSource) <> "") Then
150         Call SetConnection(strCurrentSource)
        
160         With ADOCM
170           Set .ActiveConnection = adocn
180           .CommandType = adCmdStoredProc
190           .CommandText = typProcsList.strGetZip
      '200           .CommandTimeout = 200 'Just in case
          
200           .Parameters.Append .CreateParameter("@CityID", adVarChar, adParamInput, 4000, lngCityID)
          
'210           adors.CursorLocation = adUseClient
          
220           Set adors = .Execute
230           Set adors.ActiveConnection = Nothing
240         End With

            'ADORS.Open "Exec " & strStoredProc & " " & strParams, ADOCN, adOpenForwardOnly, adLockReadOnly ', adCmdStoredProc
250         Call UnsetConnection
        
260         If Not adors.EOF Then
270           strZip = adors.Fields("zip_code").Value
            
280           Exit Do
290         Else
300           strZip = ""
310         End If
320       End If
          
330       Set ADOCM = Nothing
340       If (adors.State = 1) Then adors.Close
350     Loop
        
360     GetZip = strZip
        
        'ADORS.Close
370     Set adors = Nothing
End Function

Public Property Get JobsRecordset() As ADODB.Recordset
10      Set JobsRecordset = rsJobsRecordset
End Property

Private Property Set JobsRecordset(ByVal rsObj As ADODB.Recordset)
10      Set rsJobsRecordset = rsObj
End Property

Public Sub KillRecordset()
10      Set ADORSJN = Nothing
End Sub

'Added 3/7/2007 by JSherian
Private Function GetDescriptionRS(ByVal lngRequisitionID As Long, ByVal strCurrentSource As String) As ADODB.Recordset
        Dim adors As ADODB.Recordset
        Dim ADOCM As ADODB.Command

10      Set adors = New ADODB.Recordset

20      Set ADOCM = New ADODB.Command

30      If (Dir(UDL_PATH & strCurrentSource) <> "") Then
40        Call SetConnection(strCurrentSource)

50        With ADOCM
60          Set .ActiveConnection = adocn
70          .CommandType = adCmdStoredProc
80          .CommandText = typProcsList.strGetDescription

90          .Parameters.Append .CreateParameter("@requisition_id", adInteger, adParamInput, 4, lngRequisitionID)

'100         adors.CursorLocation = adUseClient

110         Set adors = .Execute
120         Set adors.ActiveConnection = Nothing
130       End With

140       Call UnsetConnection

150       If Not adors.EOF Then Set GetDescriptionRS = adors
160     End If

170     Set ADOCM = Nothing
180     Set adors = Nothing
End Function

'Added 3/7/2007 by JSherian
Public Function VerifyProcExists(ByVal intAutoFeedID As Integer, ByVal strFileName As String) As Byte
        'Dim adors As ADODB.Recordset
        Dim ADOCM As ADODB.Command

      '20      'Set adors = New ADODB.Recordset

10      Set ADOCM = New ADODB.Command

20      Call SetConnection(MASTER_SOURCE)

30      With ADOCM
40        Set .ActiveConnection = adocn
50        .CommandType = adCmdStoredProc
60        .CommandText = typProcsList.strVerifyProcExists

70        .Parameters.Append .CreateParameter("@Return", adInteger, adParamReturnValue, 0)
80        .Parameters.Append .CreateParameter("@FID", adInteger, adParamInput, , intAutoFeedID)
90        .Parameters.Append .CreateParameter("@FName", adVarChar, adParamInput, 150, strFileName)
100       .Parameters.Append .CreateParameter("@Source", adVarChar, adParamInput, 50, Machine)

      '20         adors.CursorLocation = adUseClient

110       .Execute , , adExecuteNoRecords
      '240         Set adors.ActiveConnection = Nothing
120     End With

130     Call UnsetConnection

140     VerifyProcExists = ADOCM.Parameters("@Return").Value

150     Set ADOCM = Nothing

      '341     If (adors.State = 1) Then adors.Close
      '380     Set adors = Nothing
End Function

Public Function ExecStoredProc_Ret(ByVal strProcName As String, ByVal strParams As String, Optional ByVal intParamUsedType As Integer = 0) As Long
        Dim lngRecsAffected As Long
        Dim ADOCM As ADODB.Command
        Dim strSplitParams() As String
        Dim intCntParams As Integer
        Dim intParamLength As Integer
        Dim strErrMessage As String
        Dim strMethod As String
        Dim clsReportErrs As Auto_Feed_Errors.clsAuto_Feed_Errors
        
        ' If we are debugging and we are going to trim the history file then just exit function
10      If ((blnDebug = True) And (intParamUsedType = 29)) Then Exit Function
        
20      On Error GoTo ExecStoredProc_Ret_Err
        
30      strMethod = "ExecStoredProc_Ret"
        
40      Set ADOCM = New ADODB.Command
        
50      Call SetConnection(MASTER_SOURCE)
        
60      With ADOCM
70        Set .ActiveConnection = adocn
80        .CommandType = adCmdStoredProc
90        .CommandText = strProcName
100       .CommandTimeout = intCommandTimeOut ' 200 'Just in case

110       If strParams <> "" Then
120         strSplitParams = Split(strParams, ",")
            
130           For intCntParams = 0 To UBound(strSplitParams)
140             If IsNumeric(strSplitParams(intCntParams)) Then
150               .Parameters.Append .CreateParameter("@Param", adInteger, adParamInput, , strSplitParams(intCntParams))
160             Else
170               intParamLength = Len(strSplitParams(intCntParams))
                  
180               If intParamLength = 0 Then intParamLength = 1
                  
190               .Parameters.Append .CreateParameter("@Param", adVarChar, adParamInput, intParamLength, strSplitParams(intCntParams))
200             End If
210           Next intCntParams
220       End If
          
230       .Execute lngRecsAffected
240     End With

        'ADORS.Open "Exec " & strStoredProc & " " & strParams, ADOCN, adOpenForwardOnly, adLockReadOnly ', adCmdStoredProc
250     Call UnsetConnection
          
260     ExecStoredProc_Ret = lngRecsAffected
        
270     Set ADOCM = Nothing

280     Exit Function

ExecStoredProc_Ret_Err:
290     Call UnsetConnection
300     Set ADOCM = Nothing
        
310     Set clsReportErrs = New Auto_Feed_Errors.clsAuto_Feed_Errors
        
320     strErrMessage = "An error has occurred" & "<br>" & _
                      "Error number: " & Err.Number & "<br>" & _
                      "Error description: " & Err.Description & "<br>" & _
                      "In function or sub: " & strMethod & "<br>" & _
                      "In line: " & Erl & "<br>" & _
                      "Stored Proc: " & strProcName & "<br>" & _
                      "Parameters list: " & strParams & "<br>" & _
                      "UDL file name: " & MASTER_SOURCE & "<br>" & _
                      "Method name: " & strMethod & "<br>" & _
                      "Date: " & Format(Date, "mm/dd/yyyy") & "<br>" & _
                      "Time: " & Format(Time, "hh:mm:ss") & "<br>"

      '790     Call EmailMessage("Autofeeds", "crey@hodesiq.com", "Error in " & strMethod, "", "", strErrMessage, "")
330     Call clsReportErrs.ReportErrors("No extra information", _
                                    "AUTO_FEED_DATA|clsGetDBData|" & strMethod, _
                                    Err.Description & "<br><br>" & strErrMessage, _
                                    Erl, _
                                    Err.Number, _
                                    0, _
                                    MASTER_SOURCE, _
                                    "N/A", _
                                    intAutoFeedID, _
                                    "N/A", _
                                    "N/A", _
                                    "N/A", _
                                    "N/A", _
                                    "N/A", _
                                    "N/A", _
                                    "N/A", _
                                    0, _
                                    0, _
                                    strMachine, _
                                    strProcName, _
                                    intParamUsedType, _
                                    3, _
                                    0, _
                                    vbNullString, blnUseSubID, lngSubID)
                                    
340     Err.Clear
                                    

350     Set clsReportErrs = Nothing
End Function

'This function replaces the old way of saving files to a directory.
Public Function SaveFileDataToTable(ByVal intAutoFeedID As Integer, ByVal strFileName As String, ByVal strFileContent As String, ByVal intParamUsedType As Integer) As Byte
        Dim bytRecsAffected As Byte
        Dim ADOCM As ADODB.Command
        Dim strErrMessage As String
        Dim strMethod As String
        Dim clsReportErrs As Auto_Feed_Errors.clsAuto_Feed_Errors
        
10      strMethod = "SaveFileDataToTable"
        
20      Set ADOCM = New ADODB.Command
        
30      Call SetConnection(MASTER_SOURCE)
        
40      With ADOCM
50        Set .ActiveConnection = adocn
60        .CommandType = adCmdStoredProc
70        .CommandText = typProcsList.strSaveFileContent

80        .Parameters.Append .CreateParameter("@FID", adInteger, adParamInput, , intAutoFeedID)
90        .Parameters.Append .CreateParameter("@FName", adVarChar, adParamInput, 150, strFileName)
100       .Parameters.Append .CreateParameter("@Source", adVarChar, adParamInput, 50, strMachine)
110       .Parameters.Append .CreateParameter("@Content", adLongVarWChar, adParamInput, -1, strFileContent)
120       .Parameters.Append .CreateParameter("@IsXML", adInteger, adParamInput, , IIf(blnSaveAsXML = True, 1, 0))
          
130       .Execute bytRecsAffected
140     End With
        
150     Call UnsetConnection
          
160     SaveFileDataToTable = bytRecsAffected
        
170     Set ADOCM = Nothing
End Function

Public Function DeleteFileDataFromTable(ByVal intAutoFeedID As Integer, ByVal strFileName As String, ByVal intParamUsedType As Integer) As Byte
        Dim bytRecsAffected As Byte
        Dim ADOCM As ADODB.Command
        Dim strErrMessage As String
        Dim strMethod As String
        Dim clsReportErrs As Auto_Feed_Errors.clsAuto_Feed_Errors
        
10      strMethod = "DeleteFileDataFromTable"
        
20      Set ADOCM = New ADODB.Command
        
30      Call SetConnection(MASTER_SOURCE)
        
40      With ADOCM
50        Set .ActiveConnection = adocn
60        .CommandType = adCmdStoredProc
70        .CommandText = typProcsList.strDeleteFileContent

80        .Parameters.Append .CreateParameter("@FID", adInteger, adParamInput, , intAutoFeedID)
90        .Parameters.Append .CreateParameter("@FName", adVarChar, adParamInput, 150, strFileName)
100       .Parameters.Append .CreateParameter("@Source", adVarChar, adParamInput, 50, strMachine)
          
110       .Execute bytRecsAffected
120     End With
        
130     Call UnsetConnection
          
140     DeleteFileDataFromTable = bytRecsAffected
        
150     Set ADOCM = Nothing
End Function

Public Function BackUpFileDataFromTable(ByVal intAutoFeedID As Integer, ByVal strFileName As String, ByVal strSubjectLine As String, ByVal intParamUsedType As Integer) As Byte
        Dim bytRecsAffected As Byte
        Dim ADOCM As ADODB.Command
        Dim strErrMessage As String
        Dim strMethod As String
        Dim clsReportErrs As Auto_Feed_Errors.clsAuto_Feed_Errors
        
10      strMethod = "BackUpFileDataFromTable"
        
20      Set ADOCM = New ADODB.Command
        
30      Call SetConnection(MASTER_SOURCE)
        
40      With ADOCM
50        Set .ActiveConnection = adocn
60        .CommandType = adCmdStoredProc
70        .CommandText = typProcsList.strBackUpFileContent

80        .Parameters.Append .CreateParameter("@FID", adInteger, adParamInput, , intAutoFeedID)
90        .Parameters.Append .CreateParameter("@FName", adVarChar, adParamInput, 150, strFileName)
100       .Parameters.Append .CreateParameter("@Source", adVarChar, adParamInput, 50, strMachine)
110       .Parameters.Append .CreateParameter("@IDLine", adVarChar, adParamInput, 1000, strSubjectLine)
120       .Parameters.Append .CreateParameter("@Exists", adInteger, adParamOutput)
          
130       .Execute bytRecsAffected
140     End With
        
150     Call UnsetConnection
          
160     BackUpFileDataFromTable = ADOCM.Parameters("@Exists").Value
        
170     Set ADOCM = Nothing
End Function
Public Property Let propGetDescription(ByVal blnValue As Boolean)
10      blnGetDescription = blnValue
End Property

Public Property Let TroubledEMediaID(ByVal strTroubledEM As String)
10      strTroubledEmedia = strTroubledEM
End Property

Public Sub UpdateHistory(ByVal lngReqEmediaID As Long, ByVal intFeedID As Integer, ByVal strUDLFile As String, Optional intJobAction As Integer = 0, Optional ByVal strFileName As String = "")

10      If blnDebug = True Then Exit Sub

20      On Error GoTo UpdateHistoryErr

        'If (Left(strCheckDups, 1) = "Y") Then
        '  If (UpdateHistory_Test(lngReqEmediaID) = True) Then
        '    Dim sline As String
            
         '   sline = "reqemediaid=" & lngReqEmediaID & vbCrLf & "FeedID=" & intFeedId & vbCrLf & "jobaction=" & intJobAction & vbCrLf & "Date=" & Now
            
         '   Call EmailMessage("Autofeeds_Duplicate", "crey@hodesiq.com", "Duplicate detected", "", "", sline, "")
         ' End If
        'End If
        
        Dim ADOCM As ADODB.Command
30      Set ADOCM = New ADODB.Command

        '*This change will take place in our new db.
        'Override what comes in from the class, from now on history will be kept in one place.
40      strUDLFile = MASTER_SOURCE
        
50      Call SetConnection(strUDLFile)
        
60      With ADOCM
70        Set .ActiveConnection = adocn
80        .CommandType = adCmdStoredProc
90        .CommandText = typProcsList.strUpdateHistory
      '80        .CommandTimeout = 200 'Just in case
          
100       .Parameters.Append .CreateParameter("@ReqEmediaID", adVarChar, adParamInput, 4000, lngReqEmediaID)
110       .Parameters.Append .CreateParameter("@JobAction", adInteger, adParamInput, 4, intJobAction)
120       .Parameters.Append .CreateParameter("@FeedID", adInteger, adParamInput, 4, intFeedID)
        
130       If (blnUsesSlotQty = True) Then
140         If (Len(strFileName) > 0) Then
150           .Parameters.Append .CreateParameter("@FileName", adVarChar, adParamInput, 100, strFileName)
160         Else
170           .Parameters.Append .CreateParameter("@FileName", adVarChar, adParamInput, 100, "")
180         End If
            
190         .Parameters.Append .CreateParameter("@UsesSlotQty", adBoolean, adParamInput, 1, blnUsesSlotQty)
200       Else
210         If Len(strFileName) > 0 Then .Parameters.Append .CreateParameter("@FileName", adVarChar, adParamInput, 100, strFileName)
220       End If
         
230       .Execute
240     End With
        'this was commented out before
        'ADORS.Open "Exec " & strStoredProc & " " & strParams, ADOCN, adOpenForwardOnly, adLockReadOnly ', adCmdStoredProc
250     Call UnsetConnection
        
260     Set ADOCM = Nothing

270   Exit Sub

UpdateHistoryErr:
280     Call UnsetConnection
290     Set ADOCM = Nothing
        
300     Err.Raise Err.Number, Err.Source, Err.Description
End Sub


Public Sub UpdateHistoryFinal(ByVal feedID As String, Optional ByVal strFileName As String)
10       If blnDebug = True Then Exit Sub
         
20       On Error GoTo UpdateHistFinalErr
         
         Dim strDataSources As String ' * 71
         Dim strTrimDataSources As String
         Dim intDelim As Integer
         Dim strCurrentSource As String

        '*This change will take place in our new db.
        'These lines must be commented out leaving only    strDataSources = MASTER_SOURCE & ","
30       strDataSources = MASTER_SOURCE & ","

        'lngVal = GetPrivateProfileString("DATA_SOURCES", "SOURCES", MASTER_SOURCE, strDataSources, 71, "d:\data\db\AutoFeeds.ini")
        'strDataSources = Left(strDataSources, lngVal)
         
         Dim ADOCM As ADODB.Command
          
40       intDelim = InStr(strDataSources, ",")
50       strTrimDataSources = strDataSources
        
60        strTrimDataSources = Trim(strTrimDataSources)
70        strKeepSourceList = strTrimDataSources

                              
80        Do While Len(strTrimDataSources) > 0
90           Set ADOCM = New ADODB.Command
        
100          If intDelim > 0 Then
110            strCurrentSource = Left(strTrimDataSources, intDelim - 1)
              
120            strTrimDataSources = Right(strTrimDataSources, Len(strTrimDataSources) - intDelim)
130          Else
140           strCurrentSource = strTrimDataSources
            
150           strTrimDataSources = ""
160          End If
          
170          intDelim = InStr(strTrimDataSources, ",")
          
180          If (CheckUDL(UDL_PATH & strCurrentSource)) Then
190            Call SetConnection(strCurrentSource)
              
                
200            With ADOCM
210            Set .ActiveConnection = adocn
220            .CommandType = adCmdStoredProc
230            .CommandText = typProcsList.strUpdateHistoryFinal
240            .CommandTimeout = intCommandTimeOut  'Just in case
250            .Parameters.Append .CreateParameter("@FeedID", adVarChar, adParamInput, 1000, feedID)

260             If (Len(strFileName) > 0) Then .Parameters.Append .CreateParameter("@FileName", adVarChar, adParamInput, 100, strFileName)

270            .Execute
280            End With
          
290            Call UnsetConnection
              
300            Set ADOCM = Nothing
310          End If
320       Loop
          
330       Exit Sub
          
UpdateHistFinalErr:
340       Call UnsetConnection
350       Set ADOCM = Nothing
          
360       Err.Raise Err.Number, Err.Source, Err.Description
End Sub

Public Sub UpdateDateSent(ByVal strUsername As String, ByVal strPwd As String)
10      If blnDebug = True Then Exit Sub

20      On Error GoTo UpdateDateSentErr
        
        Dim ADOCM As ADODB.Command
30      Set ADOCM = New ADODB.Command
        
40      Call SetConnection(MASTER_SOURCE)
        
50      With ADOCM
60        Set .ActiveConnection = adocn
70        .CommandType = adCmdStoredProc
80        .CommandText = typProcsList.strUpdateDateSent
      '80        .CommandTimeout = 200 'Just in case
          
90        .Parameters.Append .CreateParameter("@UserName", adVarChar, adParamInput, 50, strUsername)
100       .Parameters.Append .CreateParameter("@Pwd", adVarChar, adParamInput, 100, strPwd)
          
110       .Execute
120     End With

        'ADORS.Open "Exec " & strStoredProc & " " & strParams, ADOCN, adOpenForwardOnly, adLockReadOnly ', adCmdStoredProc
130     Call UnsetConnection
        
140     Set ADOCM = Nothing

150   Exit Sub

UpdateDateSentErr:
160     Call UnsetConnection
170     Set ADOCM = Nothing
        
180     Err.Raise Err.Number, Err.Source, Err.Description
End Sub

Private Sub ReportDebugValueForDeveloper(ByVal strMachine As String, ByVal strMsg As String)
20      On Error GoTo ReportDebugValueForDeveloperErr
        
        Dim ADOCM As ADODB.Command
30      Set ADOCM = New ADODB.Command
        
40      Call SetConnection(MASTER_SOURCE)
        
50      With ADOCM
60        Set .ActiveConnection = adocn
70        .CommandType = adCmdStoredProc
80        .CommandText = typProcsList.strUpdateDevDebugVal
      '80        .CommandTimeout = 200 'Just in case
          
90        .Parameters.Append .CreateParameter("@Machine", adVarChar, adParamInput, 20, Left(strMachine, 20))
100       .Parameters.Append .CreateParameter("@Msg", adVarChar, adParamInput, 200, Left(strMsg, 200))
          
110       .Execute
120     End With

        'ADORS.Open "Exec " & strStoredProc & " " & strParams, ADOCN, adOpenForwardOnly, adLockReadOnly ', adCmdStoredProc
130     Call UnsetConnection
        
140     Set ADOCM = Nothing

150   Exit Sub

ReportDebugValueForDeveloperErr:
160     Call UnsetConnection
170     Set ADOCM = Nothing
        
180     Err.Raise Err.Number, Err.Source, Err.Description
End Sub
Private Sub SetConnection(ByVal strUDLFile As String, Optional ByRef adoOptConn As ADODB.Connection = Nothing)
10    If (adoOptConn Is Nothing) Then
20      Set adocn = New ADODB.Connection
        
30      With adocn
40        .CursorLocation = adUseClient
50        .ConnectionString = "File Name=" & UDL_PATH & strUDLFile
60        .Open
70      End With
80    Else
90      Set adoOptConn = New ADODB.Connection
        
100     With adoOptConn
110       .CursorLocation = adUseClient
120       .ConnectionString = "File Name=" & UDL_PATH & strUDLFile
130       .Open
140     End With
150   End If
End Sub

Private Sub UnsetConnection(Optional ByRef adoOptConn As ADODB.Connection = Nothing)
10    If (adoOptConn Is Nothing) Then
20      If Not (adocn Is Nothing) Then
30        If adocn.State = 1 Then adocn.Close
40        Set adocn = Nothing
50      End If
60    Else
70      If Not (adoOptConn Is Nothing) Then
80        If adoOptConn.State = 1 Then adoOptConn.Close
90        Set adoOptConn = Nothing
100     End If
110   End If
End Sub

'Private Sub WriteToLogFile(ByVal strLine As String)
'10      If (strDataLog = "N") Then Exit Sub
'
'        Dim objLog As Scripting.FileSystemObject
'        Dim objLogFile As Scripting.TextStream
'
'20      Set objLog = New Scripting.FileSystemObject
'
'30      Set objLogFile = objLog.OpenTextFile(strDataLogFile, ForAppending, True)
'
'40      objLogFile.WriteLine (strLine)
'
'50      objLogFile.Close
'
'60      Set objLogFile = Nothing
'70      Set objLog = Nothing
'End Sub

Private Sub Class_Initialize()
10      Set clsObjXmlSettings = New Auto_Feed_XML.clsXMLSettings
20      clsObjXmlSettings.FileName = "d:\data\db\AutoFeeds.xml"
        
30      blnDebug = CBool(clsObjXmlSettings.GetXMLSettings("DEBUG", "START", DEFAULT_DEBUG))  'lngVal = GetPrivateProfileString("DEBUG", "START", DEFAULT_DEBUG, strDebug, 6, "d:\data\db\AutoFeeds.ini")
40      intCommandTimeOut = CInt(clsObjXmlSettings.GetXMLSettings("SQL_PROPERTIES", "COMMAND_TIMEOUT", "240"))
41      strRegExNoHTMLAttributes = clsObjXmlSettings.GetXMLSettings("REGEX", "NO_HTML_ATTRIBUTES", vbNullString)
42      strRegExExcludedAttribMedia = clsObjXmlSettings.GetXMLSettings("REGEX", "MEDIA_EXCLUDED", vbNullString)
50      strFromEmail = clsObjXmlSettings.GetXMLSettings("POST_EMAIL", "POSTING_EMAIL", "")
51      strExcludedHorgs = clsObjXmlSettings.GetXMLSettings("EXCLUDED_HORGS", "HORG_IDS", "")
52      strRegExNoHTMLComments = clsObjXmlSettings.GetXMLSettings("REGEX", "NO_HTML_COMMENTS", "<!--[\r\n\s\w\W]*?-->")

53      If ((LenB(strRegExNoHTMLComments) > 0) And InStrB(1, strRegExNoHTMLComments, "<!--") = 0) Then
54        strRegExNoHTMLComments = "<!--" & strRegExNoHTMLComments & "-->"
55      End If

        strSplitExcludedHorgs = Split(strExcludedHorgs, ",")
        
60      If (blnDebug = True) Then
70        strSubType3Source = MASTER_SOURCE
80      Else
90        strSubType3Source = clsObjXmlSettings.GetXMLSettings("DATA_SOURCES", "SUB_TYPE3_SOURCE", MASTER_SOURCE)
100     End If

        strListOfExcludedQCodes = clsObjXmlSettings.GetXMLSettings("ALL_FEEDS", "EXCLUDED_QCODES", vbNullString)
        
      '20      If (lngVal = 0) Then
      '30        blnDebug = False
      '40      Else
      '50        If InStr(1, strDebug, "False", vbTextCompare) = 0 And InStr(1, strDebug, "True", vbTextCompare) = 0 Then
      '60          blnDebug = False
      '70        Else
      '80          blnDebug = CBool(strDebug)
      '90        End If
      '100     End If
              
      '110     strDataLog = clsObjXmlSettings.GetXMLSettings("DEBUG", "LogToDataSplit", DEFAULT_LOG_DATA_SPLIT) ' lngVal = GetPrivateProfileString("DEBUG", "LogToDataSplit", DEFAULT_LOG_DATA_SPLIT, strDataLog, 2, "d:\data\db\AutoFeeds.ini")
        
      '120     If (lngVal = 0) Then strDataLog = "N"
        
      '130     strDataLogFile = clsObjXmlSettings.GetXMLSettings("DEBUG", "LogFileDataSplit", DEFAULT_LOG_DATA_FILE) 'lngVal = GetPrivateProfileString("DEBUG", "LogFileDataSplit", DEFAULT_LOG_DATA_FILE, strDataLogFile, 40, "d:\data\db\AutoFeeds.ini")
        
      '140     If (lngVal = 0) Then
      '150       strDataLogFile = "d:\data\db\AutofeedDataSplitLog.csv"
      '160     Else
      '170       strDataLogFile = Left(strDataLogFile, lngVal)
      '180     End If
                      
      '        strCheckDups = clsObjXmlSettings.GetXMLSettings("DEBUG", "CHECK_DUPS", "N") ' lngVal = GetPrivateProfileString("DEBUG", "CHECK_DUPS", "N", strCheckDups, 2, "d:\data\db\AutoFeeds.ini")
           
      '        If (lngVal = 0) Then
      '          strCheckDups = "N"
      '        Else
      '          strCheckDups = Left(strCheckDups, lngVal)
      '        End If
                      
110     With typProcsList
130       .strGetZip = "Auto_feed_component_Get_Zip"
140       .strUpdateHistory = "Auto_feed_component_Update_History"
150       .strUpdateDateSent = "Auto_feed_component_Update_Date_Sent"
160       .strSetJoinedData = "Auto_feed_component_Set_Joined_Data"
170       .strUpdateHistoryFinal = "Auto_feed_component_Update_History_Final"
180       .strAutoFeedTest = "Auto_feed_component_get_test_data"
181       .strUpdateDevDebugVal = "dbo.Auto_Feed_Update_Dev_Debug_Value"

      'Added 3/7/2007 by JSherian
190       .strGetDescription = "Auto_Feed_Component_GetDescription"
200       .strLogEvent = "dbo.Auto_Feed_Generator_Log_Event"
210       .strUpdateEvent = "dbo.Auto_Feed_Generator_Update_Log_Event"
220       .strGetEncodes = "dbo.Auto_Feed_Generator_Encodes"
230       .strSaveFileContent = "dbo.Auto_Feed_Output_Save_Files"
240       .strGetFileContent = "dbo.Auto_Feed_Get_File_Content"
250       .strDeleteFileContent = "dbo.Auto_Feed_Delete_File_Content"
260       .strBackUpFileContent = "dbo.Auto_Feed_Output_Archive_File"
270       .strVerifyProcExists = "dbo.Auto_Feed_Verify_Tabled_Feed"
280       .strGetContactInfo = "dbo.Auto_Feed_GetContactAddressInfo"
281       .strInsertCareerBuilder = "dbo.auto_feed_generator_CareerBuilder_Jobs"
282       .strVerifyCBL = "dbo.Auto_Feed_Verify_CBL"
283       .strDeleteCareerBuilder = "dbo.Auto_Feed_Delete_Jobs_Table"
290     End With
End Sub

Private Function GetEncodesListRS() As ADODB.Recordset
        Dim adors As ADODB.Recordset
        Dim ADOCM As ADODB.Command
        
10      Set ADOCM = New ADODB.Command
20      Set adors = New ADODB.Recordset
        
30      If (Dir(UDL_PATH & MASTER_SOURCE) <> "") Then
40        Call SetConnection(MASTER_SOURCE)
          
50        With ADOCM
60          Set .ActiveConnection = adocn
70          .CommandType = adCmdStoredProc
80          .CommandText = typProcsList.strGetEncodes
'90          adors.CursorLocation = adUseClient
100         Set adors = .Execute
110         Set adors.ActiveConnection = Nothing
120       End With
          
130       Set GetEncodesListRS = adors
140     End If
        
150     Call UnsetConnection
160     Set ADOCM = Nothing
170     Set adors = Nothing
End Function

Public Function GetFileDataFromTable(ByVal intAutoFeedID As Integer, ByVal strFileName As String, ByVal intParamUsedType As Integer) As String
        Dim adors As ADODB.Recordset
        Dim ADOCM As ADODB.Command
        Dim clsReportErrs As Auto_Feed_Errors.clsAuto_Feed_Errors
        
        Const strMethod = "GetFileDataFromTable"
        
10      Set ADOCM = New ADODB.Command
20      Set adors = New ADODB.Recordset
        
30      If (Dir(UDL_PATH & MASTER_SOURCE) <> "") Then
40        Call SetConnection(MASTER_SOURCE)
          
50        With ADOCM
60          Set .ActiveConnection = adocn
70          .CommandType = adCmdStoredProc
80          .CommandText = typProcsList.strGetFileContent
            
90          .Parameters.Append .CreateParameter("@FID", adInteger, adParamInput, , intAutoFeedID)
100         .Parameters.Append .CreateParameter("@FName", adVarChar, adParamInput, 150, strFileName)
110         .Parameters.Append .CreateParameter("@Source", adVarChar, adParamInput, 50, strMachine)
            
'120         adors.CursorLocation = adUseClient
130         Set adors = .Execute
140         Set adors.ActiveConnection = Nothing
150       End With
          
160       GetFileDataFromTable = adors.Fields("FileContent").Value
170     End If
        
180     Call UnsetConnection
190     Set ADOCM = Nothing
        
200     If (adors.State = 1) Then adors.Close
210     Set adors = Nothing
End Function


Private Function ScanDescription(ByVal StringToModify As String) As String
        'Leave this if statement in just in case some programmer has a call for it somewhere else besides 'BuildJoinedRecordsetMultiSource'
10      If ((blnISXML = False) And (blnEncode = False)) Then
20        ScanDescription = StringToModify
        
30        Exit Function
40      End If
        
50      If ((blnEncode = True) And (blnISXML = False)) Then
60        ScanDescription = EncodeDescriptionChars(StringToModify)
          
70        Exit Function
80      End If
        
90      If (blnISXML = True) Then
100       If (blnEncode = True) Then StringToModify = EncodeDescriptionChars(StringToModify)
          
110       If (TestForXML(StringToModify) = True) Then
120         ScanDescription = StringToModify
130       Else
            ' TestForXML fails then we better call "EncodeDescriptionChars" first before calling "EncodeDescription"
140         If (blnEncode = False) Then StringToModify = EncodeDescriptionChars(StringToModify)
            
150         ScanDescription = EncodeDescription(StringToModify)
160       End If
170     End If
End Function

  Private Function NormalizeHTML(ByVal strText As String, ByVal strGoodTags As String) As String
          Dim REPLACE_WITH_CRLF As String
          Dim REPLACE_WITH_STR As String
          Dim REPLACE_WITH_STR2 As String
          Dim REPLACE_WITH_TAB As String
          Dim REPLACE_WITH_SPACE As String
          
10        REPLACE_WITH_CRLF = "<br>|</tr>|</p>|</li>"
20        REPLACE_WITH_STR = "<li>"
21        REPLACE_WITH_STR2 = "<li "
30        REPLACE_WITH_TAB = "</td>"
40        REPLACE_WITH_SPACE = "&nbsp;"
    
          'chr(44)=,
          'chr(124)=|
          'chr(62)=>
          'chr(60)=<
          
50        If (LenB(strGoodTags) > 0) Then
60          strGoodTags = RegExpReplace(Chr(62) & Chr(62), Chr(62), True, True, RegExpReplace(Chr(44) & Chr(60), Chr(62) & Chr(44) & Chr(60), True, True, strGoodTags)) ' Replace(strGoodTags, ",<", ">,<")
70          strGoodTags = RegExpReplace(Chr(44), Chr(124), True, True, strGoodTags)
            
80          REPLACE_WITH_CRLF = RegExpReplace(strGoodTags, "", True, True, REPLACE_WITH_CRLF)
90          REPLACE_WITH_STR = RegExpReplace(strGoodTags, "", True, True, REPLACE_WITH_STR)

            If (InStrB(1, strGoodTags, REPLACE_WITH_STR2) > 0) Then
91            REPLACE_WITH_STR2 = vbNullString   'RegExpReplace(strGoodTags, "", True, True, REPLACE_WITH_STR2)
            End If
            
100         REPLACE_WITH_TAB = RegExpReplace(strGoodTags, "", True, True, REPLACE_WITH_TAB)
            
            ' Get rid of "||"
110         If (InStrB(1, REPLACE_WITH_CRLF, Chr(124) & Chr(124)) > 0) Then REPLACE_WITH_CRLF = Replace(REPLACE_WITH_CRLF, Chr(124) & Chr(124), Chr(124))
            ' Get rid of beginning "|"
120         If (Left$(REPLACE_WITH_CRLF, 1) = Chr(124)) Then REPLACE_WITH_CRLF = Right$(REPLACE_WITH_CRLF, Len(REPLACE_WITH_CRLF) - 1)
            ' Get rid of ending "|"
130         If (Right$(REPLACE_WITH_CRLF, 1) = Chr(124)) Then REPLACE_WITH_CRLF = Left$(REPLACE_WITH_CRLF, Len(REPLACE_WITH_CRLF) - 1)
140       End If
          
      '            strConverted = RegExpReplace(, " <BR>", True, True, strTextArea)
      '            strConverted = RegExpReplace("\n", " <BR>", True, True, strConverted)
      '            strConverted = RegExpReplace("\t", " &nbsp;&nbsp;&nbsp;&nbsp;", True, True, strConverted)
      '            strConverted = RegExpReplace("\v", "", True, True, strConverted)
      '48170       strConverted = RegExpReplace("[\f\n\r\t\v]", "", True, True, strConverted)
          
150       If LenB(REPLACE_WITH_CRLF) > 0 Then strText = RegExpReplace(REPLACE_WITH_CRLF, vbNewLine, True, True, strText)
160       If LenB(REPLACE_WITH_STR) > 0 Then strText = RegExpReplace(REPLACE_WITH_STR, "* <li>", True, True, strText)
161       If LenB(REPLACE_WITH_STR2) > 0 Then strText = RegExpReplace(REPLACE_WITH_STR2, "* <li>", True, True, strText)
170       If LenB(REPLACE_WITH_TAB) > 0 Then strText = RegExpReplace(REPLACE_WITH_TAB, vbTab, True, True, strText)
          'Call ScanThroughHTML(strText, REPLACE_WITH_CRLF, strGoodTags, "\r\n")
          'Call ScanThroughHTML(strText, REPLACE_WITH_STR, strGoodTags, "*")
          'Call ScanThroughHTML(strText, REPLACE_WITH_TAB, strGoodTags, vbTab)
          
          'As per tickets #109097, #109850.
180       If (InStrB(strText, REPLACE_WITH_SPACE) > 0) Then
190         If (clsObjXmlSettings.GetXMLSettings("HTML", "ALLOW_NBSP_E_" & strOrderEmediaID, "N") = "Y") Then
200           strText = RegExpReplace(REPLACE_WITH_SPACE, Chr(32), True, True, strText)
210         End If
220       End If
          
230       NormalizeHTML = strText
  End Function
  
Private Function stripFilterHTML(ByVal strText As String, ByVal strGoodTags As String) As Boolean
        Dim blnGotTag As Boolean
        
      '49360   strText = Replace(strText, Chr(32), "")

10      strGoodTags = Replace(strGoodTags, ",", "|")
20      blnGotTag = CheckForHTMLTag(strText, strGoodTags)
        
30      stripFilterHTML = blnGotTag
End Function

Private Function CheckForHTMLTag(ByVal strTextToCheck As String, ByVal strPattern As String) As Boolean
        Dim objRegExp As RegExp
        
        'Dim spattern As String
        
        'spattern = "style=|<!DOCTYPE>|<a>|<abbr>|<acronym>|<address>|<applet>|<area>|<b>|<base>|<basefont>|<bdo>|<big>|<blockquote>|<body>|<br>|<button>|<caption>|<center>|<cite>|<code>|<col>|<colgroup>|<dd>|<del>|<dfn>|<dir>|<div>|<dl>|<dt>|<em>|<fieldset>|<font>|<form>|<frame>|<frameset>|<head>|<h1>|<h2>|<h3>|<h4>|<h5>|<h6>|<hr>|<html>|<i>|<iframe>|<img>|<input>|<ins>|<kbd>|<label><legend>|<li>|<link>|<map>|<menu>|<meta>|<noframes>|<noscript>|<object>|<ol>|<optgroup>|<option>|<p>|<param>|<pre>|<q>|<s>|<samp>|<script>|<select>|<small>|<span>|<strike>|<strong>|<style>|<sub>|<sup>|<table>|<tbody>|<td>|<textarea>|<tfoot>|<th>|<thead>|<title>|<tr>|<tt>|<u>|<ul>|<var>"
        
10      Set objRegExp = New RegExp
        
20      objRegExp.IgnoreCase = True
30      objRegExp.Pattern = strPattern
        
40      CheckForHTMLTag = objRegExp.Test(strTextToCheck)
        
50      Set objRegExp = Nothing
End Function
  
  '------------------------------------------------------------------------------
  'Name:      StripHTML
  'Programmer:
  'Date:
  'Purpose:   Removes HTML from a string
  'Inputs:      strIn
  'Outputs:   strStripped
  '------------------------------------------------------------------------------
Private Function StripHTML(ByVal strIn As String, ByVal lngRequisitionID As Long, ByVal strFieldName As String, ByVal strEmediaID As String, ByVal strUDLName As String, ByVal strParamUsed As String, ByVal strParams As String, ByVal intParamType As Integer, ByVal strCaller As String) As String
        Dim strStripped As String
        Dim strCurrentChar As String
        Dim strCurrentTag As String
        Dim blnIsBracketOpen As Boolean
        Dim lngCount As Long
        Dim strPartialString As String
        Static strGoodTags As String
        Dim lngKeepCharCount As Long
        Dim lngstrInLength As Long
        
        'chr(44)=,
        'chr(124)=|
        'chr(62)=>
        'chr(60)=<
        
        If ((InStrB(1, strIn, "w:WordDocument") > 0) And (InStrB(1, strIn, "<!--") > 0)) Then
          'Get rid of Microsoft XHTML.
          '\<![ \r\n\t]*(--([^\-]|[\r\n]|-[^\-])*--[ \r\n\t]*)\>
          strIn = RegExpReplace(strRegExNoHTMLComments, vbNullString, True, True, strIn)
        End If
        
        'If there is no html to strip off just exit the function.
10      If (InStrB(strIn, Chr(60)) = 0) Then
20        StripHTML = strIn
          
30        Exit Function
40      End If
        
        If ((InStrB(1, strIn, "=") > 0) And (blnPartialHTMLStrip = True) And (LenB(strRegExNoHTMLAttributes) > 0)) Then
          If (InStrB(strRegExExcludedAttribMedia, "," & strOrderEmediaID & ",") = 0) Then
            '  (\S+)=[""""]?((?:.(?![""""]?\s+(?:\S+)=|[>""""]))+.)[""""]?|(\S+)=[""""]?[0-9]
            'abbr|accept-charset|accesskey|action|align|alink|alt|archive|axis|background|bgcolor|border|cellpadding|cellspacing|char|charoff|charset|checked|cite|class|classid|clear|code|codebase|codetype|color|cols|colspan|compact|content|coords|data|datetime|declare|defer|dir|disabled|enctype|face|for|frame|frameborder|headers|hreflang|hspace|http-equiv|id|ismap|label|lang|language|link|longdesc|marginheight|marginwidth|maxlength|media|method|multiple|name|nohref|noresize|noshade|nowrap|object|onblur|onchange|onclick|ondblclick|onfocus|onkeydown|onkeypress|onkeyup|onload|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|onreset|onselect|onsubmit|onunload|profile|prompt|readonly|rel|rev|rows|rowspan|rules|scheme|scope|scrolling|selected|shape|span|standby|start|style|summary|tabindex|target|text|title|type|usemap|valign|value|valuetype|version|vlink|vspace
            strIn = RegExpReplace(strRegExNoHTMLAttributes, vbNullString, True, True, strIn)
            
            If (InStrB(1, strIn, "<FONT >&nbsp;</FONT>") > 0) Then
              strIn = RegExpReplace("<FONT >&nbsp;</FONT>", vbNullString, True, True, strIn)
            End If
          End If
        End If
        
50      If ((LenB(strGoodTags) = 0) And (blnPartialHTMLStrip = True)) Then
60        strGoodTags = clsObjXmlSettings.GetXMLSettings("HTML", "E_" & strOrderEmediaID & "_AllowedHTML", "", "", False)
          
70        If (Len(strGoodTags) = 0) Then strGoodTags = clsObjXmlSettings.GetXMLSettings("HTML", "AllowedHTML", "", "", False)
          '"<b,</b>,<br>,<ul,</ul>,<li,</li>,<i>,</i>,<center>,</center>,<u>,</u>,<ol>,</ol>,<li>,</li>,<blockquote>,</blockquote>,<hr>,<p>,<dl>,</dl>,<dt>,<dd>,<sub>,</sub>,<sup>,</sup>"
80        strGoodTags = Replace(Replace(strGoodTags, "&lt;", "<"), "&gt;", ">")
90      End If

100     strIn = NormalizeHTML(strIn, strGoodTags)
        
        'Initialize variables
110       strStripped = vbNullString
120       blnIsBracketOpen = False
          
          lngKeepCharCount = 1
          lngstrInLength = Len(strIn)
          
KeepLooping:
130       For lngCount = lngKeepCharCount To lngstrInLength
140         strCurrentChar = Mid(strIn, lngCount, 1)

150         Select Case strCurrentChar
            Case "<"
160             strCurrentTag = vbNullString
170             blnIsBracketOpen = True
              
180           Case ">"
190             blnIsBracketOpen = False
              
200           Case Else
210             Select Case blnIsBracketOpen
                Case True
220                 strCurrentTag = strCurrentTag & strCurrentChar

                    If ((IsNumeric(strCurrentTag)) And ((LenB(Trim(strCurrentTag)) > 0) And (LenB(Trim(strGoodTags)) > 0))) Then
                      If (InStrB(1, strGoodTags, "<" & LCase(strCurrentTag)) = 0) Then
                        strStripped = strStripped & "<" & strCurrentChar
                        blnIsBracketOpen = False
                        lngKeepCharCount = lngCount + 1
                        
                        'This should never happen but ...
                        If (lngKeepCharCount > lngstrInLength) Then
                          ' We are looping out of control.
                          Call EmailMessage("crey@hodesiq.com", "crey@hodesiq.com;jcamacho@hodesiq.com", "Autofeed System is looping out of control", vbNullString, vbNullString, "Error source: " & App.EXEName & "|clsGetDbData|StripHTML" & vbNewLine & "Autofeed System is looping out of control." & vbNewLine & "AutoFeedID: " & intAutoFeedID & vbNewLine & "RequisitionID: " & lngRequisitionID & vbNewLine & "FieldName: " & strFieldName & vbNewLine & "EmediaID: " & strEmediaID & vbNewLine & "UDLName: " & strUDLName & vbNewLine & "ParamUsed: " & strParamUsed & vbNewLine & "Params: " & strParams & vbNewLine & "ParamType: " & intParamType & vbNewLine & "Caller: " & strCaller & vbNewLine & "Date: " & Now, vbNullString)
                         
                          Err.Raise "-1", App.EXEName & "|clsGetDbData|stripHTML", "Error source: " & App.EXEName & "|clsGetDbData|StripHTML" & vbNewLine & "Autofeed System is looping out of control." & vbNewLine & "AutoFeedID: " & intAutoFeedID & vbNewLine & "RequisitionID: " & lngRequisitionID & vbNewLine & "FieldName: " & strFieldName & vbNewLine & "EmediaID: " & strEmediaID & vbNewLine & "UDLName: " & strUDLName & vbNewLine & "ParamUsed: " & strParamUsed & vbNewLine & "Params: " & strParams & vbNewLine & "ParamType: " & intParamType & vbNewLine & "Caller: " & strCaller & vbNewLine & "Date: " & Now
                        End If
                       
                        GoTo KeepLooping
                      End If
                    End If
                    
230               Case False
240                 strStripped = strStripped & strCurrentChar
250             End Select
              
260         End Select

          ' See if we are supposed to "partially" strip out the html by reading blnPartialHTMLStrip.
          ' This variable is set in the Emedia property let procedure.
270         If ((Not blnIsBracketOpen) And (blnPartialHTMLStrip) And (strCurrentTag <> "")) Then
280           strPartialString = "<" & strCurrentTag & ">"
            
290           If ((stripFilterHTML(strPartialString, strGoodTags))) Then
300             strStripped = strStripped & strPartialString
310           End If
            
320           strPartialString = vbNullString
330           strCurrentTag = vbNullString
340         End If
          
350       Next lngCount
        
          'This should never happen but ...
          If (lngKeepCharCount > lngstrInLength) Then
            ' if lngKeepCharCount > lngstrInLength then we have  a problem
            Call EmailMessage("crey@hodesiq.com", "crey@hodesiq.com;jcamacho@hodesiq.com", "lngKeepCharCount has exceeded the character count.", vbNullString, vbNullString, "Error source: " & App.EXEName & "|clsGetDbData|StripHTML" & vbNewLine & "lngKeepCharCount has exceeded the character count." & vbNewLine & "AutoFeedID: " & intAutoFeedID & vbNewLine & "RequisitionID: " & lngRequisitionID & vbNewLine & "FieldName: " & strFieldName & vbNewLine & "EmediaID: " & strEmediaID & vbNewLine & "UDLName: " & strUDLName & vbNewLine & "ParamUsed: " & strParamUsed & vbNewLine & "Params: " & strParams & vbNewLine & "ParamType: " & intParamType & vbNewLine & "Caller: " & strCaller & vbNewLine & "Date: " & Now, vbNullString)
            
            Err.Raise "-1", App.EXEName & "|clsGetDbData|stripHTML", "Error source: " & App.EXEName & "|clsGetDbData|StripHTML" & vbNewLine & "lngKeepCharCount has exceeded the character count." & vbNewLine & "AutoFeedID: " & intAutoFeedID & vbNewLine & "RequisitionID: " & lngRequisitionID & vbNewLine & "FieldName: " & strFieldName & vbNewLine & "EmediaID: " & strEmediaID & vbNewLine & "UDLName: " & strUDLName & vbNewLine & "ParamUsed: " & strParamUsed & vbNewLine & "Params: " & strParams & vbNewLine & "ParamType: " & intParamType & vbNewLine & "Caller: " & strCaller & vbNewLine & "Date: " & Now
          End If
          
          'Some jobs have bad html, for example bullets with no data in the middle.
360       strStripped = ReplaceRepeatText(strStripped, "<li></li>", vbNullString)
370       strStripped = ReplaceRepeatText(strStripped, "<p>&nbsp;</p>", vbNullString)
380       strStripped = ReplaceRepeatText(strStripped, "<p> </p>", vbNullString)
390       strStripped = ReplaceRepeatText(strStripped, "<p>" & Chr(160) & "</p>", vbNullString)
400       strStripped = ReplaceRepeatText(strStripped, "<p></p>", vbNullString)
410       strStripped = ReplaceRepeatText(strStripped, "</i></p>", vbNullString)
          
420       strStripped = ReplaceRepeatText(strStripped, "<p>" & vbNewLine & "<p>", "<p>")
430       strStripped = ReplaceRepeatText(strStripped, "</p>" & vbNewLine & "</p>", "</p>")
440       strStripped = ReplaceRepeatText(strStripped, "</p></p>", "</p>")
450       strStripped = ReplaceRepeatText(strStripped, "<p><p>", "<p>")
460       strStripped = ReplaceRepeatText(strStripped, "<br><br><br>", "<br><br>")
470       strStripped = ReplaceRepeatText(strStripped, "<p style=""margin: 0in 0in 0pt 0.25in"">" & vbNewLine & "<p style=""margin: 0in 0in 0pt 0.25in"">", vbNullString)
480       strStripped = ReplaceRepeatText(strStripped, "<p style=""margin: 0in 0in 0pt 0.25in"">&nbsp;</p>", vbNullString)
490       strStripped = ReplaceRepeatText(strStripped, "<P class=MsoNormal style=""MARGIN: 0in 0in 12pt"">", "<P>")
500       strStripped = ReplaceRepeatText(strStripped, "<P class=MsoNormal style=""MARGIN: 0in 0in 0pt"">", "<P>")
510       strStripped = ReplaceRepeatText(strStripped, "<P class=MsoNormal style=""MARGIN: 0in 0in 0pt; COLOR: #0a0100; mso-list: l0 level1 lfo1; tab-stops: list .5in"">", "<P>")
520       strStripped = ReplaceRepeatText(strStripped, "<B style=""mso-bidi-font-weight: normal"">", "<B>")
530       strStripped = ReplaceRepeatText(strStripped, "<P class=MsoNormal style=""MARGIN: 0in 0in 0pt 38.65pt; TEXT-INDENT: -0.25in; mso-list: l0 level1 lfo1; tab-stops: list 38.65pt"">", "<P>")
540       strStripped = ReplaceRepeatText(strStripped, "<UL style=""MARGIN-TOP: 0in"" type=disc>", "<UL>")
550       strStripped = ReplaceRepeatText(strStripped, "<LI class=MsoNormal style=""MARGIN: 0in 0in 0pt; COLOR: #0a0100; mso-list: l0 level1 lfo1; tab-stops: list .5in"">", "<LI>")
560       strStripped = ReplaceRepeatText(strStripped, "<LI class=MsoNormal style=""MARGIN: 0in 0in 0pt; COLOR: #0a0100; mso-list: l0 level1 lfo1; tab-stops: list 5in"">", "<LI>")
          
570       strStripped = ReplaceRepeatText(strStripped, "<ol> <BR>", "<ol>")
580       strStripped = ReplaceRepeatText(strStripped, "<ol><BR>", "<ol>")
590       strStripped = ReplaceRepeatText(strStripped, "</ol> <BR>", "</ol>")
600       strStripped = ReplaceRepeatText(strStripped, "</ol><BR>", "</ol>")
610       strStripped = ReplaceRepeatText(strStripped, "<ul> <BR>", "<ul>")
620       strStripped = ReplaceRepeatText(strStripped, "<ul><BR>", "<ul>")
630       strStripped = ReplaceRepeatText(strStripped, "</ul><BR>", "</ul>")
640       strStripped = ReplaceRepeatText(strStripped, "</ul> <BR>", "</ul>")
          
650       strStripped = ReplaceRepeatText(strStripped, "<BR> </P>", "</p>")
660       strStripped = ReplaceRepeatText(strStripped, "<BR></P>", "</p>")
670       strStripped = ReplaceRepeatText(strStripped, "<BR> <P>", "<p>")
680       strStripped = ReplaceRepeatText(strStripped, "<BR><P>", "<p>")
690       strStripped = ReplaceRepeatText(strStripped, "<p> <p>", "<p>")
700       strStripped = ReplaceRepeatText(strStripped, "<p><p>", "<p>")
701       strStripped = ReplaceRepeatText(strStripped, "dl{margin:0 0 .8em}dt{font-weight:bold}dd{margin:.4em 0 0 2em}", vbNullString)

'          If (strNoConvMediaID = "Y") Then
'701         strStripped = ReplaceRepeatText(strStripped, "<h2 class=""no-change-header-inline"" xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance"" xmlns:ftl=""http://www.taleo.net/ftl"" xmlns:htm=""http://www.w3.org/1999/xhtml"">", vbNullString)
'            strStripped = ReplaceRepeatText(strStripped, "</div>", "<br />")
'          End If
          'strStripped = ReplaceRepeatText(strStripped, "<ol>", "<ul>")
          'strStripped = ReplaceRepeatText(strStripped, "</ol>", "</ul>")
          
710       StripHTML = strStripped
        
End Function

Private Function ReplaceRepeatText(ByVal strTextToSearch As String, ByVal strTextToFind As String, ByVal strReplacement As String)
        Dim strNewText As String
        Dim lngF As Long
        
10      strNewText = RegExpReplace(strTextToFind, strReplacement, True, True, strTextToSearch)
        
20      lngF = InStrB(1, strNewText, strTextToFind, vbTextCompare)
        
30      Do While lngF > 0
40        strNewText = RegExpReplace(strTextToFind, strReplacement, True, True, strNewText)
          
50        lngF = InStrB(1, strNewText, strTextToFind, vbTextCompare)
60      Loop
        
70      ReplaceRepeatText = strNewText
End Function

Private Function StripOffEndingBrake(ByVal strDescValue As String)
        Dim strTextEnding(0 To 4) As String
        
10      strDescValue = Trim(strDescValue)
20      strTextEnding(0) = UCase(Right(strDescValue, 4))
30      strTextEnding(1) = UCase(Right(strDescValue, 4))
40      strTextEnding(2) = UCase(Right(strDescValue, 3))
50      strTextEnding(3) = UCase(Right(strDescValue, 2))
        
60      Do While strTextEnding(0) = "<BR>" Or strTextEnding(1) = "</P>" Or strTextEnding(2) = "<P>" Or strTextEnding(3) = vbNewLine
70        Select Case True
            Case strTextEnding(0) = "<BR>", strTextEnding(1) = "</P>"
80            strDescValue = Trim(Left(strDescValue, Len(strDescValue) - 4))
90          Case strTextEnding(2) = "<P>"
100           strDescValue = Trim(Left(strDescValue, Len(strDescValue) - 3))
110         Case strTextEnding(3) = vbNewLine
120           strDescValue = Trim(Left(strDescValue, Len(strDescValue) - 2))
130       End Select
          
140       strTextEnding(0) = UCase(Right(strDescValue, 4)) ' "<BR>"
150       strTextEnding(1) = UCase(Right(strDescValue, 4)) ' "</P>"
160       strTextEnding(2) = UCase(Right(strDescValue, 3)) ' "<P>"
170       strTextEnding(3) = UCase(Right(strDescValue, 2)) ' vbNewLine
180     Loop
        
190     StripOffEndingBrake = strDescValue
End Function

'Public Function GetNewGuid() As String
'  Dim GetNewGuild As String
'  Dim g As GUID
'  Dim b() As Byte
'  Dim lSize As Long
'  Dim lR As Long
'
'  Call CoCreateGuid(g)
'
'  lSize = 40
'  ReDim b(0 To (lSize * 2) - 1) As Byte
'  lR = StringFromGUID2(g, VarPtr(b(0)), lSize)
'
'  GetNewGuid = Left$(b, lR - 1)
'End Function
'
Private Sub Class_Terminate()
10      UnsetConnection

20      If (Not (RSEncode Is Nothing)) Then
30        If (RSEncode.State = 1) Then RSEncode.Close
40      End If
        
50      Set RSEncode = Nothing
End Sub


Public Sub GetMediaTrackInfo(ByVal lngReqEmediaID As Long, ByRef strApplyUrl As String, ByRef strImg As String)
        Dim adors As ADODB.Recordset
        Dim adocn As ADODB.Connection
        Dim ADOCM As ADODB.Command
        
10      Set adocn = New ADODB.Connection
20      Set adors = New ADODB.Recordset
30      Set ADOCM = New ADODB.Command
        
40      adocn.CursorLocation = adUseClient
50      adocn.Open "file name=d:\data\db\iqtrackread.udl"
        
60      With ADOCM
70        .ActiveConnection = adocn
80        .CommandType = adCmdStoredProc
90        .CommandText = "dbo.p_select_imagetag_contactHRapplyURL"
          
100       .Parameters.Append .CreateParameter("@reqemdiaID", adInteger, adParamInput, , lngReqEmediaID)
          
'110       adors.CursorLocation = adUseClient
120       Set adors = .Execute
130       Set adors.ActiveConnection = Nothing
140     End With
        
150     If adocn.State = 1 Then adocn.Close
160     Set adocn = Nothing
          
170     If (Not adors.EOF) Then
180       strApplyUrl = adors.Fields("applyURL").Value & vbNullString
190       strImg = adors.Fields("imagetag").Value & vbNullString
200     Else
210       strApplyUrl = vbNullString
220       strImg = vbNullString
230     End If
        
240     If adors.State = 1 Then adors.Close
250     Set adors = Nothing
260     Set ADOCM = Nothing
End Sub


Public Sub UpdateSub3(ByVal strSub3FeedList As String)
10      Call DeactivateSubType3(strSub3FeedList)

        Dim lngReqEmediaID As Long
        Dim intSubscriptionID As Integer
        Dim strErrorDescription As String
        Dim blnIsError As Boolean
        Dim intFeedID As Integer
        
        Dim adors As ADODB.Recordset
        Dim ADOCM As ADODB.Command
        
20      Set adors = New ADODB.Recordset
30      Set ADOCM = New ADODB.Command
        
40      Call SetConnection(MASTER_SOURCE)
        
50      With ADOCM
60        .ActiveConnection = adocn
70        .CommandType = adCmdStoredProc
80        .CommandText = "dbo.Auto_feed_component_Get_Jobs_SubType3"
          
90        .Parameters.Append .CreateParameter("@FeedList", adVarChar, adParamInput, 1000, strSub3FeedList)
          
100       Set adors = .Execute
110       Set adors.ActiveConnection = Nothing
120     End With
        
130     Call UnsetConnection
          
140     With adors
150       Do While (Not .EOF)
160         lngReqEmediaID = .Fields("reqemediaid").Value
170         intSubscriptionID = .Fields("subscriptionid").Value
180         strErrorDescription = .Fields("ErrorDescription").Value
190         blnIsError = .Fields("IsError").Value
200         intFeedID = .Fields("feedid").Value
            
210         Call UpdateSubType3Report(lngReqEmediaID, intSubscriptionID, blnIsError, intFeedID, strErrorDescription)
220         .MoveNext
230       Loop
240     End With
        
250     If adors.State = 1 Then adors.Close
        
260     Set adors = Nothing
270     Set ADOCM = Nothing

280     Set adocn = New ADODB.Connection
290     Set ADOCM = New ADODB.Command
        
300     Call SetConnection(MASTER_SOURCE)
        
310     With ADOCM
320       .ActiveConnection = adocn
330       .CommandType = adCmdStoredProc
340       .CommandText = "dbo.Auto_Feed_Component_DeleteTempSubType3Jobs_By_Feedid"
          
350       .Parameters.Append .CreateParameter("@FeedList", adVarChar, adParamInput, 1000, strSub3FeedList)
          
360       .Execute
370     End With
        
380     Call UnsetConnection
390     Set ADOCM = Nothing

End Sub

Private Sub UpdateSubType3Report(ByVal lngReqEmediaID As Long, ByVal intSubscriptionID As Integer, ByVal blnIsError As Boolean, ByVal intFeedID As Integer, ByVal strErrorDescription As String)
        Dim adocn As ADODB.Connection
        Dim ADOCM As ADODB.Command
        
10      Set adocn = New ADODB.Connection
20      Set ADOCM = New ADODB.Command
        
30      Call SetConnection(strSubType3Source, adocn)
          
40      With ADOCM
50        .ActiveConnection = adocn
60        .CommandType = adCmdStoredProc
70        .CommandText = "dbo.Auto_feed_component_UpdateSub3"
          
80        .Parameters.Append .CreateParameter("@ReqEmediaID", adInteger, adParamInput, , lngReqEmediaID)
90        .Parameters.Append .CreateParameter("@SubID", adInteger, adParamInput, , intSubscriptionID)
100       .Parameters.Append .CreateParameter("@IsError", adBoolean, adParamInput, , blnIsError)
110       .Parameters.Append .CreateParameter("@FeedID", adInteger, adParamInput, , intFeedID)
120       .Parameters.Append .CreateParameter("@ErrorDescription", adVarChar, adParamInput, 1000, Left(strErrorDescription, 1000))
          
130       .Execute
140     End With
        
150     If adocn.State = 1 Then adocn.Close
        
160     Call UnsetConnection(adocn)
170     Set ADOCM = Nothing
End Sub

Private Sub DeactivateSubType3(ByVal strFeedList As String)
        Dim adocn As ADODB.Connection
        Dim ADOCM As ADODB.Command
        
10      Set adocn = New ADODB.Connection
20      Set ADOCM = New ADODB.Command
        
30      Call SetConnection(strSubType3Source, adocn)
        
40      With ADOCM
50        .ActiveConnection = adocn
60        .CommandType = adCmdStoredProc
70        .CommandText = "dbo.Auto_Feed_component_Deactivate_SubType3"
          
80        .Parameters.Append .CreateParameter("@FeedList", adVarChar, adParamInput, 4, strFeedList)
          
90        .Execute
100     End With
        
110     Call UnsetConnection(adocn)
        
120     Set ADOCM = Nothing
End Sub

Private Function SetExcludedHorgErr() As Long
  Dim clsReportErrs As Auto_Feed_Errors.clsAuto_Feed_Errors
  Set clsReportErrs = New Auto_Feed_Errors.clsAuto_Feed_Errors
  
  SetExcludedHorgErr = clsReportErrs.GetExcludedHiringOrg
  
  Set clsReportErrs = Nothing
End Function


