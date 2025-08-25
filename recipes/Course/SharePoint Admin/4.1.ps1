#========================================================================
# Created by:   Shane Cribbs
# Organization: Learning Tree International
#========================================================================
# Load assemblies
[void][reflection.assembly]::Load("System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")

# Check host name
If ($env:COMPUTERNAME -ine "LTREE"){
	[void][System.Windows.Forms.MessageBox]::Show("This script is designed for server ""LTREE"" only.`n SCRIPT ABORTING","Script Aborted")
	Exit
}

Write-Host "Host name validated" -ForegroundColor 'Green'

# Add the SP snappin
Write-Host "Loading the SharePoint snapin..." -ForegroundColor Green
Add-PSSnapin -Name "Microsoft.SharePoint.PowerShell"

#region Exercise Logic starts here

# Check for the Secure Store Service which should be configured from the 'Do Now'
$SSService = Get-SPServiceInstance | Where-Object {$_.TypeName -ieq "Secure Store Service"}
$SSGUID = $SSService.Id

If ($SSService.Status -ieq "Disabled")
   {
   [void][System.Windows.Forms.MessageBox]::Show("The required Do Now has not been completed.","ERROR")
   Exit
   }

# Run the SQL script to add db, tables and data
Write-Host "Creating external data from SQL Script..." -ForegroundColor 'Green'
Invoke-Sqlcmd -InputFile "c:\course1532\BDC Files\CourseInfo.sql"

# Start the Business Data Connectivity Server Service
# Check for and configure Secure Store Service
$BDCSService = Get-SPServiceInstance | Where-Object {$_.TypeName -ieq "Business Data Connectivity Service"}
$ServiceGUID = $BDCSService.Id

# Start and wait on the Business Data Connectivity Server service
If ($BDCSService.Status -ieq "Disabled")
   {
   Write-Host "Starting the Business Data Connectivity Server service..." -ForegroundColor Green
   Start-SPServiceInstance -Identity $ServiceGUID
   While ($BDCSService.Status -ine "Online"){
       Start-Sleep -Seconds 1
       $BDCSService = Get-SPServiceInstance -Identity $ServiceGUID
      }
   Write-Host "Started the Business Data Connectivity Server service..." -ForegroundColor Green
   }


# Configure Business Data Connectivity Application Service
Write-Host "Creating the BDC service application..." -ForegroundColor Green
New-SPServiceApplicationPool -Name "ServiceApps" -Account "LOCALDOMAIN\SPFarmService"
New-SPBusinessDataCatalogServiceApplication -ApplicationPool "ServiceApps" -Name "BDC" -DatabaseName "BDC_Service_DB" -DatabaseServer "LTREE"

# Import model
Write-Host "Importing BDC model..." -ForegroundColor Green
$MetadataStore = Get-SPBusinessDataCatalogMetadataObject -BdcObjectType Catalog -ServiceContext "http://ltree.localdomain.com"
Import-SPBusinessDataCatalogModel -Path "C:\Course1532\BDC files\CourseAttendance.bdcm" -Identity $MetadataStore -ModelsIncluded -LocalizedNamesIncluded -PropertiesIncluded -Force

# Configure Secure Store Service credential access
Write-Host "Configuring Secure Store Service credential access..." -ForegroundColor Green
# Convert values to secure strings
$secureUserName = convertto-securestring "LOCALDOMAIN\CourseUser" -asplaintext -force
$securePassword = convertto-securestring "pw" -asplaintext -force
$credentialValues = $secureUserName,$securePassword

$ssapp = Get-SPSecureStoreApplication -ServiceContext "http://ltree.localdomain.com" -Name "CourseInfo"
 
# Fill in the values for the fields in the target application
Update-SPSecureStoreGroupCredentialMapping -Identity $ssApp -Values $credentialValues

# Add the external SharePoint list
$ListURL = "CourseAttendance"
$ListTitle = "CourseAttendance"
$Description = ""

$SPWeb = Get-SPWeb -Identity "http://ltree.localdomain.com/Documents"
$ds = New-Object -TypeName Microsoft.SharePoint.SPListDataSource
$ds.SetProperty("LobSystemInstance", "CourseInfo")
$ds.SetProperty("EntityNamespace", "http://ltree")
$ds.SetProperty("Entity", "CourseAttendance")
$ds.SetProperty("SpecificFinder", "Read Item")


$SPWeb.Lists.Add($ListTitle,$Description,$ListURL,$ds)
$list = $SPWeb.Lists[$ListURL]
$list.Title = $ListTitle
$list.update()
$SPWeb.Dispose()

# Adjust Metadata Store Permissions
$claimSPFarmAdmin = New-SPClaimsPrincipal -Identity "LOCALDOMAIN\SPFarmAdmin" -IdentityType WindowsSamAccountName
$catalog = Get-SPBusinessDataCatalogMetadataObject -BdcObjectType Catalog -ServiceContext "http://ltree.localdomain.com"
$model = Get-SPBusinessDataCatalogMetadataObject -BdcObjectType Model -ServiceContext "http://ltree.localdomain.com" -Name "CourseAttendance"
Grant-SPBusinessDataCatalogMetadataObject -Principal $claimSPFarmAdmin -Identity $catalog -Right "SetPermissions,Execute,Edit,SelectableInClients"
Grant-SPBusinessDataCatalogMetadataObject -Principal $claimSPFarmAdmin -Identity $model -Right "SetPermissions,Execute,Edit,SelectableInClients"

#endregion

[void][System.Windows.Forms.MessageBox]::Show("Solution script is complete.","Solution Script")
