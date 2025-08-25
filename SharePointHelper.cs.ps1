using System;
using System.Linq;
using System.Text;
using System.Xml;
using SPAttachmentTab.SPCopy;
using SPAttachmentTab.SPDws;
using SPAttachmentTab.SPLists;
using SPAttachmentTab.SPMeetings;
using SPAttachmentTab.SPObjects;
using SPAttachmentTab.SPSiteData;
using SPAttachmentTab.SPWebs;
using System.Web;
using System.Web.UI;
using System.Net;

namespace SPAttachmentTab
{
    internal class SharePointHelper
    {

        public Page _mypage = null;

        #region private member variables
        private readonly String IndexListName = "Entity Library Index";
        private const String IndexContentTypeName = "Entity Library Location";
        private const String CustomDocContentTypeName = "Entity Attachment";
        private readonly Int32 CustomListTemplateId = 100;
        private readonly Int32 DocLibListTemplateId = 101;
        private readonly String ItemContentTypeCode = "0x01";
        private readonly String DocumentContentTypeCode = "0x0101";

        private readonly String DefaultSiteTemplateIdentifier = "STS#1";
        private readonly UInt32 _locId = 1033;

        private readonly String ListsServiceEndpoint = "/_vti_bin/Lists.asmx";
        private readonly String MeetingsServiceEndpoint = "/_vti_bin/Meetings.asmx";
        private readonly String WebsServiceEndpoint = "/_vti_bin/Webs.asmx";
        private readonly String SiteDataServiceEndpoint = "/_vti_bin/SiteData.asmx";
        private readonly String DWSServiceEndpoint = "/_vti_bin/DWS.asmx";
        private readonly String CopyServiceEndpoint = "/_vti_bin/Copy.asmx";
        #endregion

        #region Web Service Endpoint manipulation methods
        private String PrepareSiteUrl(String url)
        {
            if (url == null) { return String.Empty; }
            if (url.EndsWith(@"/")) { return url.Substring(0, url.Length - 1); }
            if (!url.StartsWith("http://") && !url.StartsWith("https://"))
            {
                url = "http://" + url;
            }
            return url;
        }

        private String GetListsServiceUrl(String siteUrl)
        {
            return PrepareSiteUrl(siteUrl) + ListsServiceEndpoint;
        }

        private String GetMeetingsServiceUrl(String siteUrl)
        {
            return PrepareSiteUrl(siteUrl) + MeetingsServiceEndpoint;
        }

        private String GetWebsServiceUrl(String siteUrl)
        {
            return PrepareSiteUrl(siteUrl) + WebsServiceEndpoint;
        }

        private String GetSiteDataServiceUrl(String siteUrl)
        {
            return PrepareSiteUrl(siteUrl) + SiteDataServiceEndpoint;
        }

        private String GetDWSServiceUrl(String siteUrl)
        {
            return PrepareSiteUrl(siteUrl) + DWSServiceEndpoint;
        }

        private String GetCopyServiceUrl(String siteUrl)
        {
            return PrepareSiteUrl(siteUrl) + CopyServiceEndpoint;
        }
        #endregion

        #region Start Here!!!!!: Create Library For Entity Method, Starting Point
        internal void CreateLibraryForEntity(SPSettings settings, String listName)
        {
            if (!String.IsNullOrEmpty(settings.AliasPrefix))
            {
                listName = settings.AliasPrefix + listName;
            }

            LoggingWrapper.DebugMessage("ListName: " + listName);
            LoggingWrapper.DebugMessage("PrepSites");
            PrepareSiteForEntityLibraries(settings);
            LoggingWrapper.DebugMessage("PrepSites - Done");
            String destSiteLoc = DetermineListDestination(settings);
            CreateIndexRecordForThisEntity(settings.SiteUrl, destSiteLoc, listName);
            CreateDocLibraryOnSite(settings, destSiteLoc, listName);
        }
        #endregion

        #region Get Folders, Files, Details about Library Items
        internal void GetFilesInFolder(string siteUrl, string folderName, ref DocLibItemCollection items)
        {
            if (!siteUrl.EndsWith("/")) { siteUrl += "/"; }

            string libraryName = folderName;
            if (folderName.Contains("/"))
            {
                // we are looking at a library sub-folder.  library name is the first segment of this path
                libraryName = libraryName.Substring(0, libraryName.IndexOf("/"));
            }

            //List WebService 
            SiteData sitedataWs = new SiteData();
            string status = string.Empty;
            sitedataWs.Url = GetSiteDataServiceUrl(siteUrl);
            sitedataWs.Credentials = SPSettingsManager.GetCredentialsFromConfig();

            _sFPUrl[] docLibItems;
            //call method
            sitedataWs.EnumerateFolder(folderName, out docLibItems);
            //check for data
            if (docLibItems == null) { return; }

            var filteredItems = from libItem in docLibItems
                                where !libItem.IsFolder && !libItem.Url.Contains("Forms")
                                select libItem;

            foreach (var listItem in filteredItems)
            {
                string docPath = listItem.Url;
                string docName = docPath.Substring(docPath.LastIndexOf("/") + 1);

                DocLibItem item = new DocLibItem();
                
                //store the virtual path (***used for delete operation***)
                item.VirtualPath = docPath;
                //store the actual file path
                item.AbsolutePath = siteUrl + docPath;
                item.ItemType = DocLibItemTypes.Document;
                PopulateMetadataForDocument(siteUrl, libraryName, ref item);
                items.Add(item);
                //recursive call
                
            }
            items.Sort();
        }

