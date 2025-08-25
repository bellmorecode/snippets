$InputFile = "C:\Computers.txt"
$FailedFile = "C:\FailedComputers.txt"

##################################

# Check for files and create the failedfile if necessary

$Computers = Get-Content -Path $InputFile

$Computers | ForEach-Object {
    If(Test-Connection -ComputerName $_ -Quiet){
        [array]$WirelessAdapters = Get-WmiObject win32_networkadapter -ComputerName $_ | `
           Where-object {$_.Name -like "*wireless*"}

        $WirelessAdapters | ForEach-Object {
            If ($_.NetEnabled -eq $False) {$_.Enable()}
        }
     }
     Else{
      Add-Content -Value "$_" -Path $FailedFile -Force
     }
}

#Key off of NetEnabled (Bool)