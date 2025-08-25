$content = "46 72 6f 6d 3a 20 41 67 65 6e 74 20 57 69 6e 74 65 72 20 54 6f 3a 20 4e 65 77 20 52 65 63 72 75 69 74 73 20 4d 65 73 73 61 67 65 3a 20 48 65 6c 70 20 6e 65 65 64 65 64 2c 20 73 74 61 6e 64 20 62 79 2e"
#WRite-Host $content

$symbols = $content.Split(' ')

#Write-Host " --- " 
#$symbols.Count

$ch_arr = new-object System.Text.StringBuilder

foreach($s in $symbols)
{
    $i = [Convert]::ToInt32($s, 16)
    $ch = [char]$i
    $ch_arr.Append($ch)
}
$ch_arr.ToString()