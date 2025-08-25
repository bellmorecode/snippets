###############################################################################################################
##
## Epona365 deployment script - 1.1
## 
###############################################################################################################
#
# Prerequisites:
#     Use PowerShell 7
#
#     Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
#     Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
#
#     Import-Module -Name Az
#     Import-Module -Name Az.KeyVault
#
#     Connect-AzAccount
#
# Example: 
#     .\Assert-Epona365Apps.ps1 -Prefix <prefix> -ApplicationUrl "https://<url>"
###############################################################################################################

Param(
    [Parameter(Mandatory, HelpMessage="Enter the prefix that was used when deploying the Epona365 offer from the Azure Marketplace.")]
    [ValidateLength(3,5)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Prefix,

    [Parameter(Mandatory, HelpMessage="Enter the application url of the (web-app) Azure Container App.")]
    [ValidateNotNullOrEmpty()]
    [string]
    $ApplicationUrl,

    [Parameter(HelpMessage="Limit the scope of this script to only EntraID apps.")]
    [Switch]
    $OnlyEntraId,

    [Parameter(HelpMessage="Reapply permissions even if the apps already exists.")]
    [Switch]
    $ForceApplyPermissions,

    [Parameter()]
    [AllowNull()]
    [string]
    $Channel = $null
)

# Check the powershell version.
if ( $PSVersionTable.PSVersion -lt ( New-Object Version 7.2 ) )
{
    throw "PowerShell 7.2 or higher is required."
}

# Load the Azure module.
$module = Get-Module -ListAvailable -Name Az | Where-Object { $_.Version -ge [Version]"7.5.0" }

if ( -not $module )
{
    Write-Host "Az module not found. Please install it with:" -ForegroundColor Yellow
    Write-Host "    Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force" -ForegroundColor Yellow
    return;
}

# Check whether the app "Epona365 api" exists in AzureAD. Create the app if it is missing.
function Assert-ApiApp
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $Name,

        [Parameter(Mandatory)]
        [string]
        $Authority
    )

    $graphResourceAccess = @{
        ResourceAppId = "00000003-0000-0000-c000-000000000000"  # Microsoft Graph
        ResourceAccess = @(
            @{
                Id = "64a6cdd6-aab1-4aaf-94b8-3cc8405e90d0"     # email
                Type = "Scope"
            },
            @{
                Id = "14dad69e-099b-42c9-810b-d002981feec1"     # profile
                Type = "Scope"
            },
            @{
                Id = "37f7f235-527c-4136-accd-4a02d197296e"     # openid
                Type = "Scope"
            },
            @{
                Id = "7427e0e9-2fba-42fe-b0c0-848c9e6a8182"     # offline_access
                Type = "Scope"
            },
            @{
                Id = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"     # User.Read
                Type = "Scope"
            },
            @{
                Id = "a154be20-db9c-4678-8ab7-66f6cc099a59"     # User.Read.All
                Type = "Scope"
            },
            @{
                Id = "bc024368-1153-4739-b217-4326f2e966d0"     # GroupMember.Read.All
                Type = "Scope"
            },
            @{
                Id = "024d486e-b451-40bb-833d-3e66d98c5c73"     # Mail.ReadWrite
                Type = "Scope"
            },
            @{
                Id = "5df07973-7d5d-46ed-9847-1271055cbd51"     # Mail.ReadWrite.Shared
                Type = "Scope"
            },
            @{
                Id = "818c620a-27a9-40bd-a6a5-d96f7d610b4b"     # MailboxSettings.ReadWrite
                Type = "Scope"
            },
            @{
                Id = "89fe6a52-be36-487e-b7d8-d061c450a026"     # Sites.ReadWrite.All
                Type = "Scope"
            },
            @{
                Id = "332a536c-c7ef-4017-ab91-336970924f0d"     # Sites.Read.All
                Type = "Role"
            },
            @{
                Id = "9492366f-7969-46a4-8d15-ed1a20078fff"     # Sites.ReadWrite.All
                Type = "Role"
            }
        )
    }

    $sharePointResourceAccess = @{
        ResourceAppId = "00000003-0000-0ff1-ce00-000000000000"  # SharePoint
        ResourceAccess = @(
            @{
                Id = "fbcd29d2-fcca-4405-aded-518d457caae4"     # Sites.ReadWrite.All
                Type = "Role"
            }
        )
    }

    $resourceAccess = @($graphResourceAccess, $sharePointResourceAccess)

    $apiApp = Get-AzADApplication -DisplayName $Name

    if ( $null -eq $apiApp )
    {
        Write-Host "The app '$Name' does not yet exist."

        Write-Host "Creating app '$Name'..."

        $apiGuid = New-Guid

        [Microsoft.Azure.PowerShell.Cmdlets.Resources.MSGraph.Models.ApiV10.IMicrosoftGraphApiApplication]$apiProperties = @{ 
            Oauth2PermissionScope = [Microsoft.Azure.PowerShell.Cmdlets.Resources.MSGraph.Models.ApiV10.IMicrosoftGraphPermissionScope]@{ 
                AdminConsentDescription = "Allows the app to access the Epona365 api as the signed-in user."
                AdminConsentDisplayName = "Access Epona365 api"
                IsEnabled = $true
                Type = "Admin"
                UserConsentDescription = "Allows the app to access the Epona365 api on your behalf."
                UserConsentDisplayName = "Access Epona365 api"
                Value = "access_as_user"
                Id = $apiGuid.Guid
            }
            PreAuthorizedApplication = @(
                @{
                    AppId = "ea5a67f6-b6f3-4338-b240-c655ddc3cc8e" # All Microsoft Office application endpoints
                    DelegatedPermissionId = @( $apiGuid )
                },
                @{
                    AppId = "d3590ed6-52b3-4102-aeff-aad2292ab01c" # Microsoft Office
                    DelegatedPermissionId = @( $apiGuid )
                },
                @{
                    AppId = "93d53678-613d-4013-afc1-62e9e444a0a5" # Office on the web
                    DelegatedPermissionId = @( $apiGuid )
                },
                @{
                    AppId = "bc59ab01-8403-45c6-8796-ac3ef710b3e3" # Outlook on the web
                    DelegatedPermissionId = @( $apiGuid )
                }
            )
            RequestedAccessTokenVersion = 2            
        }

        [Microsoft.Azure.PowerShell.Cmdlets.Resources.MSGraph.Models.ApiV10.IMicrosoftGraphOptionalClaims]$optionalClaim = @{
            AccessToken = [Microsoft.Azure.PowerShell.Cmdlets.Resources.MSGraph.Models.ApiV10.IMicrosoftGraphOptionalClaim]@{
                Name = "groups"
                Essential = $false
            }
            IdToken = [Microsoft.Azure.PowerShell.Cmdlets.Resources.MSGraph.Models.ApiV10.IMicrosoftGraphOptionalClaim]@{
                Name = "groups"
                Essential = $false
            }
            Saml2Token = [Microsoft.Azure.PowerShell.Cmdlets.Resources.MSGraph.Models.ApiV10.IMicrosoftGraphOptionalClaim]@{
                Name = "groups"
                Essential = $false
            }
        }

        $apiApp = New-AzADApplication `
            -DisplayName $Name `
            -AvailableToOtherTenants $false `
            -RequiredResourceAccess $resourceAccess `
            -Api $apiProperties `
            -GroupMembershipClaim "DirectoryRole" `
            -OptionalClaim $optionalClaim

        # Set the remaining properties that cannot be set by New-AzADApplication.
        Update-AzADApplication `
            -ApplicationId $apiApp.AppId `
            -IdentifierUri "api://$Authority/$($apiApp.AppId)"

        Write-Host "Finished creating app '$($apiApp.DisplayName)' (client id: $($apiApp.AppId))."
    }
    else
    {
        Write-Host "Found the app '$($apiApp.DisplayName)' in AzureAD (client id: $($apiApp.AppId))." -ForegroundColor Green

        # Apply the permissions.
        if ( $ForceApplyPermissions )
        {
            Write-Host "Applying the permissions for app '$($apiApp.DisplayName)' (client id: $($apiApp.AppId))..."

            Update-AzADApplication `
                -ApplicationId $apiApp.AppId `
                -RequiredResourceAccess $resourceAccess

            Write-Host "Finished applying the permissions for app '$($apiApp.DisplayName)' (client id: $($apiApp.AppId))."
        }
    }

    return $apiApp;
}