        private void PopulateMetadataForDocument(string siteUrl, string libraryName, ref DocLibItem item)
        {
            // set defaults
            item.Title = item.VirtualPath;
            item.DocumentType = String.Empty;

            string filePath = item.AbsolutePath;

            try 
            {
                using (Lists listsWs = new Lists())
                {
                    listsWs.Credentials = SPSettingsManager.GetCredentialsFromConfig();
                    listsWs.Url = GetListsServiceUrl(siteUrl);
                    string rootWebUrl = GetRootWebUrl(siteUrl);
                    string virtualPath = filePath.Replace(rootWebUrl, String.Empty);

                    XmlDocument xmlDoc = new XmlDocument();
                    XmlNode query = xmlDoc.CreateNode(XmlNodeType.Element, "Query", "");
                    query.InnerXml = @"<Where><Eq><FieldRef Name='FileRef' /><Value Type='Text'>" + virtualPath + @"</Value></Eq></Where>";

                    XmlNode queryOptions = xmlDoc.CreateNode(XmlNodeType.Element, "QueryOptions", "");
                    queryOptions.InnerXml = @"<IncludeMandatoryColumns>True</IncludeMandatoryColumns><ViewAttributes Scope='Recursive' />";
                    //get ListItem ID
                    XmlNode viewFieldsNode = xmlDoc.CreateNode(XmlNodeType.Element, "ViewFields", "");
                    viewFieldsNode.InnerXml = "<FieldRef Name='ID' /><FieldRef Name='Title' /><FieldRef Name='DocumentCategory' />";

                    XmlNode itemsNode = listsWs.GetListItems(libraryName, null, query,
                                                          viewFieldsNode, int.MaxValue.ToString(), queryOptions, null);

                    string listItemId = String.Empty;
                    foreach (XmlNode itemNode in itemsNode.ChildNodes)
                    {
                        foreach (XmlNode itemNode2 in itemNode.ChildNodes)
                        {
                            if (itemNode2.Attributes != null)
                            {
                                XmlAttribute titleAttr = itemNode2.Attributes["ows_Title"];
                                XmlAttribute docCategoryAttr = itemNode2.Attributes["ows_DocumentCategory"];
                                if (titleAttr != null)
                                {
                                    item.Title = titleAttr.InnerXml;
                                }
                                if (docCategoryAttr != null)
                                {
                                    item.DocumentType = docCategoryAttr.InnerXml;
                                }
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                string status = ex.StackTrace.ToString();
                LoggingWrapper.ReportError(ex);
            }
        }

        internal void GetFolders(string siteUrl, string folderUrl, ref DocLibItemCollection items)
        {
            if (!siteUrl.EndsWith("/")) { siteUrl += "/"; }

            //List WebService 
            SiteData sitedataWs = new SiteData();
            string status = string.Empty;
            sitedataWs.Url = GetSiteDataServiceUrl(siteUrl);
            sitedataWs.Credentials = SPSettingsManager.GetCredentialsFromConfig();

            _sFPUrl[] docLibItems;
            //call method
            sitedataWs.EnumerateFolder(folderUrl, out docLibItems);
            //check for data
            if (docLibItems == null) { return; }

            var filteredItems = from libItem in docLibItems
                                where libItem.IsFolder && !libItem.Url.Contains("Forms")
                                select libItem;

            foreach (var listItem in filteredItems)
            {
                string folderPath = listItem.Url;
                string folderName = folderPath.Substring(folderPath.LastIndexOf("/") + 1);

                DocLibItem item = new DocLibItem();
                item.Title = folderName;
                //store the virtual path (***used for delete operation***)
                item.VirtualPath = folderPath;
                //store the actual file path
                item.AbsolutePath = siteUrl + folderPath;
                item.ItemType = DocLibItemTypes.Folder;

                string[] pathFragments = folderPath.Split('/');
                item.ContainerName = (pathFragments.Length >= 2) ? pathFragments[pathFragments.Length - 2] : String.Empty; 
                //add to list
                items.Add(item);
                //recursive call
                GetFolders(siteUrl, folderPath, ref items);
            }

            items.Sort();
        }
        #endregion

        #region Site Existence and Creation Methods
        private String CreateSubSite(SPSettings settings, String newSubSiteName)
        {
            using (Meetings mtgs = new Meetings())
            {
                mtgs.Url = GetMeetingsServiceUrl(settings.SiteUrl);
                mtgs.Credentials = SPSettingsManager.GetCredentialsFromConfig();
                XmlNode node = mtgs.CreateWorkspace(newSubSiteName, DefaultSiteTemplateIdentifier, _locId, new TimeZoneInf());
            }

            String baseUrl = settings.SiteUrl;
            if (!baseUrl.EndsWith("/")) { baseUrl += "/"; }
            baseUrl += newSubSiteName;
            return baseUrl;
        }

        internal Boolean SiteExists(String url)
        {
            try
            {
                using (Lists listWs = new Lists())
                {
                    listWs.Url = GetListsServiceUrl(url);
                    listWs.Credentials = SPSettingsManager.GetCredentialsFromConfig();
                    listWs.Discover();
                }
                return true;
            }
            catch (Exception ex)
            {
                LoggingWrapper.ReportError(ex);
                return false;
            }
        }
        #endregion

        #region Site Content Limiting and Provisioning methods (and Helpers)
        // from a given url, determine the url of the site collections root.
        private string GetRootWebUrl(string siteUrl)
        {
            String rootUrl = siteUrl;
            
            using (SiteData sdWs = new SiteData())
            {
                sdWs.Url = GetSiteDataServiceUrl(siteUrl);
                sdWs.Credentials = SPSettingsManager.GetCredentialsFromConfig();

                _sSiteMetadata siteMetadata;
                _sWebWithTime[] webInfo;
                String users;
                String sGroups;
                String[] vGroups;

                uint response = sdWs.GetSite(out siteMetadata, out webInfo, out users, out sGroups, out vGroups);

                rootUrl = webInfo[0].Url;
                if (rootUrl.EndsWith("/")) { rootUrl = rootUrl.Substring(0, rootUrl.Length - 1); }
                string[] urlParts = rootUrl.Split(new char[] { '/' }, StringSplitOptions.None);
                if (urlParts.Length > 3)
                {
                    string[] shortUrlParts = new string[3];
                    for (int x = 0; x < 3; x++) { shortUrlParts[x] = urlParts[x]; }
                    rootUrl = String.Join("/", shortUrlParts);
                }
                if (!rootUrl.EndsWith("/")) { rootUrl += "/"; }
            }
            return rootUrl;
        }
        
        // determine which provisioned subsite should contain our new List
        private String DetermineListDestination(SPSettings settings)
        {
            String topUrl = settings.SiteUrl;
            LoggingWrapper.DebugMessage("TopUrl: " + topUrl);
            String groupUrl = String.Empty;
            using (SiteData sdWs = new SiteData())
            {
                sdWs.Url = GetSiteDataServiceUrl(topUrl);
                LoggingWrapper.DebugMessage("ServiceUrl: " + sdWs.Url);
                var cred = (NetworkCredential)SPSettingsManager.GetCredentialsFromConfig();
                sdWs.Credentials = cred;
                LoggingWrapper.DebugMessage("User: " + cred.UserName);

                _sSiteMetadata siteMetadata;
                _sWebWithTime[] webInfo;
                String users;
                String sGroups;
                String[] vGroups;

                uint response = sdWs.GetSite(out siteMetadata, out webInfo, out users, out sGroups, out vGroups);
                
                String latestGroupUrl = String.Empty;
                
                foreach (var webInfoItem in webInfo)
                {
                    if (webInfoItem.Url.StartsWith(topUrl) && !webInfoItem.Url.Equals(topUrl))
                    {
                        latestGroupUrl = webInfoItem.Url;
                    }
                }

                groupUrl = latestGroupUrl;

                if (String.IsNullOrEmpty(latestGroupUrl))
                {
                    // create group site
                    String groupalias = GenerateNextGroupSiteAlias(String.Empty);
                    groupUrl = CreateSubSite(settings, groupalias);
                }
                else
                {
                    // check if this group is beyond its limit;
                    if (GroupExceedsListLimit(settings, latestGroupUrl))
                    {
                        String groupalias = latestGroupUrl.Substring(latestGroupUrl.LastIndexOf("/")+1);
                        String newgroupalias = GenerateNextGroupSiteAlias(groupalias);
                        groupUrl = CreateSubSite(settings, newgroupalias);
                    }
                }
            }
            return groupUrl;
        }
        
        // generate next alias for a "group site" which is site that holds a limited number of 
        // libraries.  Alias are generated: A1, A2, A3, A4, ... A(n)
        private String GenerateNextGroupSiteAlias(String groupalias)
        {
            if (String.IsNullOrEmpty(groupalias))
            {
                return "A1";
            }
            if (groupalias.Length == 2)
            {
                char letter = groupalias[0];
                char index = groupalias[1];

                int v;
                if (int.TryParse(index.ToString(), out v)) 
                { 
                    v++; 
                }
                else
                {
                    throw new InvalidOperationException("Bad Group Site Alias Sequence: " + groupalias);
                }

                if (v == 10)
                {
                    v = 1;
                    byte b = (byte)letter;
                    b++;
                    letter = (char)b;

                    if (letter == 'Z') { throw new OverflowException("SharePoint Group Site Alias Sequence overflow: " + groupalias); }
                    return String.Format("{0}{1}", letter, v);
                }
                else
                {
                    return String.Format("{0}{1}", letter, v);
                }
            }
            throw new OverflowException("SharePoint Group Site Alias Sequence overflow: " + groupalias);
        }
        
        // determines if the current Group site has reached the limit and we need to create a new one
        private bool GroupExceedsListLimit(SPSettings settings, String latestGroupUrl)
        {
            int limit = SPSettingsManager.GetItemLimitForEntity(settings.EntityName);
            int actual = 0;
            using (Lists listWs = new Lists())
            {
                listWs.Credentials = SPSettingsManager.GetCredentialsFromConfig();
                listWs.Url = GetListsServiceUrl(settings.SiteUrl);
                XmlNode itemsNode = listWs.GetListItems(IndexListName, null, null, null, null, null, null);
                foreach (XmlNode itemNode in itemsNode.ChildNodes)
                {
                    foreach (XmlNode itemNode2 in itemNode.ChildNodes)
                    {
                        if (itemNode2.Attributes != null)
                        {
                            XmlAttribute locAttr = itemNode2.Attributes["ows_LibraryLocation"];
                            if (locAttr != null)
                            {
                                string path = locAttr.InnerXml;
                                if (path.Equals(latestGroupUrl)) { actual++; }
                            }
                        }
                    }
                }
            }
            return actual >= limit;
        }

        // creates the Library
        private void CreateDocLibraryOnSite(SPSettings settings, string destSiteLoc, string listName)
        {
            using (Lists listsWs = new Lists())
            {
                listsWs.Url = GetListsServiceUrl(destSiteLoc);
                listsWs.Credentials = SPSettingsManager.GetCredentialsFromConfig();

                string desc = String.Format("{0} library: {1}", settings.EntityName, listName);

                XmlNode outputNode = listsWs.AddList(listName, desc, DocLibListTemplateId);
                String contentTypeId = GetContentTypeByName(SPSettingsManager.GetContentTypeLocationForEntity(settings.EntityName), CustomDocContentTypeName);
                listsWs.ApplyContentTypeToList(settings.SiteUrl, contentTypeId, listName);
            }
        }

        // creates the list on our top level site to track where each entity's library is.
        private void CreateIndexRecordForThisEntity(String rootSiteUrl, String destinationSiteUrl, String listName)
        {
            using (Lists listWs = new Lists())
            {
                listWs.Credentials = SPSettingsManager.GetCredentialsFromConfig();
                listWs.Url = GetListsServiceUrl(rootSiteUrl);

                XmlDocument doc = new XmlDocument();
                XmlNode batchNode = doc.CreateNode(XmlNodeType.Element, "Batch", "");
                XmlNode methodNode = doc.CreateNode(XmlNodeType.Element, "Method", "");
                XmlNode idFieldNode = doc.CreateNode(XmlNodeType.Element, "Field", "");
                XmlNode titleFieldNode = doc.CreateNode(XmlNodeType.Element, "Field", "");
                XmlNode locationFieldNode = doc.CreateNode(XmlNodeType.Element, "Field", "");

                XmlAttribute onErrorAttr = (XmlAttribute)doc.CreateNode(XmlNodeType.Attribute, "OnError", "");
                onErrorAttr.InnerXml = "Continue";
                XmlAttribute listVerAttr = (XmlAttribute)doc.CreateNode(XmlNodeType.Attribute, "ListVersion", "");
                listVerAttr.InnerXml = "1";
                XmlAttribute methodIDAttr = (XmlAttribute)doc.CreateNode(XmlNodeType.Attribute, "ID", "");
                methodIDAttr.InnerXml = "1";
                XmlAttribute methodCmdAttr = (XmlAttribute)doc.CreateNode(XmlNodeType.Attribute, "Cmd", "");
                methodCmdAttr.InnerXml = "New";
                XmlAttribute fldIDNameAttr = (XmlAttribute)doc.CreateNode(XmlNodeType.Attribute, "Name", "");
                fldIDNameAttr.InnerXml = "ID";
                XmlAttribute fldTitleNameAttr = (XmlAttribute)doc.CreateNode(XmlNodeType.Attribute, "Name", "");
                fldTitleNameAttr.InnerXml = "Title";
                XmlAttribute fldLocNameAttr = (XmlAttribute)doc.CreateNode(XmlNodeType.Attribute, "Name", "");
                fldLocNameAttr.InnerXml = "LibraryLocation";

                batchNode.Attributes.Append(onErrorAttr);
                batchNode.Attributes.Append(listVerAttr);
                methodNode.Attributes.Append(methodIDAttr);
                methodNode.Attributes.Append(methodCmdAttr);
                idFieldNode.Attributes.Append(fldIDNameAttr);
                titleFieldNode.Attributes.Append(fldTitleNameAttr);
                locationFieldNode.Attributes.Append(fldLocNameAttr);

                idFieldNode.InnerXml = "New";
                titleFieldNode.InnerXml = listName;
                locationFieldNode.InnerXml = destinationSiteUrl;

                methodNode.AppendChild(idFieldNode);
                methodNode.AppendChild(titleFieldNode);
                methodNode.AppendChild(locationFieldNode);
                batchNode.AppendChild(methodNode);

                XmlNode resultNode = listWs.UpdateListItems(IndexListName, batchNode);
            }
        }

        // determines whether the "index list" exists for a given site.  
        // this needs to be created once per entity
        private void PrepareSiteForEntityLibraries(SPSettings settings)
        {
            bool indexListExists = false;

            using (Lists listsWs = new Lists())
            {
                listsWs.Url = GetListsServiceUrl(settings.SiteUrl);
                listsWs.Credentials = SPSettingsManager.GetCredentialsFromConfig();

                foreach (XmlNode listNode in listsWs.GetListCollection().ChildNodes)
                {
                    XmlAttribute titleAttribute = listNode.Attributes["Title"];
                    if (titleAttribute != null)
                    {
                        if (IndexListName.Equals(titleAttribute.InnerXml))
                        {
                            indexListExists = true;
                            break;
                        }
                    }
                }

                LoggingWrapper.DebugMessage("Index List Exists: " + indexListExists.ToString());

                if (!indexListExists)
                {
                    listsWs.AddList(IndexListName, String.Empty, CustomListTemplateId);
                    String contentTypeId = GetContentTypeByName(SPSettingsManager.GetContentTypeLocationForEntity(settings.EntityName), IndexContentTypeName);
                    listsWs.ApplyContentTypeToList(settings.SiteUrl, contentTypeId, IndexListName);
                }
            }
        }

        // looks for Entity reference in index list.
        internal String FindEntityLibraryLocation(SPSettings settings, string id)
        {
            string url = String.Empty;
            using (Lists listWs = new Lists())
            {
                listWs.Credentials = SPSettingsManager.GetCredentialsFromConfig();
                listWs.Url = GetListsServiceUrl(settings.SiteUrl);

                XmlDocument xmlDoc = new XmlDocument();
                XmlNode viewFieldsNode = xmlDoc.CreateNode(XmlNodeType.Element, "ViewFields", "");
                viewFieldsNode.InnerXml = "<FieldRef Name=\"ID\" /><FieldRef Name=\"Title\" /><FieldRef Name=\"LibraryLocation\" />";

                XmlNode query = xmlDoc.CreateNode(XmlNodeType.Element, "Query", "");
                query.InnerXml = @"<Where><Eq><FieldRef Name='Title' /><Value Type='Text'>" + id + @"</Value></Eq></Where>";

                XmlNode itemsNode = listWs.GetListItems(IndexListName, null, query, viewFieldsNode, null, null, null);

                foreach (XmlNode itemNode in itemsNode.ChildNodes)
                {
                    foreach (XmlNode itemNode2 in itemNode.ChildNodes)
                    {
                        if (itemNode2.Attributes != null)
                        {
                            //url += ", item has has attributes!" + (x++).ToString() ;

                            XmlAttribute titleAttr = itemNode2.Attributes["ows_Title"];
                            XmlAttribute locAttr = itemNode2.Attributes["ows_LibraryLocation"];
                            string path = String.Empty;
                            string title = String.Empty;
                            
                            if (titleAttr != null) { title = titleAttr.InnerXml; }
                            if (locAttr != null) { path = locAttr.InnerXml; }

                            if (_mypage is Page) _mypage.Trace.Write("Title > " + title + ", Path > " + path);

                            if (title.Equals(id)) 
                            {
                                if (_mypage is Page) _mypage.Trace.Write("Url Found!!!: " + path);
                                url = path; 
                            }
                        }
                    }
                }
            }
            return url;
        }
        #endregion

        #region Working with Content Types
        private String GetContentTypeByName(String contentLocation, String contentTypeName)
        {
            String contentTypeId = String.Empty;

            using (Webs websWs = new Webs())
            {
                websWs.Url = GetWebsServiceUrl(contentLocation);
                websWs.Credentials = SPSettingsManager.GetCredentialsFromConfig();
                bool contentTypeFound = false;

                XmlNode contentTypesNode = websWs.GetContentTypes();

                foreach (XmlNode contentTypeNode in contentTypesNode.ChildNodes)
                {
                    XmlAttribute nameAttrib = contentTypeNode.Attributes["Name"];
                    XmlAttribute idAttrib = contentTypeNode.Attributes["ID"];
                    if (nameAttrib != null)
                    {
                        if (contentTypeName.Equals(nameAttrib.InnerXml))
                        {
                            contentTypeId = idAttrib.InnerXml;
                            XmlNode contentTypeDescNode = websWs.GetContentType(contentTypeId);
                            contentTypeFound = true;
                            break;
                        }
                    }
                }

                if (!contentTypeFound)
                {
                    switch (contentTypeName)
                    {
                        case IndexContentTypeName:
                            contentTypeId = CreateEntityLibraryIndexContentType(websWs);
                            break;
                        case CustomDocContentTypeName:
                            contentTypeId = CreateCustomDocLibContentType(websWs);
                            break;
                        default:
                            throw new ArgumentException("GetContentTypeByName:Unknown ContentType, Cannot Create.");
                    }                
                }
            }

            return contentTypeId;
        }

        private String CreateCustomDocLibContentType(Webs websWs) 
        {
            String docTypeColumn = "DocumentCategory";
            String docTypeColumnDesc = "Document Category";

            if (!SiteColumnExists(docTypeColumn, websWs))
            {
                CreateSiteColumn(docTypeColumn, docTypeColumnDesc, "Text", websWs);
            }

            XmlDocument contentTypeDoc = new XmlDocument();
            XmlNode fieldsNode = contentTypeDoc.CreateNode(XmlNodeType.Element, "Fields", "");
            XmlNode methodNode = contentTypeDoc.CreateNode(XmlNodeType.Element, "Method", "");

            XmlAttribute methodidAttr = (XmlAttribute)contentTypeDoc.CreateNode(XmlNodeType.Attribute, "ID", "");
            methodidAttr.InnerXml = "1";

            methodNode.Attributes.Append(methodidAttr);
            fieldsNode.AppendChild(methodNode);

            XmlNode field1Node = contentTypeDoc.CreateNode(XmlNodeType.Element, "Field", "");

            XmlAttribute nameAttr = (XmlAttribute)contentTypeDoc.CreateNode(XmlNodeType.Attribute, "Name", "");
            nameAttr.InnerXml = docTypeColumn;

            XmlAttribute dispAttr = (XmlAttribute)contentTypeDoc.CreateNode(XmlNodeType.Attribute, "DisplayName", "");
            dispAttr.InnerXml = docTypeColumnDesc;

            XmlAttribute typeAttr = (XmlAttribute)contentTypeDoc.CreateNode(XmlNodeType.Attribute, "Type", "");
            typeAttr.InnerXml = "Text";

            field1Node.Attributes.Append(nameAttr);
            field1Node.Attributes.Append(dispAttr);
            field1Node.Attributes.Append(typeAttr);

            methodNode.AppendChild(field1Node);

            return CreateContentType(websWs, CustomDocContentTypeName, GetBaseContentTypeID(websWs, "Item"), fieldsNode);
        }

        private String CreateEntityLibraryIndexContentType(Webs websWs)
        {
            String libLocColumn = "LibraryLocation";
            String libLocColumnDesc = "Library Location";

            if (!SiteColumnExists(libLocColumn, websWs))
            {
                CreateSiteColumn(libLocColumn, libLocColumnDesc, "Text", websWs);
            }

            XmlDocument contentTypeDoc = new XmlDocument();
            XmlNode fieldsNode = contentTypeDoc.CreateNode(XmlNodeType.Element, "Fields", "");
            XmlNode methodNode = contentTypeDoc.CreateNode(XmlNodeType.Element, "Method", "");

            XmlAttribute methodidAttr = (XmlAttribute)contentTypeDoc.CreateNode(XmlNodeType.Attribute, "ID", "");
            methodidAttr.InnerXml = "1";

            methodNode.Attributes.Append(methodidAttr);
            fieldsNode.AppendChild(methodNode);

            XmlNode field1Node = contentTypeDoc.CreateNode(XmlNodeType.Element, "Field", "");

            XmlAttribute nameAttr = (XmlAttribute)contentTypeDoc.CreateNode(XmlNodeType.Attribute, "Name", "");
            nameAttr.InnerXml = libLocColumn;

            XmlAttribute dispAttr = (XmlAttribute)contentTypeDoc.CreateNode(XmlNodeType.Attribute, "DisplayName", "");
            dispAttr.InnerXml = libLocColumnDesc;

            XmlAttribute typeAttr = (XmlAttribute)contentTypeDoc.CreateNode(XmlNodeType.Attribute, "Type", "");
            typeAttr.InnerXml = "Text";

            field1Node.Attributes.Append(nameAttr);
            field1Node.Attributes.Append(dispAttr);
            field1Node.Attributes.Append(typeAttr);

            methodNode.AppendChild(field1Node);

            return CreateContentType(websWs, IndexContentTypeName, GetBaseContentTypeID(websWs, "Item"), fieldsNode);
        }

        private string GetBaseContentTypeID(Webs websWs, String baseContentTypeName)
        {
            XmlNode contentTypesNode = websWs.GetContentTypes();

            foreach (XmlNode contentTypeNode in contentTypesNode.ChildNodes)
            {
                XmlAttribute nameAttrib = contentTypeNode.Attributes["Name"];
                XmlAttribute idAttrib = contentTypeNode.Attributes["ID"];
                if (nameAttrib != null)
                {
                    if (baseContentTypeName.Equals(nameAttrib.InnerXml))
                    {
                        string contentTypeId = idAttrib.InnerXml;
                        return contentTypeId;
                    }
                }
            }
            return "0x01"; // This is the ID for the 'Item' ContentType
        }

        private string CreateContentType(Webs websWs, string name, string itemContentTypeCode, XmlNode fieldsNode)
        {
            XmlDocument contentTypeDoc = new XmlDocument();
            XmlNode propsNode = contentTypeDoc.CreateNode(XmlNodeType.Element, "ContentType", "");
            String id = websWs.CreateContentType(name, itemContentTypeCode, fieldsNode, propsNode);
            return id;
        }
        #endregion

        #region Working with Site Columns
        private void CreateSiteColumn(String colName, String colDesc, String colType, Webs websWs)
        {
            XmlDocument contentTypeDoc = new XmlDocument();
            XmlNode fieldsNode = contentTypeDoc.CreateNode(XmlNodeType.Element, "Fields", "");
            XmlNode methodNode = contentTypeDoc.CreateNode(XmlNodeType.Element, "Method", "");

            XmlAttribute methodidAttr = (XmlAttribute)contentTypeDoc.CreateNode(XmlNodeType.Attribute, "ID", "");
            methodidAttr.InnerXml = "1";

            methodNode.Attributes.Append(methodidAttr);
            fieldsNode.AppendChild(methodNode);

            XmlNode field1Node = contentTypeDoc.CreateNode(XmlNodeType.Element, "Field", "");

            XmlAttribute nameAttr = (XmlAttribute)contentTypeDoc.CreateNode(XmlNodeType.Attribute, "Name", "");
            nameAttr.InnerXml = colName;

            XmlAttribute dispAttr = (XmlAttribute)contentTypeDoc.CreateNode(XmlNodeType.Attribute, "DisplayName", "");
            dispAttr.InnerXml = colDesc;

            XmlAttribute typeAttr = (XmlAttribute)contentTypeDoc.CreateNode(XmlNodeType.Attribute, "Type", "");
            typeAttr.InnerXml = "Text";

            XmlAttribute requiredAttr = (XmlAttribute)contentTypeDoc.CreateNode(XmlNodeType.Attribute, "Required", "");
            requiredAttr.InnerXml = "FALSE";

            XmlAttribute groupAttr = (XmlAttribute)contentTypeDoc.CreateNode(XmlNodeType.Attribute, "Group", "");
            groupAttr.InnerXml = "Custom Columns";

            XmlAttribute maxLenAttr = (XmlAttribute)contentTypeDoc.CreateNode(XmlNodeType.Attribute, "MaxLength", "");
            maxLenAttr.InnerXml = "255";

            field1Node.Attributes.Append(typeAttr);
            field1Node.Attributes.Append(dispAttr);
            field1Node.Attributes.Append(requiredAttr);
            field1Node.Attributes.Append(maxLenAttr);
            field1Node.Attributes.Append(groupAttr);
            field1Node.Attributes.Append(nameAttr);
            
            

            methodNode.AppendChild(field1Node);

            XmlNode resultsNode = websWs.UpdateColumns(fieldsNode, fieldsNode, null);
        }

        private void RemoveSiteColumn(String colName, Webs websWs)
        {
            XmlDocument contentTypeDoc = new XmlDocument();
            XmlNode fieldsNode = contentTypeDoc.CreateNode(XmlNodeType.Element, "Fields", "");
            XmlNode methodNode = contentTypeDoc.CreateNode(XmlNodeType.Element, "Method", "");

            XmlAttribute methodidAttr = (XmlAttribute)contentTypeDoc.CreateNode(XmlNodeType.Attribute, "ID", "");
            methodidAttr.InnerXml = "1";

            methodNode.Attributes.Append(methodidAttr);
            fieldsNode.AppendChild(methodNode);

            XmlNode field1Node = contentTypeDoc.CreateNode(XmlNodeType.Element, "Field", "");

            XmlAttribute nameAttr = (XmlAttribute)contentTypeDoc.CreateNode(XmlNodeType.Attribute, "Name", "");
            nameAttr.InnerXml = colName;

            XmlAttribute typeAttr = (XmlAttribute)contentTypeDoc.CreateNode(XmlNodeType.Attribute, "Type", "");
            typeAttr.InnerXml = "Text";

            field1Node.Attributes.Append(nameAttr);
            field1Node.Attributes.Append(typeAttr);

            methodNode.AppendChild(field1Node);

            XmlNode resultsNode = websWs.UpdateColumns(null, null, fieldsNode);
        }

        private bool SiteColumnExists(String colName, Webs websWs)
        {
            XmlNode columnsNode = websWs.GetColumns();
            foreach (XmlNode colNode in columnsNode.ChildNodes)
            {
                Console.WriteLine(colNode.OuterXml);
                XmlAttribute nameAttr = colNode.Attributes["Name"];
                if (nameAttr != null)
                {
                    if (nameAttr.InnerXml.Equals(colName))
                    {
                        return true;
                    }
                }
            }
            return false;
        }
        #endregion

        #region Deleting Files From Library
        internal string DeleteFilesFromDocumentLibrary(string siteUrl, string libraryName, string[] pathsToDelete)
        {
            using (Lists listsWs = new Lists())
            {
                string status = string.Empty;
                listsWs.Credentials = SPSettingsManager.GetCredentialsFromConfig();
                //location
                listsWs.Url = GetListsServiceUrl(siteUrl);
                try
                {
                    //get Lists GUID
                    XmlNode ndListView = listsWs.GetListAndView(libraryName, "");
                    string strListID = ndListView.ChildNodes[0].Attributes["Name"].Value;
                    string strViewID = ndListView.ChildNodes[1].Attributes["Name"].Value;
                    //string builder
                    StringBuilder sbXML = new StringBuilder();
                                        
                    XmlNodeList xListItemID = null;
                    XmlNode xListItemsData = null;
                    string sListItemID = string.Empty;

                    //one time setup
                    XmlDocument xmlDoc = new XmlDocument();
                    XmlDocument xDocItemID = new XmlDocument();

                    //check if there is site nesting
                    string sPreFilePath = GetWebsPrefixForFilePath(siteUrl);

                    //sequence setup
                    foreach (string sFilePath in pathsToDelete)
                    {
                        string sFullFilePath = sPreFilePath + sFilePath;
                        //CAML query
                        XmlNode query = xmlDoc.CreateNode(XmlNodeType.Element, "Query", "");
                        query.InnerXml = @"<Where><Eq><FieldRef Name='FileRef' /><Value Type='Text'>" + sFullFilePath + @"</Value></Eq></Where>";

                        XmlNode queryOptions = xmlDoc.CreateNode(XmlNodeType.Element, "QueryOptions", "");
                        queryOptions.InnerXml = @"<IncludeMandatoryColumns>True</IncludeMandatoryColumns><ViewAttributes Scope='Recursive' />";
                        //get ListItem ID
                        xListItemsData = listsWs.GetListItems(libraryName, null, query,
                                                              null, int.MaxValue.ToString(), queryOptions, null);
                        
                        xDocItemID.LoadXml(xListItemsData.OuterXml);
                        xListItemID = xDocItemID.GetElementsByTagName("z:row");
                        sListItemID = xListItemID[0].Attributes["ows_ID"].Value.ToString();

                        string sXML = @"<Method ID='1' Cmd='Delete'>
                                 <Field Name='ID'>" + sListItemID + "</Field>" +
                                 "<Field Name='FileRef'>" + sFullFilePath + @"</Field>" +
                                 @"</Method>";
                        //add to string
                        sbXML.Append(sXML);
                        //clean
                        sXML = string.Empty;
                    }

                    //operation
                    XmlElement updateBatch = xmlDoc.CreateElement("Batch");
                    updateBatch.SetAttribute("OnError", "Continue");
                    updateBatch.SetAttribute("ListVersion", "1");
                    updateBatch.SetAttribute("ViewName", strViewID);
                    updateBatch.InnerXml = sbXML.ToString();
                    XmlNode xnode = listsWs.UpdateListItems(strListID, updateBatch);
                    status = xnode.OuterXml.ToString();

                    //clean
                    sbXML = null;
                    xmlDoc = null;
                    xDocItemID = null;
                }
                catch (Exception ex)
                {
                    status = ex.StackTrace.ToString();
                    LoggingWrapper.ReportError(ex);
                }

                return status;
            }
        }

        // When deleting a file, the path should contain not only its location 
        // in the current library, but also its current site's location within the site collection.
        private string GetWebsPrefixForFilePath(string siteUrl)
        {
            string siteBaseUrl = GetRootWebUrl(siteUrl);
            if (!siteBaseUrl.EndsWith("/")) { siteBaseUrl += "/"; }
            string newPath = siteUrl.Replace(siteBaseUrl, String.Empty);
            if (!newPath.EndsWith("/")) { newPath += "/"; }
            return newPath;
        }
        #endregion

        #region Working with Library Folders
        internal string CreateFolder(string siteUrl, string folderUrl)
        {
            using (Dws dwsWs = new Dws())
            {
                string status = string.Empty;
                dwsWs.Credentials = SPSettingsManager.GetCredentialsFromConfig();
                //location
                dwsWs.Url = GetDWSServiceUrl(siteUrl);
                try
                {
                    status = dwsWs.CreateFolder(folderUrl);
                }
                catch (Exception ex)
                {
                    status = ex.StackTrace.ToString();
                }
                return status;
            }
        }

        internal string DeleteFolder(string siteUrl, string folderUrl)
        {
            using (Dws objSvc = new Dws())
            {
                string status = string.Empty;
                objSvc.Credentials = SPSettingsManager.GetCredentialsFromConfig();
                //location
                objSvc.Url = GetDWSServiceUrl(siteUrl);
                try
                {
                    string delURL = folderUrl.Replace(" ", "%20");

                    //check if the folder has files, folders with files are not allowed to be deleted
                    bool IsEmpty = IsFolderEmpty(siteUrl, folderUrl);

                    //check if there "/" after the folder to delete    
                    if (folderUrl.Substring(folderUrl.Length - 1, 1) == "/")
                    {
                        delURL = folderUrl.Remove(folderUrl.Length - 1, 1);
                    }

                    if (IsEmpty == true)
                    {
                        //delete
                        status = objSvc.DeleteFolder(delURL);
                    }
                    else
                    {
                        status = " (Only empty folder can be deleted.)";
                    }
                }
                catch (Exception ex)
                {
                    status = ex.StackTrace.ToString();
                    LoggingWrapper.ReportError(ex);
                }
                return status;
            }
        }

        private bool IsFolderEmpty(string siteUrl, string folderUrl)
        {
            DocLibItemCollection coll = new DocLibItemCollection();
            GetFilesInFolder(siteUrl, folderUrl, ref coll);
            return coll.Count == 0;
        }
        #endregion

        #region Add Item to Library
        internal string AddDocumentToLibrary(string siteUrl, string libraryName, FileDescriptor descriptor, byte[] data)
        {
            string status = String.Empty;
            using (Copy copyWs = new Copy())
            {
                copyWs.Credentials = SPSettingsManager.GetCredentialsFromConfig();
                copyWs.Url = GetCopyServiceUrl(siteUrl);
                
                try
                {
                    CopyResult[] resultArray;
                    FieldInformation oFieldInfo = new FieldInformation();
                    oFieldInfo.DisplayName = descriptor.Description;
                    oFieldInfo.Type = FieldType.Text;
                    oFieldInfo.Value = descriptor.Title;
                    FieldInformation[] info = { oFieldInfo };
                    //Copy the document from SourceUrl to destinationUrl with metadatas
                    uint result = copyWs.CopyIntoItems(descriptor.SourceUrl, descriptor.DestinationUrls, info,
                                                  data, out resultArray);

                    using (Lists listsWs = new Lists())
                    {
                        listsWs.Credentials = SPSettingsManager.GetCredentialsFromConfig();
                        listsWs.Url         = GetListsServiceUrl(siteUrl);
                        string rootWebUrl   = GetRootWebUrl(siteUrl);
                        string virtualPath  = descriptor.DestinationUrls[0].Replace(rootWebUrl, String.Empty);


                        //get the item ID
                        string listItemId   = sGetIDOfUploadedFile(siteUrl, libraryName, descriptor);
                        LoggingWrapper.DebugMessage("Debug: " + virtualPath + ", for search to update title, category");
                        

                        XmlDocument xmlDoc  = new XmlDocument();
                        XmlNode query       = null;
                        
                        if (String.IsNullOrEmpty(listItemId)) 
                        {
                            LoggingWrapper.DebugMessage("Item not found for path: " + virtualPath);
                            throw new Exception("Item Not Found, cannot update Title Property."); 
                        }

                        string safeTitle    = descriptor.Title; // originally tried to UrlEncode, but the spaces were replaced with 'pluses'
                        string safeDocType  = descriptor.DocumentType;
                        string methodXml    = String.Format("<Method ID='1' Cmd='Update'><Field Name='ID'>{0}</Field><Field Name='Title'>{1}</Field><Field Name='DocumentCategory'>{2}</Field></Method>", listItemId, safeTitle, safeDocType);

                        XmlElement updateBatch = xmlDoc.CreateElement("Batch");
                        updateBatch.SetAttribute("OnError", "Continue");
                        updateBatch.SetAttribute("ListVersion", "1");

                        updateBatch.InnerXml    = methodXml;
                        XmlNode xnode           = listsWs.UpdateListItems(libraryName, updateBatch);
                        status                  = xnode.OuterXml.ToString();

                    }
                }
                catch (Exception ex)
                {
                    status = ex.StackTrace.ToString();
                    LoggingWrapper.ReportError(ex);
                }
            }

            return status;
        }

        /// <summary>
        /// fetch ID of uploaded file
        /// </summary>
        /// <param name="siteUrl"></param>
        /// <param name="sListName"></param>
        /// <param name="descriptor"></param>
        /// <returns></returns>
        private string sGetIDOfUploadedFile(string siteUrl, string sListName, FileDescriptor descriptor)
        {
            string id  = string.Empty;
            using (Lists listsWS = new Lists())
            {
                listsWS.Credentials       = SPSettingsManager.GetCredentialsFromConfig();;
                listsWS.Url               = GetListsServiceUrl(siteUrl);
                XmlDocument xmlDoc        = new XmlDocument();
                //sites/projects/A1/Pro20/FIN 2.docx [expected format]
                string sFullFilePath      = GetWebsPrefixForFilePath(siteUrl) + descriptor.DestinationUrls[0].Replace(siteUrl, String.Empty);
                //just in case some paths are getting mixed up
                sFullFilePath               = sFullFilePath.Replace("//", "/");
                //CAML query
                XmlNode query               = xmlDoc.CreateNode(XmlNodeType.Element, "Query", "");
                query.InnerXml              = @"<Where><Eq><FieldRef Name='FileRef' /><Value Type='Text'>" + sFullFilePath + @"</Value></Eq></Where>";
                XmlNode queryOptions        = xmlDoc.CreateNode(XmlNodeType.Element, "QueryOptions", "");
                queryOptions.InnerXml       = @"<IncludeMandatoryColumns>True</IncludeMandatoryColumns><ViewAttributes Scope='Recursive' />";
                //get ListItem ID, shopuld return one record only
                XmlNode xListItemsData      = listsWS.GetListItems(sListName, null, query,
                                                      null, "1", queryOptions, null);
                XmlDocument xDocItemID      = new XmlDocument();
                xDocItemID.LoadXml(xListItemsData.OuterXml);
                XmlNodeList xListItemID     = xDocItemID.GetElementsByTagName("z:row");
                id                          = xListItemID[0].Attributes["ows_ID"].Value.ToString();
            }
            //return
            return id;
        }

        #endregion
    }
}
