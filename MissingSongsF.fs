/// Glenn Ferrie - Jun 13 2010
/// MissingSongsF :: fsharp app for comparing two sets of playlists and determining
/// the deltas, per file and overall. Tested with iTunes(9.?) format playlists.
/// Note: This is a good example of some .NET4, F#2.0 features
/// Functional: No state mutation, some file creation, logging
#light

open System
open System.IO

/// Start Here!
Console.WriteLine "Begin Analyze Missing Songs"

// paths containing two directories to compare
let desktop = @"c:\users\glenn\desktop"
let pathBefore = desktop + "\BEFORE"
let pathAfter = desktop + "\AFTER"

// Get the files in each directory using a new static method for Directory
// Also: DirectoryInfo, File, and FileInfo
let fileListBefore = Directory.EnumerateFiles(pathBefore);
let fileListAfter = Directory.EnumerateFiles(pathAfter);

// feature[zipping] :: Convert list<filepath>, list<filepath> -> list<filepath * filepath>
let fileList = fileListAfter |> Seq.zip(fileListBefore)

// The file is assumed to be a tab and CR delimited data structure
// where the rows represent song data and the first two columns (0, 1)
// contain the song name and the artist. (other data exists, but is unimportant
// for this excercise.
// Returns list<author, songname>
let GetLinesFromFileInfo(fi : FileInfo) = 
    // open stream, get all text, split by CR
    let stream = fi.OpenText()
    let data = ( stream.ReadToEnd() ).Split([| '\n' |])
    // split each line into a string[], by tab, 
    // omit any rows with less than 2 cells, take the first two columns, 
    // skip the first row (row-header)
    let names = data |> Seq.map ( fun x -> x.Split([| '\t' |]) ) |> Seq.filter( fun x -> x.Length > 1 ) |> Seq.map ( fun x -> x.[1], x.[0] ) |> Seq.skip(1)
    // convert from seq to list (style)
    Seq.toList(names)

// create a type for storing my complex result. MFResult means "MissingFile" Result
// it has a playlist name, a pair if song lists (from our two libraries) and the delta
type MFResult = { Filename : string; BeforeNames : (string * string) list; AfterNames : (string * string) list; Delta : (string * string) list; }
    
// compare two files (x : path; y : path) [patterns that can compose and decompose]
let CompareFiles ( x, y ) = 
    let fi1 = new FileInfo(x)
    let fi2 = new FileInfo(y)
    let rowsBefore = GetLinesFromFileInfo(fi1)
    let rowsAfter = GetLinesFromFileInfo(fi2)
    // compute delta...
    // this is fun. 
    let delta = Seq.toList( seq { 
        for i = 0 to rowsBefore.Length - 1 do
            let exists = rowsAfter |> Seq.exists ( fun x -> rowsBefore.[i].Equals(x) )
            if (exists = false) then yield rowsBefore.[i] } )

    let name = x.Substring(x.LastIndexOf("\\")+1); // get playlist name

    // construct MFResult through type inference
    { Filename = name; BeforeNames = rowsBefore; AfterNames = rowsAfter; Delta = delta; }

// generate MFResults from the file lists
let resultsList = fileList |> Seq.map( fun (x,y) -> CompareFiles (x, y) )

/// value for writing result to the Console.   
let Review x = 
    Console.WriteLine(x.ToString())

//resultsList |> Seq.iter ( fun x -> Review ( x ) )

// if before = after then delta = 0, filter those from our list
let ListsWithItemsMissing = Seq.toList(resultsList |> Seq.filter( fun x -> x.Delta.Length > 0 ))

// instantiate streamwriter for log per playlist [first-mutation]
let fs1 = new StreamWriter(desktop + "\MissingItems.txt")
for x = 0 to ListsWithItemsMissing.Length - 1 do
    fs1.WriteLine()
    Console.WriteLine()
    fs1.WriteLine(ListsWithItemsMissing.Item(x).Filename)
    Console.WriteLine(ListsWithItemsMissing.Item(x).Filename)
    for y = 0 to ListsWithItemsMissing.Item(x).Delta.Length - 1 do
        fs1.WriteLine(" " + ListsWithItemsMissing.Item(x).Delta.Item(y).ToString())
        Console.WriteLine(" " + ListsWithItemsMissing.Item(x).Delta.Item(y).ToString())

fs1.Flush()
fs1.Close()
    
let pauseText = Console.ReadLine() : string
Console.WriteLine()
let fs2 = new StreamWriter(desktop + "\DistinctMissingItems.txt")

// function sequence generation, two-tiered. Convert to Set<T> (unique, ordered)
let unique = Set(seq { for list in ListsWithItemsMissing do 
                        for item in list.Delta -> item })

unique |> Seq.iter( fun x -> fs2.WriteLine(x.ToString()) )
unique |> Seq.iter( fun x -> Console.WriteLine(x.ToString()) )

fs2.Flush()
fs2.Close()

Console.WriteLine ("Missing Files: " + unique.Count.ToString())
let xxxx = Console.ReadLine()


