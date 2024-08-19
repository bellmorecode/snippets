using System;
using System.Diagnostics;
using System.IO;

namespace bc.snippets 
{
    public sealed class Utility
    {
        public void ExecuteAsAdmin(string filename)
        {
            Process proc = new Process();
            proc.StartInfo.FileName = filename;
            proc.StartInfo.UseShellExecute = true;
            proc.StartInfo.WorkingDirectory = Path.GetDirectoryName(filename);
            proc.StartInfo.Verb = "runas";
            proc.Start();
        }
    }
}
