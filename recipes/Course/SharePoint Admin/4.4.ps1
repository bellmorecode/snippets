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

# Add the SP snapin
Write-Host "Loading the SharePoint snapin..." -ForegroundColor Green
Add-PSSnapin -Name "Microsoft.SharePoint.PowerShell"

#region Exercise Logic starts here

# Create Search Service AD Account
Write-Host "Creating SearchService AD account..." -ForegroundColor Green
New-ADUser -Name "SearchService" -Path "OU=CourseAdmins,DC=LOCALDOMAIN,DC=com" -Surname "SearchService" -SamAccountName "SearchService" -Enabled $true -ChangePasswordAtLogon $false -AccountPassword (ConvertTo-SecureString -AsPlainText "pw" -Force) -PasswordNeverExpires $true -UserPrincipalName "SearchService@localdomain.com" -DisplayName "SearchService" -ErrorAction Continue

# Register the SearchService account as a Managed Account
$SSCred = New-Object System.Management.Automation.PSCredential "LOCALDOMAIN\SearchService",(ConvertTo-SecureString "pw" -AsPlainText -Force)
New-SPManagedAccount $SSCred


Write-Host "Starting the Search service instance..." -ForegroundColor Green
$SearchInstance = Get-SPEnterpriseSearchServiceInstance
$SearchInstance.DefaultIndexLocation = "C:\Program Files\Microsoft Office Servers\15.0\Data\Office Server\Applications"
$SearchInstance.Update()

Start-SPEnterpriseSearchServiceInstance -Identity (Get-SPEnterpriseSearchServiceInstance)
Start-SPEnterpriseSearchQueryAndSiteSettingsServiceInstance -Identity (Get-SPEnterpriseSearchQueryAndSiteSettingsServiceInstance)

While($SearchInstance.Status -ine "Online")
{
    Start-Sleep -Seconds 3
    $SearchInstance = Get-SPEnterpriseSearchServiceInstance
}

While((Get-SPEnterpriseSearchQueryAndSiteSettingsServiceInstance).Status -ine "Online")
{
    Start-Sleep -Seconds 3
}

Get-SPEnterpriseSearchServiceInstance

# Create the Search service application
Write-Host "Creating the Search Service application..." -ForegroundColor Green
New-SPEnterpriseSearchServiceApplication -Name "SearchService" -ApplicationPool "ServiceApps" -DatabaseServer "LTREE"

Write-Host "Creating the Search service application proxy..." -ForegroundColor Green
New-SPEnterpriseSearchServiceApplicationProxy -Name "SearchService" -SearchApplication "SearchService"

$SSApp = (Get-SPServiceApplication | Where-Object {$_.DisplayName -ieq "SearchService"})
Write-Host "Setting the Search service application account..." -ForegroundColor Green
Set-SPEnterpriseSearchService -ServiceAccount "LOCALDOMAIN\SearchService" -ServicePassword (ConvertTo-SecureString -AsPlainText -String "pw" -Force)

Write-Host "Configuring a new search topology..." -ForegroundColor Green
$InitialSearchTopology = $SSApp | Get-SPEnterpriseSearchTopology -Active
$InitialSearchTopologyID = $InitialSearchTopology.TopologyId.ToString()

# Create a new search topology
$SearchTopology = $SSApp | New-SPEnterpriseSearchTopology

# Create Index Root directory
$IndexParent = "C:\Program Files\Microsoft Office Servers\15.0\Data\Office Server\Applications"
New-Item -Name "Index" -Path $IndexParent -ItemType Directory

Write-Host "Beginning pause for services to initialize..." -ForegroundColor Green
While((Get-SPEnterpriseSearchServiceInstance).Status -ine "Online")
{
    Start-Sleep -Seconds 3
}
Write-Host "Continuing..." -ForegroundColor Green

$SearchInstance = Get-SPEnterpriseSearchServiceInstance
# Create necessary components
New-SPEnterpriseSearchAdminComponent -SearchTopology $SearchTopology -SearchServiceInstance $SearchInstance
New-SPEnterpriseSearchAnalyticsProcessingComponent -SearchTopology $SearchTopology -SearchServiceInstance $SearchInstance
New-SPEnterpriseSearchContentProcessingComponent -SearchTopology $SearchTopology -SearchServiceInstance $SearchInstance
New-SPEnterpriseSearchQueryProcessingComponent -SearchTopology $SearchTopology -SearchServiceInstance $SearchInstance
New-SPEnterpriseSearchCrawlComponent -SearchTopology $SearchTopology -SearchServiceInstance $SearchInstance
New-SPEnterpriseSearchIndexComponent -SearchTopology $SearchTopology -SearchServiceInstance $SearchInstance -RootDirectory "$IndexParent\Index"

# Activate the new Search Topology
$SearchTopology | Set-SPEnterpriseSearchTopology

# Remove the initial Search Topology
Write-Host "Removing the initial search topology..." -ForegroundColor Green
while($InitialSearchTopology.State -ine "Inactive")
{
    $InitialSearchTopology = $SSApp | Get-SPEnterpriseSearchTopology -Identity $InitialSearchTopologyID
    Start-Sleep -Seconds 2
}

$admin | Set-SPEnterpriseSearchAdministrationComponent -SearchServiceInstance $SearchInstance -Debug:$false
$admin = $SSApp | Get-SPEnterpriseSearchAdministrationComponent -Debug:$false

Write-Host "Waiting for Search Admin component to initialize" -ForegroundColor Green -NoNewline
While (-not $admin.Initialized)
{
    Write-Host -NoNewline "." -ForegroundColor Green
    Start-Sleep -Seconds 3
    $admin = $SSApp | Get-SPEnterpriseSearchAdministrationComponent -Debug:$false

}
Write-Host "done" -ForegroundColor Green
Write-Host "Search Admin component initialized." -ForegroundColor Green

# Add a crawl content source
Write-Host "Adding crawl content source and UNC path..." -ForegroundColor Green
New-SPEnterpriseSearchCrawlContentSource -Name "Reference Material Share" -SearchApplication $SSApp -Type File -StartAddresses "\\LTREE\C$\Course1532\Reference"

# Start crawls
Write-Host "Initiating full crawls for all content sources.." -ForegroundColor Green
Get-SPEnterpriseSearchCrawlContentSource -SearchApplication $SSApp | Where-Object {$_.CrawlState -ieq "Idle"} | ForEach-Object {$_.StartFullCrawl()}

# Activate SharePoint publishing features
Write-Host "Activating Publishing features for site collection and site..." -ForegroundColor Green
Enable-SPFeature -Identity "PublishingSite" -Url "http://ltree.localdomain.com"
Enable-SPFeature -Identity "PublishingWeb" -Url "http://ltree.localdomain.com"

# Create an Enterprise Search Site
Write-Host "Resetting IIS..." -ForegroundColor Green
Start-Process iisreset -Wait -NoNewWindow
Start-Sleep -Seconds 3
Write-Host "Creating Enterprise Search site..." -ForegroundColor Green
New-SPWeb -Url "http://ltree.localdomain.com/EnterpriseSearch" -Name "EnterpriseSearch" -Template "SRCHCEN#0" -UseParentTopNav

#endregion

[void][System.Windows.Forms.MessageBox]::Show("Solution script is complete.","Solution Script")
