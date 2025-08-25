# SharePoint Migration Toolkit
$CSOM_assembly_root = "I:\gfdata_v2\SharedArtifactsLibrary\CSOM"
$creds_path = "c:\apps\gfdatacorp\spmove\"

# shared functions
function Get-SPLib {
    Add-Type -Path ("$CSOM_assembly_root\Microsoft.SharePoint.Client.dll")
    Add-Type -Path ("$CSOM_assembly_root\Microsoft.SharePoint.Client.Runtime.dll")
}

function Connect-SPOContext {
    param([string]$configName)
    
    $cfgpath = "$creds_path$configName.info"  
    # Write-Host $cfgpath  
    if ([System.IO.File]::Exists($cfgpath) -eq $false) {
        Write-Host "Error: Unknown configuration: $configName" -ForegroundColor Red
        return $null
    }
    $settingsText = [System.IO.File]::ReadAllText($cfgpath)
    #Write-host $settingsText
    $settings = $settingsText.split('|')
    $targetsite = $settings[0]
    $userlogin = $settings[1]
    $secret_pwd = ConvertTo-SecureString -String $settings[2] -AsPlainText -Force 

    $ctx = New-Object Microsoft.SharePoint.Client.ClientContext($targetsite)
    $creds = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($userlogin,$secret_pwd)
    $ctx.Credentials = $creds
    Write-Host "Connecting to " -NoNewline
    Write-Host $targetsite -ForegroundColor Cyan

    #Retrieve list
    $web = $ctx.Web
    $ctx.Load($web)
    $ctx.Load($ctx.Site)
    $ctx.ExecuteQuery()

    return $ctx
}

function Connect-SPOSite {
    param([string]$url)
}

function Copy-SPOSite {

}

function Copy-SPOWeb {

}

function Copy-SPODocLib {
    param($from, $from_name, $to, $to_name)

}

function Copy-SPOList {

}

function Set-FileToSPOWeb {

}

function Copy-SPOUser {

}

function Set-SPOUserPhoto {

}

function Get-SPOSiteInfo {
    param([Microsoft.SharePoint.Client.ClientContext]$ctx)

    Write-Host ""
    Write-Host "Site Properties - ID: " -NoNewline
    Write-Host $ctx.Site.Id
    Write-Host "compat level: " $ctx.Site.CompatibilityLevel
    Write-Host "relative url: " $ctx.Site.ServerRelativeUrl
    Write-Host "url: " $ctx.Site.Url
    WRite-Host "server version: " $ctx.ServerVersion
    Write-Host "library: " $ctx.ServerLibraryVersion
    Write-Host "site template " $ctx.Web.WebTemplate

    [Microsoft.SharePoint.Client.ListCollection]$lists = $ctx.Web.Lists
    $ctx.Load($lists)
    $ctx.ExecuteQuery()
    foreach($list in $lists) {
        Write-Host $list.ID $list.Title, $list.ItemCount "($($list.BaseType))"
    }
    WRite-Host $lists.Count "list(s) found" 
}

# This is where the main procedure start.
Write-Host "Loading Libraries..." -ForegroundColor Yellow
Get-SPLib

# connection names refer to config files in the root, it's pipe-delimited -> url|un|pwd
$fromConnection = "wbnet"
$toConnection = "wbnet-test"

Write-Host "Connect to $fromConnection and $toConnection" -ForegroundColor Yellow

$from_ctx = Connect-SPOContext -configName $fromConnection
$to_ctx = Connect-SPOContext -configName $toConnection

if ($null -eq $from_ctx -or $null -eq $to_ctx) {
    Write-Host "one or more connections did not load correctly." -
    return
}

Write-Host "Get Site Collection info" -ForegroundColor Yellow

# $from_ctx.GetType().AssemblyQualifiedName
Get-SPOSiteInfo $from_ctx
Get-SPOSiteInfo $to_ctx