#========================================================================
# Created with: SAPIEN Technologies, Inc., PowerShell Studio 2012 v3.1.19
# Created on:   8/1/2013 6:40 AM
# Created by:   Shane Cribbs
# Organization: 
# Filename:     
#========================================================================

#region Customizations

#========================================================================
$bInstalliSCSI = $False # Set to $TRUE or $FALSE
$NewComputerName = "ADSrv"
$DomainNetBIOS = "mydomain"
$DomainFQDN = "mydomain.local"
$LocalAdminPassword = "Password1"
$DomainAdminPassword = "Password1"
$EthernetIPv4 = "10.1.1.200"
$EthernetDG = "10.1.1.254"
$EthernetIPv4SubnetSize = "24" # 24=255.255.255.0 16=255.255.0.0 8=255.0.0.0
$UserPassword = "Password1" #Password for AD standard user accounts
$AdminPassword = "Password2" #Password for AD administrative accounts
#========================================================================

#endregion


Import-Module ServerManager
Import-Module Storage
Import-Module ActiveDirectory

function Enable-AutoLogon {
	[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$true)]
		[System.String]
		$UserName,
		[Parameter(Position=1)]
		[System.String]
		$Password,
		[Parameter(Position=2, Mandatory=$true)]
		[System.String]
		$Domain
	)
	Write-Verbose "Entered Enable-AutoLogon function"
	
	$WL_Key = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WinLogon"

	If(((Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WinLogon').AutoAdminLogon) -eq 1){
		Set-ItemProperty -Path $WL_Key -Name AutoAdminLogon -Value 1
		Set-ItemProperty -Path $WL_Key -Name DefaultUserName -Value $Username
		Set-ItemProperty -Path $WL_Key -Name DefaultPassword -Value $Password
		Set-ItemProperty -Path $WL_Key -Name DefaultDomainName -Value $Domain
	}
	Else{
		New-ItemProperty -Path $WL_Key -Name AutoAdminLogon -Value 1
		New-ItemProperty -Path $WL_Key -Name DefaultUserName -Value $Username
		New-ItemProperty -Path $WL_Key -Name DefaultPassword -Value $Password
		New-ItemProperty -Path $WL_Key -Name DefaultDomainName -Value $Domain
	}
} 

function Disable-AutoLogon {
	
	Write-Verbose "Entered Disable-AutoLogon function."
	
	$WL_Key = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WinLogon"

	New-ItemProperty -Path $WL_Key -Name AutoAdminLogon -Value 0
	New-ItemProperty -Path $WL_Key -Name DefaultPassword -Value ""
}

function Populate-ADAccounts ($NumberOfAdmins=50, $NumberOfUsers=50) {
	
	# Build the core AD objects
	$DNC = (Get-ADRootDSE).defaultNamingContext
	If (-not(Test-Path "AD:\ou=Course Accounts,$DNC")){
		New-ADOrganizationalUnit -Name "Course Accounts" -Path $DNC
	}
	
	# Create the standard user accounts
	Write-Host "Creating UserX accounts..."
	If ($NumberOfAdmins -gt 0){
		for($i=1;$i -le $NumberOfUsers;$i++){
			$UserPWSS = ConvertTo-SecureString -String $UserPassword -AsPlainText -Force
			New-ADUser -Name "User$i" `
					   -SamAccountName "User$i" `
					   -Path "ou=Course Accounts,$dnc" `
					   -AccountPassword $UserPWSS `
			           -PasswordNeverExpires $true `
					   -Enabled $true `
					   -DisplayName "User$i" `
					   -UserPrincipalName "User$i@$DomainFQDN"
		}
	}
	
	# Create the AdminX accounts
	Write-Host "Creating the AdminX accounts..."
	If ($NumberOfUsers -gt 0){
		for($i=1;$i -le $NumberOfAdmins;$i++){
			$AdminPWSS = ConvertTo-SecureString -String $AdminPassword -AsPlainText -Force
			New-ADUser -Name "Admin$i" `
					   -SamAccountName "Admin$i" `
					   -Path "ou=Course Accounts,$dnc" `
					   -AccountPassword $AdminPWSS `
			           -PasswordNeverExpires $true `
					   -Enabled $true `
					   -DisplayName "Admin$i" `
					   -UserPrincipalName "Admin$i@$DomainFQDN"
		}
	}
	
	#Add the AdminX accounts to the Domain Admins group
		Write-Host "Granting AdminX accounts administrative rights..."
		If ($NumberOfUsers -gt 0){
		New-ADGroup -Name "Course Admins" -Path "OU=Course Accounts,$DNC" -GroupCategory Security -GroupScope Global
		Add-ADGroupMember -Identity "Domain Admins" -Members "Course Admins"
		
		for($i=1;$i -le $NumberOfAdmins;$i++){
			Add-ADGroupMember -Identity "Course Admins" -Members "Admin$i"
		}
	}
	
}

# Script Logic Starts Here


#region Add script to auto run
If(-not(Test-Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\ConfigureLoad.lnk")){
	Write-Verbose "Creating shortcut to script in common StartUp folder..."
	$ScriptPathName = $MyInvocation.MyCommand.Path
	$objShell = New-Object -ComObject "Wscript.Shell"
	$objNewShortcut = $objShell.CreateShortcut("C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\ConfigureLoad.lnk")
	$objNewShortcut.TargetPath = "PowerShell.exe"
    $objNewShortcut.Arguments = $ScriptPathName
	$objNewShortcut.Save()
}
#endregion

#region Enable Auto Admin Logon for Local Administrator
If(((Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WinLogon').AutoAdminLogon) -ne 1){
	Enable-AutoLogon -UserName "Administrator" -Password $LocalAdminPassword -Domain $Env:COMPUTERNAME
}
#endregion

#region Configure core server settings (name, ip, etc.)

#IP Settings
New-NetIPAddress -IPAddress $EthernetIPv4 -InterfaceAlias "Ethernet" -DefaultGateway $EthernetDG -AddressFamily IPv4 -PrefixLength $EthernetIPv4SubnetSize
#Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 10.10.10.1

#Rename Computer
If (($env:COMPUTERNAME) -ine $NewComputerName){
	Write-Verbose "Renaming computer to $NewComputerName"
	Rename-Computer -NewName $NewComputerName
	Restart-Computer
}

#If not a domain controller, join the domain
#Add-Computer -DomainName $DomainFQDN

#endregion


# Install necessary roles
Write-Host "Adding the ADDS role and management tools..."

Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

If ($ENV:USERDOMAIN -ne $DomainNetBIOS){
	Write-Host "Creating the AD Forest..."
	$RecoveryPasswordSS = ConvertTo-SecureString -String $LocalAdminPassword -AsPlainText -Force
	Install-ADDSForest -DomainName "course.local" -SafeModeAdministratorPassword $RecoveryPasswordSS -Force
}
	
# Configure AD
Populate-ADAccounts

# Perform final configuration tasks
# Add iSCSI Target
If ($bInstalliSCSI){
	Install-WindowsFeature FS-iSCSITarget-Server -IncludeManagementTools
	Install-WindowsFeature iSCSITarget-VSS-VDS -IncludeManagementTools
	Install-WindowsFeature WindowsStorageManagementService
}

# Prepare the N: drive
If ((Get-Disk -Number 1).OperationalStatus -ieq "Offline"){
	Write-Host "Preparing the N: drive..."
	"select disk 1","online disk" | diskpart
	Initialize-Disk -Number 1 -PartitionStyle GPT -ErrorAction 'SilentlyContinue'
}
If((Get-Partition -DiskNumber 1).count -le 1){
	New-Partition -DiskNumber 1 -UseMaximumSize -DriveLetter "N" | Format-Volume -NewFileSystemLabel "Data" -Force -Confirm:$false
}

# Remove this script from autorun
Write-Host "`r`nRemoving the ConfigureLoad script from startup..."
# Disable Auto Admin Logon
#Disable-AutoLogon

Write-Host "Script has completed"
Write-Host "`r`nDon't forget to change the default domain policy to never expire passwords."

Start-Sleep -Seconds 10