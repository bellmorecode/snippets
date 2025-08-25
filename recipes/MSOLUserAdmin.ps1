# Script requires:
#   Microsoft Online Services Sign-In Assistant
#   Azure Active Directory Module for Windows PowerShell

#********************************

$intNumUsersToCreate = 20
$CRMSubDomain = "course4674"


#********************************

# Authenticate to Office 365 Admin Center
Connect-MsolService

# Get a list of active SKUs
#Get-MsolAccountSku

# Get a list of active Users
#Get-MsolUser

# Get a list of users whose name or email starts with "CRM"
#Get-MsolUser -SearchString "CRM"

# Remove a user
#Remove-MsolUser -UserPrincipalName CRMUser1@crmintro.onmicrosoft.com -Force

#region Create new users

$OutputPath = "$PSCriptRoot\CRMUsers.csv"
$Global:NewUsers = @()

For ($i=1;$i -le $intNumUsersToCreate; $i++){
    $NewUser = New-MsolUser -UserPrincipalName "CRMUser$i@$CRMSubDomain.onmicrosoft.com" `
                 -ForceChangePassword $false `
                 -Password "Password7" `
                 -PasswordNeverExpires $true `
                 -DisplayName "CRM User $i" `
                 -FirstName "CRM User $i" `
                 -LicenseAssignment "$($CRMSubDomain):CRMSTANDARD" -UsageLocation "US"

                 $Global:NewUsers = $Global:NewUsers + $NewUser
}

$NewUser = New-MsolUser -UserPrincipalName "Admin@$CRMSubDomain.onmicrosoft.com" `
                -ForceChangePassword $false `
                -Password "Password7" `
                -PasswordNeverExpires $true `
                -DisplayName "Admin" `
                -FirstName "Admin" `
                -LicenseAssignment "$($CRMSubDomain):CRMSTANDARD" -UsageLocation "US"

                $Global:NewUsers = $Global:NewUsers + $NewUser

# Export the results
$NewUsers | Select-Object -Property UserPrincipalName,Password,IsLicensed,UsageLocation |  Export-Csv -Path $OutputPath -NoTypeInformation
 
 #endregion
