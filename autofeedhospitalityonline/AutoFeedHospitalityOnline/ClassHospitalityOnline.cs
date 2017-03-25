// This is a test 03/24/2018 10:00 PM
// Second set of changes
// from local
// from vm
// from vm 2
using System;
using System.Text;
using AutoFeedData;
using AutoFeedMembers;
using System.Data;
using System.IO;
using AutoFeedErrors;
using AutoFeedStatic;
using AutoFeedFormatJobs;
using AutoFeedParams;
using AutoFeedXML;
using System.Xml;

namespace AutoFeedHospitalityOnline
{
  
  public class ClassHospitalityOnline : ClassFeedMembers
  {
        private string CLASS_NAME = System.Reflection.Assembly.GetExecutingAssembly().ToString() + "/AutoFeedHospitalityOnline.ClassHospitalityOnline";
        private string PROCEDURE_NAME = string.Empty;

        private ClassData clsData = new ClassData();

        public override void Dispose()
        {
          if (clsData != null)
          {
            clsData.Dispose();
          }

          clsData = null;
        }

        public override string ExecFeed(object objPackage)
        {
          ClassFormatParams clsPackage = new ClassFormatParams();
          clsPackage = (AutoFeedParams.ClassFormatParams)objPackage;
          objPackage = null;

          string PROCEDURE_NAME = "ExecFeed";

          //SqlDataReader drJobDescription = null;
          DataTable dt = new DataTable();
          dt = clsPackage.Data;
          //clsPackage.Guid = base.StripTheHTML(clsPackage.Guid);

          int intClientID = 0;
          int intAutoFeedID = clsPackage.AutoFeedID;

          ClassXMLSettings clsXML = new ClassXMLSettings();
          ClassMembers clsMems = new ClassMembers();
          ClassFormatJobsParams clsParams = new ClassFormatJobsParams();
          clsParams.IsTest = (clsPackage.ParamUsed.Contains("TEST") && (ClassStaticData.Debug == true));
          ClassFormatJobs clsFormat = new ClassFormatJobs(clsPackage.EmediaID, clsParams);
          clsFormat.PropProcessGuid = clsPackage.Guid;
          clsParams = null;
          StringBuilder sb = new StringBuilder();
          StringBuilder sbJobDescription = new StringBuilder();

          const string SECTION_NAME = "HOSPITALITY_ONLINE";

          int intJobAction = 0;
          int intReqEmediaID = 0;
          int intReqID = 0;

          string strHeader = string.Empty;
          string strRequirements = string.Empty;
          string strDuties = string.Empty;
          string strFooter = string.Empty;
          string strChildMedia = string.Empty;

          string strApplyURL = string.Empty;
          string strImgTrack = string.Empty;
          string strHistoricFileName = string.Empty;
          string strJobAction = string.Empty;
          string strPostMethod = string.Empty;
          string strAppendingURL = string.Empty;
          string strKeepDeliveryAddress = string.Empty;
          string strXMLEncoding = string.Empty;
          string strExternalSourceID = string.Empty;
          string strCompensation = string.Empty;
          string strContactEmail = string.Empty;
          string strAPIUser = string.Empty;
          string strAPIKey = string.Empty;
          string strTitle = string.Empty;
          string strPostingParam = string.Empty;

          bool blnIsScraped = false;

          int intRows = 0;
          int intAdds = 0;
          int intUpdates = 0;
          int intDeletes = 0;
          int intJobCount = 0;

          try
          {
            XmlDocument doc = new XmlDocument();
            XmlNode docNode = doc.CreateXmlDeclaration("1.0", "UTF-8", null);

            doc.AppendChild(docNode);
            XmlNode HodesNode = doc.CreateElement("HODES_XML_ENVELOPE");
            doc.AppendChild(HodesNode);

            while (intRows < dt.Rows.Count) //for (int intRows = 0; intRows < dt.Rows.Count; intRows += 1)
            {
              intJobCount += 1;
              intReqEmediaID = Convert.ToInt32(dt.Rows[intRows]["req_emediaid"]);
              intReqID = Convert.ToInt32(dt.Rows[intRows]["requisition_id"]);
              intClientID = Convert.ToInt32(dt.Rows[intRows]["ClientID"]);
              strAPIUser = clsXML.GetXMLSettings(SECTION_NAME, "API_USER_C_" + intClientID.ToString(), string.Empty);
              strAPIKey = clsXML.GetXMLSettings(SECTION_NAME, "API_KEY_C_" + intClientID.ToString(), string.Empty);
              
              if (clsMems.IsNumeric(dt.Rows[intRows]["low_base_compensation"].ToString()) && clsMems.IsNumeric(dt.Rows[intRows]["high_base_compensation"].ToString()))
                strCompensation = dt.Rows[intRows]["low_base_compensation"].ToString() + " - " + dt.Rows[intRows]["high_base_compensation"].ToString();
              else
                strCompensation = string.Empty;

              if (strKeepDeliveryAddress.Length == 0)
              {
                strKeepDeliveryAddress = clsPackage.DeliveryAddress;
              }

              clsPackage.DeliveryAddress = string.Empty;

              switch (dt.Rows[intRows]["JobAction"].ToString())
              {
                case "A":
                  //strAppendingURL = @"/v1/jobs";
                  clsPackage.DeliveryAddress = strKeepDeliveryAddress; // + strAppendingURL;
                  strPostMethod = "POST";
                  strJobAction = "ADD";
                  strHistoricFileName = clsPackage.FileName;
                  intJobAction = (int)ClassStaticData.FileMode.NormalFileMode;

                  intAdds += 1;
                  break;
                case "U":
                  //strAppendingURL = @"/v1/jobs/partner-job-id=" + intReqEmediaID.ToString();
                  clsPackage.DeliveryAddress = strKeepDeliveryAddress; // + strAppendingURL;
                  strPostMethod = "POST";
                  strJobAction = "EDIT"; // This format uses EDIT instead of UPDATE.
                  strHistoricFileName = clsPackage.FileName;
                  intJobAction = (int)ClassStaticData.FileMode.UpdateFileMode;

                  intUpdates += 1;
                  break;
                case "D":
                  //strAppendingURL = @"/v1/jobs/partner-job-id=" + intReqEmediaID.ToString();
                  clsPackage.DeliveryAddress = strKeepDeliveryAddress; // + strAppendingURL;
                  strPostMethod = "POST";
                  strJobAction = "DELETE";
                  strHistoricFileName = clsPackage.FileName;
                  intJobAction = (int)ClassStaticData.FileMode.DeleteFileMode;

                  intDeletes += 1;
                  break;
              }

              if (strJobAction == "ADD")
              {
                /*************************************************************************/
                //Always get job description and tracking information first.
                /*************************************************************************/
                DataTable dtJobDescription = clsData.GetDescriptionDT(intReqID, intReqEmediaID);
                DataRow drJobDescription = dtJobDescription.Rows[0];
                
                //drJobDescription.Read();
                strChildMedia = drJobDescription["ChildMedia"].ToString();
                blnIsScraped = Convert.ToBoolean(drJobDescription["IsScraped"]);
                strTitle = clsFormat.GetDynamicRsFieldValue(dt.Rows[intRows]["title"].ToString(), dt.Rows[intRows]["title"].GetType().ToString(), "TITLE", 59, intReqID, clsPackage.EmediaID, ClassStaticData.MASTER_SOURCE, clsPackage.ParamUsed, CLASS_NAME, blnIsScraped);
                strHeader = clsFormat.GetDynamicRsFieldValue(drJobDescription["header"].ToString(), drJobDescription["header"].GetType().ToString(), "HEADER", 59, intReqID, clsPackage.EmediaID, ClassStaticData.MASTER_SOURCE, clsPackage.ParamUsed, CLASS_NAME, blnIsScraped);
                strRequirements = clsFormat.GetDynamicRsFieldValue(drJobDescription["requirements"].ToString(), drJobDescription["requirements"].GetType().ToString(), "REQUIREMENTS", 59, intReqID, clsPackage.EmediaID, ClassStaticData.MASTER_SOURCE, clsPackage.ParamUsed, CLASS_NAME, blnIsScraped);
                strDuties = clsFormat.GetDynamicRsFieldValue(drJobDescription["duties"].ToString(), drJobDescription["duties"].GetType().ToString(), "DUTIES", 59, intReqID, clsPackage.EmediaID, ClassStaticData.MASTER_SOURCE, clsPackage.ParamUsed, CLASS_NAME, blnIsScraped);
                strFooter = clsFormat.GetDynamicRsFieldValue(drJobDescription["footer"].ToString(), drJobDescription["footer"].GetType().ToString(), "FOOTER", 59, intReqID, clsPackage.EmediaID, ClassStaticData.MASTER_SOURCE, clsPackage.ParamUsed, CLASS_NAME, blnIsScraped);
                //drJobDescription.Close();
                dtJobDescription.Dispose();
                dtJobDescription = null;
                drJobDescription = null;

                strApplyURL = clsMems.GetDirectURL(intReqEmediaID.ToString(), Convert.ToByte(dt.Rows[intRows]["apply_statement_indicator"]), dt.Rows[intRows]["url_address"].ToString(), false, clsPackage.EmediaID);
                strImgTrack = string.Empty;
                clsFormat.GetMediaTracking(intReqEmediaID, Convert.ToBoolean(dt.Rows[intRows]["Provisioned"]), Convert.ToBoolean(dt.Rows[intRows]["MediaTracking"]), ref strApplyURL, ref strImgTrack);
                /*************************************************************************/

                sbJobDescription.Append(clsFormat.ParagraphFields(strHeader, strRequirements, strDuties, strFooter) + strImgTrack);

              }

              XmlNode JobNumber = doc.CreateElement("Job_" + intJobCount.ToString());
              HodesNode.AppendChild(JobNumber);

              XmlNode ReqEmID = doc.CreateElement("ReqEmediaID");
              ReqEmID.AppendChild(doc.CreateTextNode(intReqEmediaID.ToString()));
              JobNumber.AppendChild(ReqEmID);

              XmlNode ReqID = doc.CreateElement("ReqID");
              ReqID.AppendChild(doc.CreateTextNode(intReqID.ToString()));
              JobNumber.AppendChild(ReqID);

              XmlNode JobAction = doc.CreateElement("JobAction");
              JobAction.AppendChild(doc.CreateTextNode(strJobAction));
              JobNumber.AppendChild(JobAction);

              XmlNode PostMethod = doc.CreateElement("PostMethod");
              PostMethod.AppendChild(doc.CreateTextNode(strPostMethod));
              JobNumber.AppendChild(PostMethod);

              XmlNode AppendingURL = doc.CreateElement("AppendingURL");
              AppendingURL.AppendChild(doc.CreateCDataSection(strAppendingURL));
              JobNumber.AppendChild(AppendingURL);

              XmlNode PostingParam = doc.CreateElement("PostingParam");
              PostingParam.AppendChild(doc.CreateTextNode("job="));
              JobNumber.AppendChild(PostingParam);

              XmlNode ActualJob = doc.CreateElement("ActualJob");
              JobNumber.AppendChild(ActualJob);

              XmlNode jobNode = doc.CreateElement("job");
              ActualJob.AppendChild(jobNode);

              XmlNode api_user = doc.CreateElement("api_user");
              api_user.AppendChild(doc.CreateTextNode(strAPIUser));
              jobNode.AppendChild(api_user);

              XmlNode api_key = doc.CreateElement("api_key");
              api_key.AppendChild(doc.CreateTextNode(strAPIKey));
              jobNode.AppendChild(api_key);

              XmlNode id = doc.CreateElement("id");
              id.AppendChild(doc.CreateTextNode(intReqEmediaID.ToString()));
              jobNode.AppendChild(id);

              XmlNode title = doc.CreateElement("title");
              title.AppendChild(doc.CreateCDataSection(dt.Rows[intRows]["title"].ToString()));
              jobNode.AppendChild(title);

              XmlNode action = doc.CreateElement("action");
              action.AppendChild(doc.CreateTextNode(strJobAction));
              jobNode.AppendChild(action);

              XmlNode categories = doc.CreateElement("categories");
              categories.AppendChild(doc.CreateCDataSection(dt.Rows[intRows]["function_map"].ToString()));
              jobNode.AppendChild(categories);

              XmlNode ismanagement = doc.CreateElement("is_management");
              ismanagement.AppendChild(doc.CreateTextNode(dt.Rows[intRows]["is_management"].ToString()));
              jobNode.AppendChild(ismanagement);

              XmlNode compensation = doc.CreateElement("compensation_range");
              compensation.AppendChild(doc.CreateCDataSection(strCompensation));
              jobNode.AppendChild(compensation);

              XmlNode descriptionNode = doc.CreateElement("description");
              descriptionNode.AppendChild(doc.CreateCDataSection(sbJobDescription.ToString()));
              jobNode.AppendChild(descriptionNode);

              XmlNode requirementsNode = doc.CreateElement("requirements");
              requirementsNode.AppendChild(doc.CreateCDataSection(string.Empty));
              jobNode.AppendChild(requirementsNode);

              XmlNode applyUrlNode = doc.CreateElement("apply_url");
              applyUrlNode.AppendChild(doc.CreateCDataSection(strApplyURL));
              jobNode.AppendChild(applyUrlNode);

              XmlNode locationNode = doc.CreateElement("location");

              XmlNode locationid = doc.CreateElement("id");
              locationid.AppendChild(doc.CreateTextNode(dt.Rows[intRows]["location_id"].ToString()));
              locationNode.AppendChild(locationid);

              XmlNode namenode = doc.CreateElement("name");
              namenode.AppendChild(doc.CreateCDataSection(dt.Rows[intRows]["hotel_name"].ToString()));
              locationNode.AppendChild(namenode);
                 
              XmlNode addressnode = doc.CreateElement("address");
              addressnode.AppendChild(doc.CreateCDataSection(dt.Rows[intRows]["hotel_address"].ToString()));
              locationNode.AppendChild(addressnode);
                
              XmlNode citynode = doc.CreateElement("city");
              citynode.AppendChild(doc.CreateCDataSection(dt.Rows[intRows]["hotel_city"].ToString()));
              locationNode.AppendChild(citynode);
                
              XmlNode statenode = doc.CreateElement("state_or_province");
              statenode.AppendChild(doc.CreateCDataSection(dt.Rows[intRows]["hotel_state"].ToString()));
              locationNode.AppendChild(statenode);

              XmlNode zipnode = doc.CreateElement("postal_code");
              zipnode.AppendChild(doc.CreateCDataSection(dt.Rows[intRows]["hotel_zip"].ToString()));
              locationNode.AppendChild(zipnode);

              XmlNode countrynode = doc.CreateElement("country_id");
              countrynode.AppendChild(doc.CreateCDataSection(dt.Rows[intRows]["hotel_country"].ToString()));
              locationNode.AppendChild(countrynode);

              XmlNode phonenode = doc.CreateElement("telephone");
              phonenode.AppendChild(doc.CreateCDataSection(string.Empty));
              locationNode.AppendChild(phonenode);

              XmlNode brand_id = doc.CreateElement("brand_id");
              brand_id.AppendChild(doc.CreateCDataSection(dt.Rows[intRows]["brand_id"].ToString()));
              locationNode.AppendChild(brand_id);

              XmlNode url = doc.CreateElement("url");
              url.AppendChild(doc.CreateCDataSection(string.Empty));
              locationNode.AppendChild(url);

              XmlNode hotel_profile = doc.CreateElement("description");
              hotel_profile.AppendChild(doc.CreateCDataSection(string.Empty));
              locationNode.AppendChild(hotel_profile);

              jobNode.AppendChild(locationNode);
              
              XmlNode userNode = doc.CreateElement("user");

              XmlNode useremail = doc.CreateElement("email");
              useremail.AppendChild(doc.CreateTextNode(dt.Rows[intRows]["user_email"].ToString()));
              userNode.AppendChild(useremail);

              XmlNode firstnamenode = doc.CreateElement("first_name");
              firstnamenode.AppendChild(doc.CreateCDataSection(dt.Rows[intRows]["user_first"].ToString()));
              userNode.AppendChild(firstnamenode);
                 
              XmlNode lastnamenode = doc.CreateElement("last_name");
              lastnamenode.AppendChild(doc.CreateCDataSection(dt.Rows[intRows]["user_last"].ToString()));
              userNode.AppendChild(lastnamenode);
                
              XmlNode usertitle = doc.CreateElement("title");
              usertitle.AppendChild(doc.CreateCDataSection(string.Empty));
              userNode.AppendChild(usertitle);

              XmlNode usertelephone = doc.CreateElement("telephone");
              usertelephone.AppendChild(doc.CreateCDataSection(string.Empty));
              userNode.AppendChild(usertelephone);

              jobNode.AppendChild(userNode);

              if (clsData.SetProcessedData(intReqEmediaID, clsPackage.Guid, intAutoFeedID, intJobAction, strHistoricFileName, clsPackage.ParamUsed, clsPackage.UserID, clsPackage.OverrideAddress, clsPackage.RunType, clsPackage.EmediaID, intClientID, clsPackage.SubID, clsPackage.Machine, clsPackage.HodesFeed, clsPackage.TotalJobCount, clsPackage.UsesSlotQty, clsPackage.DeliveryAddress, intAdds, intUpdates, intDeletes, intJobCount, strChildMedia, clsPackage.MultiFile) > 0)
              {
                intRows += 1;
              }
              else
              {
                ClassStaticData.EmailMessage(ClassStaticData.GetFromEmail, ClassStaticData.GetDevEmail, string.Empty, ClassStaticData.Msg_UnexpectedError + "|clsData.SetProcessedData returned 0.", "ProcessGuid: " + clsPackage.Guid + "\r\nAutoFeedID: " + clsPackage.AutoFeedID.ToString() + "\r\nFileName: " + clsPackage.FileName + "\r\nParamUsed: " + clsPackage.ParamUsed + "\r\nUserID: " + clsPackage.UserID.ToString() + "\r\nOverridAddress: " + clsPackage.OverrideAddress + "\r\nRunType: " + clsPackage.RunType.ToString() + "\r\nEmediaID: " + clsPackage.EmediaID + "\r\nSubID: " + clsPackage.SubID.ToString() + "\r\nMachine: " + clsPackage.Machine + "\r\nHodesFeed: " + clsPackage.HodesFeed.ToString() + "\r\nTotalJobCount: " + clsPackage.TotalJobCount.ToString() + "\r\nSource: " + CLASS_NAME + "\r\nProcedure: " + PROCEDURE_NAME + "\r\nclsData.SetProcessedData returned 0.\r\n\r\nErrorTime: " + System.DateTime.Now.ToLongTimeString());

                string strErrorSource = "Error source: " + CLASS_NAME;
                string strErrorMessage = "clsData.SetProcessedData returned 0.|ORIGINAL_SOURCE" + CLASS_NAME + " --> Error occurred in " + CLASS_NAME + "." + PROCEDURE_NAME + "|REQEMEDIAID" + intReqEmediaID.ToString() + "|ERRORINFOError reported from: " + CLASS_NAME + "." + PROCEDURE_NAME + "|CLASSNAME" + CLASS_NAME + "|FEEDID" + clsPackage.AutoFeedID.ToString() + "|EMEDIAID" + clsPackage.EmediaID + "|ERRORLEVEL4|WRITESTOPLIGHT1|FILENAME" + clsPackage.FileName + "|PARAMUSED" + clsPackage.ParamUsed + "|PARAMTYPE67|PROCESSGUID" + clsPackage.Guid;
                Exception ex = new Exception(strErrorMessage);
                ex.Source = strErrorSource;

                throw ex;
              }
            } // for (int intRows = 0; intRows < dt.Rows.Count; intRows += 1)

            StringWriter sw = null;

            string strRetVal = string.Empty;

            if (intJobCount > 0)
            {
              sw = new StringWriter();
              XmlTextWriter xw = new XmlTextWriter(sw);
              doc.WriteTo(xw);

              if (clsData.UpdateXMLFeed(clsPackage.Guid, clsPackage.AutoFeedID, clsMems.GetUTF8ByteData(sw.ToString()), 0) > 0)
                strRetVal = "true";
              else
                strRetVal = "false";
            }
            else
            {
              strRetVal = "false";
            }

            sw.Dispose();
            sw = null;

            return strRetVal;
          }
          catch (Exception ex)
          {
            ex.Data.Add("ORIGINAL_SOURCE", ex.Source + " --> Error occurred in " + CLASS_NAME + "." + PROCEDURE_NAME);
            ex.Data.Add("CLASSNAME", ex.TargetSite.DeclaringType.ToString());
            ex.Data.Add("ERRORINFO", "Error reported from: " + ex.TargetSite.DeclaringType.ToString() + "|" + ex.TargetSite.ToString());
            ex.Data.Add("REQEMEDIAID", intReqEmediaID.ToString()); // converted to string to avoid boxing.
            ex.Data.Add("REQUISITIONID", intReqID.ToString()); // converted to string to avoid boxing.
            ex.Data.Add("CLIENTID", intClientID.ToString()); // converted to string to avoid boxing.
            ex.Data.Add("SUBID", clsPackage.SubID.ToString()); // converted to string to avoid boxing.
            ex.Data.Add("FEEDID", clsPackage.AutoFeedID.ToString()); // converted to string to avoid boxing.
            ex.Data.Add("EMEDIAID", clsPackage.EmediaID);
            ex.Data.Add("ERRORLEVEL", "4"); // converted to string to avoid boxing.
            ex.Data.Add("WRITESTOPLIGHT", "1"); // converted to string to avoid boxing.
            ex.Data.Add("FILENAME", clsPackage.FileName);
            ex.Data.Add("PARAMUSED", clsPackage.ParamUsed);
            ex.Data.Add("PARAMTYPE", "58"); // converted to string to avoid boxing.
            ex.Data.Add("PROCESSGUID", clsPackage.Guid);

            ClassErrors clsErr = new ClassErrors(ex.Message, ex, ex.Source, ex.Data);

            try
            {
              clsData.ReportError(clsErr.ErrorInfo, clsErr.Source, clsErr.Message, clsErr.LineNumber, clsErr.AfErrorNumber, clsErr.ErrorNumber, clsErr.ConnectionString, clsErr.Filename, clsErr.AutoFeedID, clsErr.EmediaID, clsErr.CIDList, clsErr.DeliveryType, clsErr.EmailAddress, clsErr.FTPAddress, clsErr.URLAddress, clsErr.LocalCopyAdddress, clsErr.ParamUsed, clsErr.RequisitionID, clsErr.ReqEmediaID, ClassStaticData.MachineName, clsErr.StoredProcedure, clsErr.ParamType, clsErr.ErrorLevel, clsErr.WriteStopLight, string.Empty, clsErr.UsesSubID, clsErr.SubID, clsErr.ProcessGuid, clsErr.GetStackTrace, clsErr.GetStackFrames, clsErr.InnerExceptionMessage, clsErr.ExceptionType, clsErr.ColumnNumber);
            }
            catch (Exception ex2)
            {
              ClassStaticData.EmailMessage(ClassStaticData.GetFromEmail, ClassStaticData.GetDevEmail, string.Empty, ClassStaticData.Msg_UnexpectedError, "Original error follows:\r\n\r\nFrom: " + System.Reflection.Assembly.GetExecutingAssembly().ToString() + "\r\nConnectionString: " + ClassStaticData.MASTER_SOURCE + "\r\n\r\n" + "Error Message: " + ex.Message + "\r\n\r\n" + ex.Source + "\r\n\r\nNew error follows:\r\n" + ex2.Message + "\r\n" + ex2.Source + "\r\nNew error inner exception: " + ex2.InnerException + "\r\n" + "\r\n\r\nAdditional information follows:\r\nAutoFeedID: " + clsErr.AutoFeedID.ToString() + "\r\n\r\nEmediaID: " + clsErr.EmediaID + "\r\n\r\nCIDList: " + clsErr.CIDList + "\r\n\r\nErrorTime: " + System.DateTime.Now.ToLongTimeString());
            }
            return "false";
          }
          finally
          {
            if (clsFormat != null)
            {
              clsFormat.Dispose();
            }

            clsFormat = null;

            if (clsXML != null)
            {
              clsXML.Dispose();
            }

            clsXML = null;

            if (clsData != null)
            {
              clsData.Dispose();
            }

            clsData = null;

            dt.Dispose();
            dt = null;
          }
        } // public override string ExecFeed(object objPackage)
  }
}