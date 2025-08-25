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

#region Add SPFarmAdmin as a Site Collection administrator
    Write-Host "Adding SPFarmAdmin as a Site Collection administrator..." -ForegroundColor Green
	Set-SPSite -Identity "http://ltree.localdomain.com" -SecondaryOwnerAlias "LOCALDOMAIN\SPFarmAdmin"
#endregion

#region Create a new Web Application for My Sites

If ((Get-SPWebApplication -Identity MySites -ErrorAction SilentlyContinue).count -eq 0){
	# Create Authentication Provider
	$AuthProvider = New-SPAuthenticationProvider -UseWindowsIntegratedAuthentication

	#Create new Web Application
	Write-Host "Creating the MySites Web Application..." -ForegroundColor Green
	New-SPWebApplication `
	    -Name "MySites"  `
	    -ApplicationPool "MySites" `
	    -ApplicationPoolAccount (Get-SPManagedAccount "LOCALDOMAIN\SPFarmService") `
	    -Port 20000 `
	    -DatabaseServer "LTREE" `
	    -DatabaseName "MySites" `
	    -AuthenticationProvider $AuthProvider
	
}
ELSE {Write-Host "MySites WebApp already exists, skipping..." -ForegroundColor 'Red'}
#endregion

# Modify scheduled job
Write-Host "Configuring the Usage Data Processing scheduled job..." -ForegroundColor Green
Set-SPTimerJob -Identity job-usage-log-file-processing -Schedule "hourly between 0 and 0"

Write-Host "Exercise solution complete." -ForegroundColor 'Green'
[void][System.Windows.Forms.MessageBox]::Show("Solution script is complete.","Solution Script")