# Check whether the app "Epona365 app" exists in AzureAD. Create the app if it is missing.
function Assert-SpaApp
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $Name,

        [Parameter(Mandatory)]
        [string]
        $Authority,

        [Parameter(Mandatory)]
        $ApiApp
    )

    $spaApp = Get-AzADApplication -DisplayName $Name

    if ( $null -eq $spaApp )
    {
        Write-Host "The app '$Name' does not yet exist."

        Write-Host "Creating app '$Name'..."

        $resourceAccess = $(
            @{
                ResourceAppId = $ApiApp.AppId                          # Epona365 api
                ResourceAccess = @(
                    @{
                        Id = $ApiApp.Api.Oauth2PermissionScope.Id      # access_as_user 
                        Type = "Scope"
                    }           
                )
            }
            @{
                ResourceAppId = "00000003-0000-0000-c000-000000000000" # Microsoft Graph
                ResourceAccess = @(
                    @{
                        Id = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"    # User.Read
                        Type = "Scope"
                    }           
                )
            }
        )

        $spaApp = New-AzADApplication `
            -DisplayName $Name `
            -AvailableToOtherTenants $false `
            -SPARedirectUri @( "https://$Authority/portal" ) `
            -RequiredResourceAccess $resourceAccess

        Write-Host "Finished creating app '$($spaApp.DisplayName)' (client id: $($spaApp.AppId))."
    }
    else
    {
        Write-Host "Found the app '$($spaApp.DisplayName)' in AzureAD (client id: $($spaApp.AppId))." -ForegroundColor Green
    }

    return $spaApp;
}

