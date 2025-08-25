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

 # Check for the ServiceApps app pool from 4.1
    If (!(Get-SPServiceApplicationPool | Where-Object {$_.Name -ieq "ServiceApps"})){
    	[void][System.Windows.Forms.MessageBox]::Show("Missing ServiceApps service application pool.  Complete exercise 4.1 `nbefore proceeding.`n`n SCRIPT ABORTING","Script Aborted")
	    Exit
    }

 # Start the PerformancePoint Service
    $PPService = Get-SPServiceInstance | Where-Object {$_.TypeName -ieq "PerformancePoint Service"}
    $ServiceGUID = $PPService.Id

    # Start and wait on the Business Data Connectivity Server service
    If ($PPService.Status -ieq "Disabled")
       {
       Write-Host "Starting the PerformancePoint service..." -ForegroundColor Green
       Start-SPServiceInstance -Identity $ServiceGUID
       While ($PPService.Status -ine "Online"){
           Start-Sleep -Seconds 2
           $PPService = Get-SPServiceInstance -Identity $ServiceGUID
          }
       Write-Host "Started the PerformancePoint service..." -ForegroundColor Green
       }


 # Add Performance Point Service App and Proxy
  Write-Host "Creating the PerformancePoint service application and proxy..." -ForegroundColor Green
  New-SPPerformancePointServiceApplication -Name "PerformancePoint" -DatabaseServer "LTREE" -DatabaseName "PerformancePoint" -ApplicationPool "ServiceApps"
  New-SPPerformancePointServiceApplicationProxy -Name "PerformancePoint" -ServiceApplication "PerformancePoint" -Default

 # Set the PerformancePoint Unattended Service Account
   Write-Host "Setting the Unattended Service Account..." -ForegroundColor Green
   Set-SPPerformancePointSecureDataValues -ServiceApplication "PerformancePoint" -DataSourceUnattendedServiceAccount (New-Object System.Management.Automation.PSCredential "LOCALDOMAIN\SPFarmAdmin", (ConvertTo-SecureString "pw" -AsPlainText -Force))

 # Create a web app named BusinessCenter on 22000
    If ((Get-SPWebApplication -Identity BusinessCenter -ErrorAction SilentlyContinue).count -eq 0){
	# Create Authentication Provider
	$AuthProvider = New-SPAuthenticationProvider -UseWindowsIntegratedAuthentication

	#Create new Web Application
	Write-Host "Creating the BusinessCenter Web Application..." -ForegroundColor Green
	New-SPWebApplication `
	    -Name "BusinessCenter"  `
	    -ApplicationPool "LTREE" `
	    -Port 22000 `
	    -DatabaseServer "LTREE" `
	    -DatabaseName "BusinessCenter" `
	    -AuthenticationProvider $AuthProvider
	
}
ELSE {Write-Host "BusinessCenter WebApp already exists, skipping..." -ForegroundColor 'Red'}

 # Create a site collection using the Business Intelligence Center template
  Write-Host "Creating the Business Intelligence Center site collection..." -ForegroundColor Green
  $BITemplate = Get-SPWebTemplate -CompatibilityLevel 15 | Where-object {$_.Title -ieq "Business Intelligence Center"}
  New-SPSite -Url "http://ltree:22000/" -OwnerAlias "LOCALDOMAIN\SPFarmAdmin" -Name "Learning Tree BI Center" -CompatibilityLevel 15 -Template $BITemplate

#endregion

[void][System.Windows.Forms.MessageBox]::Show("Solution script is complete.`n `nYou may now create a data connection and`nscorecard to complete the exercise.","Solution Script")
