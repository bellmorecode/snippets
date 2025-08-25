using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Microsoft.SharePoint;
using System.IO;

namespace SharePointSiteCollectionInspector
{
    public class SimpleWriter : IDisposable
    {
        private StreamWriter _sw;
        public SimpleWriter(string path)
        {
            string rootPath = AppDomain.CurrentDomain.BaseDirectory;
            string logpath = Path.Combine(rootPath, path);
            _sw = new StreamWriter(logpath);
        }

        public void WriteLine(string message)
        {
            Console.WriteLine(message);
            _sw.WriteLine(message);
            _sw.Flush();
        }

        public void WriteLine(string format, params object[] args)
        {
            WriteLine(String.Format(format, args));
        }

        private bool _disposed = false;

        public void Dispose()
        {
            Dispose(_disposed);
            GC.SuppressFinalize(this);
        }

        protected virtual void Dispose(bool disposing)
        {
            if (!_disposed)
            {
                if (disposing)
                {
                    if (_sw != null)
                    {
                        _sw.Flush();
                        _sw.Close();
                        _sw.Dispose();
                        _sw = null;
                    }
                }
                _disposed = true;
                // set resource references to null here.
            }
        }
    }

    class Program
    {
        static void Main(string[] args)
        {
            Console.Write("Enter your sharepoint site url:");
            string url = Console.ReadLine(); ;
            using (SimpleWriter writer = new SimpleWriter("output.xml"))
            {
                
                //if (Environment.MachineName.Equals("ZFERRIE")) url = "http://zferrie";
                SPSecurity.RunWithElevatedPrivileges(
                    delegate()
                    {
                        using (SPSite site = new SPSite(url))
                        {
                            using (SPWeb topWeb = site.OpenWeb())
                            {
                                writer.WriteLine(WrapAsXml(topWeb.Name));
                                writer.WriteLine("{0}{1}", " ", WrapAsXml("Lists"));
                                GetListsForWeb(writer, topWeb, "  ");
                                writer.WriteLine("{0}{1}", " ", WrapAsXml("Lists", true));
                                writer.WriteLine("{0}{1}", " ", WrapAsXml("SubSites"));
                                RecurseSubWebs(writer, topWeb, "  ");
                                writer.WriteLine("{0}{1}", " ", WrapAsXml("SubSites", true));
                                writer.WriteLine(WrapAsXml(topWeb.Name, true));
                            }
                        }
                    });

            }

            Console.WriteLine("Done!");
            string input = Console.ReadLine();

        }

        private static void GetListsForWeb(SimpleWriter writer, SPWeb topWeb, string separator)
        {
            foreach (SPList list in topWeb.Lists)
            {
                long count = list.Items.Count;
                writer.WriteLine("{0}<List Name=\"{1}\" items=\"{2}\" />", separator, list.Title, count);
            }
        }

        private static String WrapAsXml(string s)
        {
            return WrapAsXml(s, false);
        }
        private static String WrapAsXml(string s, bool isEndTag)
        {
            if (String.IsNullOrEmpty(s)) s = "top";
            if (isEndTag)
                return String.Format("</{0}>", s);
            else
                return String.Format("<{0}>", s);
        }

        private static void RecurseSubWebs(SimpleWriter writer, SPWeb topWeb, string separator)
        {
            foreach (SPWeb web in topWeb.Webs)
            {
                writer.WriteLine("{0}<Site Name=\"{1}\">", separator, web.Name);

                string nextSeparator = separator + " ";
                string nextSeparator2 = nextSeparator + " ";
                writer.WriteLine("{0}{1}", nextSeparator, WrapAsXml("Lists"));
                GetListsForWeb(writer, web, nextSeparator2);
                writer.WriteLine("{0}{1}", nextSeparator, WrapAsXml("Lists", true));

                writer.WriteLine("{0}{1}", nextSeparator, WrapAsXml("SubSites"));

                RecurseSubWebs(writer, web, nextSeparator2);
                writer.WriteLine("{0}{1}", nextSeparator, WrapAsXml("SubSites", true));
                writer.WriteLine("{0}{1}", separator, WrapAsXml("Site", true));
            }
        }
    }
}
