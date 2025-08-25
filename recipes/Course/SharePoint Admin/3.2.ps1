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
	
	If ((Get-SPSite -Identity http://ltree:20000 -ErrorAction SilentlyContinue).Count -eq 0) {
		Write-Host "Creating Site Collection for My Sites..." -ForegroundColor 'Green'
		New-SPSite -URL "http://ltree:20000" -Template (Get-SPWebTemplate -Identity "SPSMSITEHOST#0") -OwnerAlias "LOCALDOMAIN\SPFarmAdmin"
	}
	ELSE {Write-Host "MySites collection already exists.  Skipping..." -ForegroundColor 'Red'}
	
	Write-Host "Enabling Self Service Site Creation for My Sites..." -ForegroundColor 'Green'
	$MySites = (Get-SPWebApplication http://ltree:20000)
    $MySites.SelfServiceSiteCreationEnabled = $true
	$MySites.Update()

	# Change the primary site collection administrator to SPFarmAdmin
	Write-Host "Changing Primary Site Collection Administrator" -ForegroundColor 'Green'
	Set-SPSite -Identity "http://ltree.localdomain.com" -OwnerAlias "LOCALDOMAIN\SPFarmAdmin"

#endregion



[void][System.Windows.Forms.MessageBox]::Show("Solution script is complete.","Solution Script")
