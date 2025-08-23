namespace LineCounter
{
    internal class Program
    {
        static void Main(string[] args)
        {
            var path = @"C:\_src\gotham\OrderTracker-Desktop";
            var files = Directory.GetFiles(path, "*.*", SearchOption.AllDirectories);
            var codeFileCount = 0;
            var lineCount = 0;
            foreach(var file in files)
            {
                if (file.IndexOf(@"\obj\") > -1) { continue; }
                if (file.IndexOf(@"\bin\") > -1) { continue; }
                if (file.IndexOf(@".min.") > -1) { continue; }
                if (file.IndexOf(@"\wwwroot\lib\") > -1) { continue; }
                if (file.IndexOf(@"\Properties\") > -1) { continue; }
                if (file.IndexOf(@"\.vs\") > -1) { continue; }
                if (file.IndexOf(@".zip") > -1) { continue; }
                if (file.IndexOf(@".csproj") > -1) { continue; }
                if (file.IndexOf(@".sln") > -1) { continue; }
                if (file.IndexOf(@".png") > -1) { continue; }
                if (file.IndexOf(@".ico") > -1) { continue; }
                if (file.IndexOf(@".json") > -1) { continue; }
                if (file.IndexOf(@".xml") > -1) { continue; }
                if (file.IndexOf(@".editorconfig") > -1) { continue; }
                if (file.IndexOf(@"\.git\") > -1) { continue; }
                if (file.IndexOf(@".pdf") > -1) { continue; }
                if (file.IndexOf(@".dll") > -1) { continue; }
                if (file.IndexOf(@".exe") > -1) { continue; }
                if (file.IndexOf(@"\jigsaw\shared\") > -1) { continue; }
                if (file.IndexOf(@"MSTest.TestFramework") > -1) { continue; }
                if (file.IndexOf(@"\lib\") > -1) { continue; }
                if (file.IndexOf(@"\packages\") > -1) { continue; }
                if (file.IndexOf(@".tt") > -1) { continue; }
                if (file.IndexOf(@".resx") > -1) { continue; }
                if (file.IndexOf(@".pfx") > -1) { continue; }
                if (file.IndexOf(@".msi") > -1) { continue; }
                if (file.IndexOf(@".bmp") > -1) { continue; }
                if (file.IndexOf(@".gitignore") > -1) { continue; }

                Console.WriteLine(file);
                lineCount += File.ReadAllLines(file).Length;
                codeFileCount++;
            }
            Console.WriteLine( $"File Count: {files.Length}" );
            Console.WriteLine($"Code File Count: {codeFileCount}");
            Console.WriteLine($"Total Line Count: {lineCount}");
            var done = Console.ReadLine();
        }
    }
}
