#####  Prompt for backup location
# Import the assembly once for the script
Add-Type -AssemblyName System.Windows.Forms

# Browse for file to open
$openFolderDialog1 = New-Object System.Windows.Forms.FolderBrowserDialog
$openFolderDialog1.Description = "Select the folder containing the USMT backup:"
$openFolderDialog1.ShowNewFolderButton = $False
$openFolderDialog1.ShowDialog()
$BackupFolder = $openFolderDialog1.SelectedPath

##### Restore data
&("$PSScriptRoot\loadstate.exe $BackupFolder /i:$PSScriptRoot\migsys.xml /i:$PSScriptRoot\migapp.xml /i:$PSScriptRoot\miguser.xml")