function Assert-KeyVault
{
    # Ensure azure keyvault prerequisite.
    $settingsKeyvault = Get-AzKeyVault -VaultName $settingsKeyvaultName

    if ( $null -eq $settingsKeyVault )
    {
        Write-Host ""
        Write-Host "Keyvault $settingsKeyvaultName is either inaccessible or does not exist." -ForegroundColor Red
        Write-Host ""
        Write-Host "To resolve this issue:" -ForegroundColor Yellow
        Write-Host "1. If you lack access to the keyvault, please request access from your administrator." -ForegroundColor Yellow
        Write-Host "2. If the keyvault does not exist, deploy the Epona365 offering from the Azure Marketplace." -ForegroundColor Yellow
        Write-Host "3. If the keyvault is in a different subscription, switch to the correct subscription using:" -ForegroundColor Yellow
        Write-Host "    Set-AzContext -Subscription <SubscriptionId>"  -ForegroundColor Yellow
        Write-Host "    Use Get-AzSubscription to list available subscriptions." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "If you wish to proceed with the next step (creating EntraID apps) without updating the keyvault, rerun the script with the '-OnlyEntraId' argument. Using this argument requires several manual steps afterwards." -ForegroundColor Yellow
        Write-Host ""
        return $false
    }

    Write-Host "Found keyvault $settingsKeyvaultName." -ForegroundColor Green

    # Ensure that the user has the 'Key Vault Secrets Officer' role assignment.
    $roleAssignment = Get-AzRoleAssignment -SignInName $($(Get-AzContext).Account.Id) -Scope $($settingsKeyvault.ResourceId) -RoleDefinitionName 'Key Vault Secrets Officer'

    if ( $null -eq $roleAssignment )
    {
        Write-Host "No 'Key Vault Secrets Officer' role assignment found for $settingsKeyvaultName."

        Write-Host "Creating role assignment..."
        $roleAssignment = New-AzRoleAssignment -SignInName $($(Get-AzContext).Account.Id) -Scope $($settingsKeyvault.ResourceId) -RoleDefinitionName 'Key Vault Secrets Officer'

        if ( $null -eq $roleAssignment )
        {
            Write-Host "Failed to create role assignment." -ForegroundColor Red
            Write-Host
            Write-Host "Please give yourself 'Key Vault Secrets Officer' access to keyvault $settingsKeyvaultName." -ForegroundColor Red
            Write-Host "For example: New-AzRoleAssignment -SignInName $($(Get-AzContext).Account.Id) -Scope $($settingsKeyvault.ResourceId) -RoleDefinitionName 'Key Vault Secrets Officer'" -ForegroundColor Red
            return $false
        }

        Write-Host "Finished creating role assignment." -ForegroundColor Green
    }
    else
    {
        Write-Host "Found role assignment 'Key Vault Secrets Officer' for $settingsKeyvaultName." -ForegroundColor Green
    }

    # Ensure that the user has the 'Key Vault Certificates Officer' role assignment.
    $roleAssignment = Get-AzRoleAssignment -SignInName $($(Get-AzContext).Account.Id) -Scope $($settingsKeyvault.ResourceId) -RoleDefinitionName 'Key Vault Certificates Officer'

    if ( $null -eq $roleAssignment )
    {
        Write-Host "No 'Key Vault Certificates Officer' role assignment found for $settingsKeyvaultName."

        Write-Host "Creating role assignment..."
        $roleAssignment = New-AzRoleAssignment -SignInName $($(Get-AzContext).Account.Id) -Scope $($settingsKeyvault.ResourceId) -RoleDefinitionName 'Key Vault Certificates Officer'

        if ( $null -eq $roleAssignment )
        {
            Write-Host "Failed to create role assignment." -ForegroundColor Red
            Write-Host
            Write-Host "Please give yourself 'Key Vault Certificates Officer' access to keyvault $settingsKeyvaultName." -ForegroundColor Red
            Write-Host "For example: New-AzRoleAssignment -SignInName $($(Get-AzContext).Account.Id) -Scope $($settingsKeyvault.ResourceId) -RoleDefinitionName 'Key Vault Certificates Officer'" -ForegroundColor Red
            return $false
        }

        Write-Host "Finished creating role assignment." -ForegroundColor Green
    }
    else
    {
        Write-Host "Found role assignment 'Key Vault Certificates Officer' for $settingsKeyvaultName." -ForegroundColor Green
    }

    return $true
}

