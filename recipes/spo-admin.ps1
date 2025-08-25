# Get-Module -Name Microsoft.Online.SharePoint.PowerShell -ListAvailable | Select Name,Version
# Install-Module -Name Microsoft.Online.SharePoint.PowerShell

$adminUPN="glenn@gfdata.io"
$orgName="gfdata"
$userCredential = Get-Credential -UserName $adminUPN -Message "XXXX"
Connect-SPOService -Url https://$orgName-admin.sharepoint.com -Credential $userCredential
$site = Get-SPOSite -Identity "https://gfdata.sharepoint.com/"
# $site.