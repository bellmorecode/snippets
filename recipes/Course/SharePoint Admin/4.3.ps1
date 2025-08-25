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
Write-Host "Loading the SharePoint snapin..." -ForegroundColor Green
Add-PSSnapin -Name "Microsoft.SharePoint.PowerShell"

#region Exercise Logic starts here

#region Check pre-reqs
  # Secure Store and Managed Metadata from DoNow
     $SSService = Get-SPServiceInstance | Where-Object {$_.TypeName -ieq "Secure Store Service"}
    $SSGUID = $SSService.Id

    # Start and wait on the Secure Store Service
    If ($SSService.Status -ieq "Disabled")
       {
        # Do the Chapter 4 Do Now
        [void][System.Windows.Forms.MessageBox]::Show("The required Do Now has not been completed.","ERROR")
        Exit
       }

  # My Sites in 3.1

  # ServiceApps pool
  If (((Get-SPServiceApplicationPool | Where-Object {$_.Name -ieq "ServiceApps"}).count) -ne 1)
           {
        # Do exercise 4.1
        [void][System.Windows.Forms.MessageBox]::Show("Exercise 4.1 has not been completed.  Missing ServiceApps pool.","ERROR")
        Exit
       }

#endregion

#region Start the User Profile Service
$UPService = Get-SPServiceInstance | Where-Object {$_.TypeName -ieq "User Profile Service"}
$ServiceGUID = $UPService.Id

# Start and wait on the User Profile Service
    If ($UPService.Status -ieq "Disabled")
       {
       Write-Host "Starting the User Profile Service..." -ForegroundColor Green
       Start-SPServiceInstance -Identity $ServiceGUID 
       While ($UPService.Status -ine "Online"){
           Start-Sleep -Seconds 2
           $UPService = Get-SPServiceInstance -Identity $ServiceGUID
          }
       Write-Host "Started the User Profile Service..." -ForegroundColor Green
       }
       Else
       {Write-Host "User Profile Service was not disabled.  Proceeding..." -ForegroundColor Green}
#endregion

#region Create New User Profile Service Application as SPFarmService
    
    Write-Host "Creating Profile Service Application and Profile Service Proxy Application..." -ForegroundColor Green
    $NSAScript = {
        Write-Host "Entering Job as SPFarmService..."
        Add-PSSnapin -Name "Microsoft.SharePoint.PowerShell"
        
        $MySites = get-spsite | Where {$_.WebApplication -ilike "*MySites"}
        Write-Host "Creating Profile Service Application..."
        $UPSApp = New-SPProfileServiceApplication -Name "UserProfile" -ApplicationPool "ServiceApps" -MySiteHostLocation $MySites -ProfileDBServer "LTREE" -ProfileDBName "Profile DB" -ProfileSyncDBServer "LTREE" -ProfileSyncDBName "Sync DB" -SocialDBServer "LTREE" -SocialDBName "Social DB"

        Write-Host "Creating Profile Service Proxy Application..."
        New-SPProfileServiceApplicationProxy -Name "UserProfile" -DefaultProxyGroup -ServiceApplication $UPSApp

        }

    $username = "LOCALDOMAIN\SPFarmService"
    $password = ConvertTo-SecureString -String "pw" -AsPlainText -Force
    $cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username,$password
    $job = Start-Job -Credential $cred -ScriptBlock $NSAScript -ArgumentList ([environment]::CurrentDirectory="C:\") | Wait-Job

    If ($job.State -ieq "Failed")
    {        
    [void][System.Windows.Forms.MessageBox]::Show("Creation of User Profile Service Application as SPFarmService failed.","ERROR")
        Exit
    }

#endregion

#region Configure and start the User Profile Synchronization Service
Write-Host "Configuring and starting the User Profile Synchronization Service..." -ForegroundColor Green
$UPSService = Get-SPServiceInstance | Where-Object {$_.TypeName -ieq "User Profile Synchronization Service"}
$UPSServiceGUID = $UPSService.Id

$FarmServicePassword = ConvertTo-SecureString -AsPlainText -String "pw" -Force
$UPSApp = Get-SPServiceApplication -Name "UserProfile"
$UPSApp.SetSynchronizationMachine("LTREE",$UPSServiceGUID,"LOCALDOMAIN\SPFarmService",$FarmServicePassword)



# Start and wait on the User Profile Service
If ($UPSService.Status -ieq "Disabled")
    {
    Start-SPServiceInstance -Identity $UPSServiceGUID | Out-Null
    }

Write-Host "Starting the User Profile Synchronization Service.  Be PATIENT..." -ForegroundColor Green -NoNewline
While ($UPSService.Status -ine "Online"){
    Write-Host "." -ForegroundColor Green -NoNewline
    Start-Sleep -Seconds 5
    $UPSService = Get-SPServiceInstance -Identity $UPSServiceGUID
    }
Write-Host ".done." -ForegroundColor Green
Write-Host "Started the User Profile Synchronization Service..." -ForegroundColor Green

#endregion


#region Create AD Users
    Write-Host "Creating AD users Attendee1 and Attendee2..." -ForegroundColor Green
    Import-Module -Name ActiveDirectory
    New-ADUser -Name "Attendee1" -Path "OU=CourseUsers,DC=LOCALDOMAIN,DC=com" -GivenName "Attendee" -Surname "1" -SamAccountName "Attendee1" -Enabled $true -ChangePasswordAtLogon $false -AccountPassword (ConvertTo-SecureString -AsPlainText "pw" -Force) -PasswordNeverExpires $true -Department "Department from AD" -Title "Title from AD" -HomePhone "Home from AD" -UserPrincipalName "Attendee1@localdomain.com" -DisplayName "Attendee1"
    New-ADUser -Name "Attendee2" -Path "OU=CourseUsers,DC=LOCALDOMAIN,DC=com" -GivenName "Attendee" -Surname "2" -SamAccountName "Attendee2" -Enabled $true -ChangePasswordAtLogon $false -AccountPassword (ConvertTo-SecureString -AsPlainText "pw" -Force) -PasswordNeverExpires $true -Department "Department from AD" -Title "Title from AD" -HomePhone "Home from AD" -UserPrincipalName "Attendee2@localdomain.com" -DisplayName "Attendee2"
#endregion

#Configure the Profile Service

#Create a Synchronization Connection

#endregion

[void][System.Windows.Forms.MessageBox]::Show("Solution script has completed inital steps.`n`r`n`rIn order to see the solution, you will need to manually complete the exercise starting from: `n`rConfigure the Profile Service for synchronization","Solution Script")
