$paths = "I:\gfdata","I:\mess","I:\to-be-moved"

$total = 0
$list = New-Object System.Collections.Generic.List[string]

foreach($path in $paths) {
    $filenames = [System.IO.Directory]::GetFiles($path, "*.cs", [System.IO.SearchOption]::AllDirectories)
    Write-Host $filenames.length
    $total += $filenames.Length
    $list.AddRange($filenames)
}

Write-Host ""
Write-Host "Total: $total"

Write-Host "begin write"


[System.IO.File]::WriteAllLines("I:\codefiles.csv", $list.ToArray())

Write-Host "Done"