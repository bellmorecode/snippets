# Add the SP snappin
Write-Host "Loading the SharePoint snappin..." -ForegroundColor Green
Add-PSSnapin -Name "Microsoft.SharePoint.PowerShell"

# Create Authentication Provider
$AuthProvider = New-SPAuthenticationProvider -UseWindowsIntegratedAuthentication

#Create new Web Application
Write-Host "Creating the LTREE Web Application..." -ForegroundColor Green
New-SPWebApplication `
    -Name "LTREE"  `
    -ApplicationPool "LTREE" `
    -ApplicationPoolAccount (Get-SPManagedAccount "LOCALDOMAIN\SPFarmService") `
    -Port 80 `
    -URL "http://ltree.localdomain.com" `
    -DatabaseServer "LTREE" `
    -DatabaseName "DELETEME" `
    -AuthenticationProvider $AuthProvider

# Copy the database files
Write-Host "Copying the supplied database files..." -ForegroundColor Green
Copy-Item -Path "C:\Course1532\SharePoint2010Content\*.*" -Destination "C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA"

# Attach the copied database
Write-Host "Attaching the database..." -ForegroundColor Green
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SQlServer.Smo")
$SQLServer = New-Object('Microsoft.SqlServer.Management.Smo.Server') ltree
$strColl = New-Object System.Collections.Specialized.StringCollection
$strColl.Add("C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\WSS_Content_80.mdf")
$strColl.Add("C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\WSS_Content_80_log.ldf")
$SQLServer.AttachDatabase("WSS_Content_80",$strColl)

# Mount the database
Write-Host "Mounting the attached database..." -ForegroundColor Green
Mount-SPContentDatabase -Name WSS_Content_80 -WebApplication http://ltree.localdomain.com

# Upgrade the site
Write-Host "Upgrading the Site..."
Upgrade-SPSite -Identity "http://ltree.localdomain.com" -VersionUpgrade

Read-Host "Exercise solution complete.  Check for errors and press <ENTER> to continue"