function Assert-KeyVaultSecrets
{
    # Ensure secret 'AppClientId'
    try
    { 
        $AppClientIdKeyvaultSecret = Get-AzKeyVaultSecret -VaultName $settingsKeyvaultName -Name "AppClientId" -ErrorAction Stop

        if ( $null -eq $AppClientIdKeyvaultSecret )
        {
            Write-Host "Creating secret 'AppClientId' in keyvault $settingsKeyvaultName..."
            $AppClientIdKeyvaultSecret = Set-AzKeyVaultSecret -VaultName $settingsKeyvaultName -Name "AppClientId" -SecretValue (ConvertTo-SecureString -String $spaApp.AppId -AsPlainText -Force)

            if ( $null -eq $AppClientIdKeyvaultSecret )
            {
                Write-Host "Failed to create secret 'AppClientId' in keyvault $settingsKeyvaultName." -ForegroundColor Red
                return $false
            }

            Write-Host "Finished creating secret 'AppClientId' in keyvault $settingsKeyvaultName." -ForegroundColor Green
        }
        else
        {
            Write-Host "Found secret 'AppClientId' in keyvault $settingsKeyvaultName." -ForegroundColor Green        
        }
    }
    catch
    {
        Write-Host "Failed to access the keyvault." -ForegroundColor Red
        Write-Host "Please add your ip address to the firewall settings (Azure Portal -> $settingsKeyvaultName -> Networking -> Firewall -> Add your client IP address)" -ForegroundColor Yellow
        Write-Host "Original error:" -ForegroundColor White
        Write-Host $_ -ForegroundColor White
        return $false
    }

    # Ensure secret 'ApiClientId'
    try
    { 
        $apiClientIdKeyvaultSecret = Get-AzKeyVaultSecret -VaultName $settingsKeyvaultName -Name "ApiClientId" -ErrorAction Stop

        if ( $null -eq $apiClientIdKeyvaultSecret )
        {
            Write-Host "Creating secret 'ApiClientId' in keyvault $settingsKeyvaultName..."
            $apiClientIdKeyvaultSecret = Set-AzKeyVaultSecret -VaultName $settingsKeyvaultName -Name "ApiClientId" -SecretValue (ConvertTo-SecureString -String $apiApp.AppId -AsPlainText -Force)

            if ( $null -eq $apiClientIdKeyvaultSecret )
            {
                Write-Host "Failed to create secret 'ApiClientId' in keyvault $settingsKeyvaultName." -ForegroundColor Red
                return $false
            }

            Write-Host "Finished creating secret 'ApiClientId' in keyvault $settingsKeyvaultName." -ForegroundColor Green
        }
        else
        {
            Write-Host "Found secret 'ApiClientId' in keyvault $settingsKeyvaultName." -ForegroundColor Green        
        }
    }
    catch
    {
        Write-Host "Failed to access the keyvault." -ForegroundColor Red
        Write-Host "Please add your ip address to the firewall settings (Azure Portal -> $settingsKeyvaultName -> Networking -> Firewall -> Add your client IP address)" -ForegroundColor Yellow
        Write-Host "Original error:" -ForegroundColor White
        Write-Host $_ -ForegroundColor White
        return $false
    }

    # Check the existing certificates that are configured in the api app.
    [string[]] $validThumbprints = @()
    [string[]] $expiredThumbprints = @()

    try
    {
        $apiAppCredentials = ( Get-AzADAppCredential -ObjectId $apiApp.Id ).Where( { $_.DisplayName -eq "CN=epona365" } )
        
        $today = (Get-Date).ToUniversalTime()
        $limitDate = $today.AddDays( 180 )

        ForEach( $apiAppCredential in $apiAppCredentials )
        {
            $customKeyIdentifier = $apiAppCredential.CustomKeyIdentifier

            try
            {
                $thumbprint = [Convert]::ToBase64String( $customKeyIdentifier )

                if ( $apiAppCredential.EndDateTime -ge $limitDate )
                {
                    $validThumbprints += $thumbprint
                }
                else
                {
                    $expiredThumbprints += $thumbprint
                }
            }
            catch
            {            
            }
        }
    }
    catch
    {
        Write-Host $_ -ForegroundColor Red
        return $false
    }

    # Ensure certificate 'ApiClientCertificate'
    $apiClientX509Certificate = $null

    try
    {
        $needsNewApiAppCertificate = $false;
        $apiClientCertificateName = "ApiClientCertificate"
        $apiClientCertificate = Get-AzKeyVaultCertificate -VaultName $settingsKeyvaultName -Name $apiClientCertificateName -ErrorAction Stop

        if ( $null -ne $apiClientCertificate )
        {
            if ( $validThumbprints.Contains( $apiClientCertificate.Thumbprint ) )
            {
                Write-Host "Found certificate 'ApiClientCertificate' in keyvault $settingsKeyvaultName and correctly configured for '$($apiApp.DisplayName)'." -ForegroundColor Green
            }
            elseif ( $expiredThumbprints.Contains( $apiClientCertificate.Thumbprint ) )
            {
                Write-Host "Found certificate 'ApiClientCertificate' in keyvault $settingsKeyvaultName and correctly configured for '$($apiApp.DisplayName)'. However it is expired or will expire within 6 months." -ForegroundColor Green
                $needsNewApiAppCertificate = $true
            }
            else
            {
                Write-Host "Found certificate 'ApiClientCertificate' in keyvault $settingsKeyvaultName but it is not configured for '$($apiApp.DisplayName)'." -ForegroundColor Green
                $needsNewApiAppCertificate = $true
            }
        }

        if ( ( $null -eq $apiClientCertificate ) -or $needsNewApiAppCertificate )
        { 
            Write-Host "Generating new certificate for '$($apiApp.DisplayName)'..." -ForegroundColor Green # Note that parameter  -DisplayName $settingsKeyvaultName  is not supported in combination with -ApplicationObject.

            $policy = New-AzKeyVaultCertificatePolicy -SecretContentType "application/x-pkcs12" -SubjectName "CN=epona365" -IssuerName "Self" -ValidityInMonths 24 -ReuseKeyOnRenewal -EmailAtNumberOfDaysBeforeExpiry 30
            $apiClientCertificateOperation = Add-AzKeyVaultCertificate -VaultName $settingsKeyvaultName -Name $apiClientCertificateName -CertificatePolicy $policy

            for ( $p = 1; $p -le 100; $p = $p+2 )
            {
                Write-Progress -Activity "Creating certificate" -Status "$p%" -PercentComplete $p
                Start-Sleep -Seconds 2

                $apiClientCertificateOperation = Get-AzKeyVaultCertificateOperation -VaultName $settingsKeyvaultName -Name $apiClientCertificateName

                if ( $apiClientCertificateOperation.Status -ne "inProgress" )
                {
                    break;
                }
            }

            if ( $apiClientCertificateOperation.Status -ne "completed" )
            {
                Write-Host $apiClientCertificateOperation.Status

                Write-Host "Failed to create a certificate for '$($apiApp.DisplayName)'." -ForegroundColor Red
                Write-Host "Please generate a certificate manually and store it in keyvault $settingsKeyvaultName with key '$apiClientCertificateName'." -ForegroundColor Red
                return $false
            }

            Write-Progress -Activity "Creating certificate" -Status "100%" -PercentComplete 100

            $apiClientCertificate = Get-AzKeyVaultCertificate -VaultName $settingsKeyvaultName -Name $apiClientCertificateName -ErrorAction Stop
            Write-Host "Created certificate for '$($apiApp.DisplayName)'." -ForegroundColor Green

            # Download the new certificate 'ApiClientCertificate' from the keyvault.
            $apiClientCertificateSecret = Get-AzKeyVaultSecret -VaultName $settingsKeyvaultName -Name $apiClientCertificate.Name
            $apiClientCertificateSecretValue = $apiClientCertificateSecret.SecretValue;
            $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR( $apiClientCertificateSecretValue );
            $apiClientCertificateSecretTextValue = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto( $bstr );
            $apiClientCertificateSecretBytes = [Convert]::FromBase64String( $apiClientCertificateSecretTextValue )
            $apiClientX509Certificate = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList (,$apiClientCertificateSecretBytes)
        }
    }
    catch
    {
        Write-Host "Failed to access the keyvault." -ForegroundColor Red
        Write-Host "Please add your ip address to the firewall settings (Azure Portal -> $settingsKeyvaultName -> Networking -> Firewall -> Add your client IP address)" -ForegroundColor Yellow
        Write-Host "Original error:" -ForegroundColor White
        Write-Host $_ -ForegroundColor White
        return $false
    }

    # Add the certificate 'ApiClientCertificate' to the api app if a new one has been created.
    if ( $null -ne $apiClientX509Certificate )
    {
        Write-Host "Adding the certificate to the credentials of '$($apiApp.DisplayName)'..." -ForegroundColor Green

        try
        {
            $rawCertificateData = [System.Convert]::ToBase64String( $apiClientX509Certificate.GetRawCertData() )
            New-AzADAppCredential -ObjectId $apiApp.Id -CertValue $rawCertificateData -EndDate $apiClientX509Certificate.NotAfter -ErrorAction Stop

            Write-Host "Added the certificate to the credentials of '$($apiApp.DisplayName)'." -ForegroundColor Green
        }
        catch
        {
            Write-Host "Failed to add the certificate to the credentials of '$($apiApp.DisplayName)'." -ForegroundColor Red
            Write-Host "Please manually download the certificate from the keyvault and upload it to '$($apiApp.DisplayName)'" -ForegroundColor Yellow
            Write-Host "Original error:" -ForegroundColor White
            Write-Host $_ -ForegroundColor White
            return $false
        }
    }

    return $true
}

