#========================================================================
# Created by:   Shane Cribbs
# Organization: Learning Tree International
#========================================================================
# Load assemblies
[void][reflection.assembly]::Load("System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")

# Check host name
If ($env:COMPUTERNAME -ne "LTREE"){
	[void][System.Windows.Forms.MessageBox]::Show("This script is designed for server ""LTREE"" only.`n SCRIPT ABORTING","Script Aborted")
	Exit
}

Write-Host "Host name validated" -ForegroundColor 'Green'

# Add the SP snappin
Write-Host "Loading the SharePoint snappin..." -ForegroundColor Green
Add-PSSnapin -Name "Microsoft.SharePoint.PowerShell"

#region Exercise Logic starts here



#endregion

[void][System.Windows.Forms.MessageBox]::Show("Solution script is complete.","Solution Script")
