Function BlankSpace {
    param([int]$howmany = 1)
    #Write-Host $howmany
    Write-Host " "
    if ($howmany -ge 2) {
        BlankSpace -howmany ($howmany-1)
    }
}
Function CheckPSVersion {

    param([int]$major,[int]$minor)

    $version_table = $PSVersionTable.PSVersion
    if ($version_table.Major -ge $major -and $version_table.Minor -ge $minor) {
        WRite-Host "PowerShell Version is OK" -ForegroundColor Green
        return $true
    } else {
        WRite-Host "PowerShell is out-of-date" -ForegroundColor DarkRed
        return $false
    }
}

BlankSpace 
WRite-Host "Start Time: $([System.DateTime]::Now)"
WRite-Host "Setup AppRegistration Policy for Teams OnlineMeetings" -ForegroundColor Yellow

# check if we are on PS 5.1 or better.
$res = CheckPSVersion -major 5 -minor 1

if ($res) {
    
    ## Install PSGet :: PowerShell Package Manager
    Write-Host "Install PSGet :: PowerShell Package Manager" -ForegroundColor Magenta
    Install-Module -Name PowerShellGet -Force -AllowClobber -ErrorAction Continue
    
    ## Install Microsoft Teams / Skype Module
    Write-Host "Install Microsoft Teams / Skype Module" -ForegroundColor Magenta
    Import-Module MicrosoftTeams -Force -AllowClobber -ErrorAction Continue 
    Write-Host "Modules imported.... " -ForegroundColor Green

    # Connect to Teams
    $tenantid = "e16e56f2-9747-40a6-8189-09ba0f1fa61c"
    Connect-MicrosoftTeams 

    Get-CsApplicationAccessPolicy
}

# hasta la vista ~~
WRite-Host "Good Bye!" -ForegroundColor Cyan
BlankSpace