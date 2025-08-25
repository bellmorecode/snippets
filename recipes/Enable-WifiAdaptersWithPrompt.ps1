#$InputFile = "C:\Computers.txt"
$FailedFile = "C:\FailedComputers.txt"

##################################

# Check for files and create the failedfile if necessary

#$Computers = Get-Content -Path $InputFile
# Import the assembly once for the script
Add-Type -AssemblyName System.Windows.Forms

# Browse for file to open
$openFileDialog1 = New-Object System.Windows.Forms.OpenFileDialog
$openFileDialog1.Filter = "Text Files|*.txt|All Files|*.*"
$openFileDialog1.ShowDialog()
$InputFileName = $openFileDialog1.FileName
$Computers = Get-Content -Path $InputFileName

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