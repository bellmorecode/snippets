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

# Check for and configure Secure Store Service
$SSService = Get-SPServiceInstance | Where-Object {$_.TypeName -ieq "Secure Store Service"}
$SSGUID = $SSService.Id

# Start and wait on the Secure Store Service
If ($SSService.Status -ieq "Disabled")
   {
   Write-Host "Starting the Secure Store Service..." -ForegroundColor Green
   Start-SPServiceInstance -Identity $SSGUID
   While ($SSService.Status -ine "Online"){
       Start-Sleep -Seconds 1
       $SSService = Get-SPServiceInstance -Identity $SSGUID
      }
   Write-Host "Started the Secure Store Service..." -ForegroundColor Green
   }

Write-Host "Creating the Secure Store Service application..." -ForegroundColor Green
New-SPServiceApplicationPool -Name "SecureStore" -Account "LOCALDOMAIN\SPFarmService"
$SSApp = New-SPSecureStoreServiceApplication -DatabaseName "Secure_Store_Service_DB" -Name "SecureStore" -ApplicationPool "SecureStore" -AuditingEnabled:$false

# Wait for the timer jobs to run
Start-Sleep -Seconds 10

Write-Host "Creating the Secure Store Service application proxy..." -ForegroundColor Green
$SSAppProxy = New-SPSecureStoreServiceApplicationProxy -Name "Secure Store Service Application Proxy" -ServiceApplication $SSApp
Write-Host "Setting the Master Key..." -ForegroundColor Green
Update-SPSecureStoreMasterKey -Passphrase 'P@ssphr@se' -ServiceApplicationProxy $SSAppProxy

# Create the CourseInfo target application
Write-Host "Creating the target application..." -ForegroundColor Green                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
$UserNameField = new-spsecurestoreapplicationfield -name "UserName" -type WindowsUserName -masked:$false
$PasswordField = new-spsecurestoreapplicationfield -name "Password" -type WindowsPassword -masked:$true
 
$fields = $UserNameField, $PasswordField
 
$targetApp = new-spsecurestoretargetapplication -Name "CourseInfo" -FriendlyName "CourseInfo" `
                -ContactEmail "SPFarmAdmin@LOCALDOMAIN.COM" -ApplicationType Group
 
$targetAppAdminAccount = New-SPClaimsPrincipal -Identity "LOCALDOMAIN\SPFarmAdmin" -IdentityType WindowsSamAccountName
$targetMembersClaim = New-SPClaimsPrincipal -EncodedClaim "c:0(.s|true"
 
$defaultServiceContext = Get-SPServiceContext "http://ltree.localdomain.com"
                                                     
$ssApp = new-spsecurestoreapplication -ServiceContext $defaultServiceContext -TargetApplication $targetApp -Administrator $targetAppAdminAccount -Fields $fields -CredentialsOwnerGroup $targetMembersClaim


#endregion

[void][System.Windows.Forms.MessageBox]::Show("Solution script is complete.","Solution Script")