$apiAppName = "Epona365 api"
$spaAppName = "Epona365 app"
$keyvaultPrefix = "$Prefix-ep"
$settingsKeyvaultName = "$keyvaultPrefix-settings"

if ( ![string]::IsNullOrEmpty( $Channel ) )
{
    $apiAppName = "$apiAppName ($Channel)"
    $spaAppName = "$spaAppName ($Channel)"
}

Write-Host "Context: $($(Get-AzContext).Name)"
Write-Host

# Assert the keyvault unless the OnlyEntraId flag is used.
if ( !( $OnlyEntraId ) )
{
    if ( -not ( Assert-KeyVault ) )
    {
        return;
    }
}

# Ensure the api and spa apps in AzureAD.
$applicationUri = [System.Uri]$ApplicationUrl
$apiApp = Assert-ApiApp -Name $apiAppName -Authority $applicationUri.Authority
$spaApp = Assert-SpaApp -Name $spaAppName -Authority $applicationUri.Authority -ApiApp $apiApp

# Ensure the api and spa app id's en client-secret in the keyvault.
if ( ( $null -eq $apiApp ) -or ( $null -eq $spaApp ) )
{
    return
}

# Stop when the OnlyEntraId flag is used.
if ( $OnlyEntraId )
{
    Write-Host ""
    Write-Host "Please provide the following details to the administrator for configuration in keyvault ${settingsKeyvaultName}:" -ForegroundColor Yellow
    Write-Host "- AppClientId: $($spaApp.AppId)" -ForegroundColor Yellow
    Write-Host "- ApiClientId: $($apiApp.AppId)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Additionally, you will need to:" -ForegroundColor Yellow
    Write-Host "1. Obtain the necessary certificate from the administrator." -ForegroundColor Yellow
    Write-Host "2. Configure the certificate in the EntraID app '$apiAppName'." -ForegroundColor Yellow
    Write-Host "3. Grant admin consent to AzureAD apps '$($apiApp.DisplayName)' and '$($spaApp.DisplayName)' in the Azure portal." -ForegroundColor Yellow
    Write-Host "4. Open a browser to $($applicationUri)setup and follow the remaining instructions." -ForegroundColor Yellow
    Write-Host ""
    return
}

# Tell the user what to do when accessing the keyvault fails.
Write-Host "Checking the app secrets in keyvault $settingsKeyvaultName..." -ForegroundColor Green        

# Assert the keyvault secrets unless the OnlyEntraId flag is used.
if ( -not ( Assert-KeyVaultSecrets ) )
{
    return
}

Write-Host
Write-Host "Finished successfully." -ForegroundColor Green
Write-Host
Write-Host "Post deployment tasks (if not done yet):" -ForegroundColor Yellow
Write-Host "    - Grant admin consent to AzureAD apps '$($apiApp.DisplayName)' and '$($spaApp.DisplayName)' in the Azure portal." -ForegroundColor Yellow
Write-Host "    - Open a browser to $($applicationUri)setup and follow the remaining instructions." -ForegroundColor Yellow
Write-Host
