Function Get-DayOfYear {
 (Get-Date).DayOfYear
}

Function Get-LargeFiles([Parameter(Mandatory=$True)]$size){
    Get-ChildItem C:\Users -Recurse | Where-Object {$_.Length -gt $size}
}

Function ConCat-Them ([string]$first,[string]$second) {
  $first + $second
}