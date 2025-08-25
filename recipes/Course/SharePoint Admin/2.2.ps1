
# Global variables
$Global:RegKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
$Global:powershell = (Join-Path $env:windir "system32\WindowsPowerShell\v1.0\powershell.exe")
$Global:restartKey = "SPInstaller-Restart"
$Global:ScriptLocal = $MyInvocation.MyCommand.Path
$Global:silentConfig = Join-Path (Split-Path -parent $global:ScriptLocal) "SilentConfig.xml"
$Global:installPath = "C:\SharePoint 2013 Software"

$Global:HasRestarted = $false

#region Functions

# Installs sharepoint prerequisies
function InstallPrerequisites{
    Write-Host "Installing Prerequisites..." -ForegroundColor Yellow

    $path = Join-Path $installPath prerequisiteinstaller.exe
    $process = $null


    $arguments = "/unattended"

    if($Global:HasRestarted)
    {
        $arguments = $arguments + " /continue"
    }

    $process = (Start-Process -Wait -PassThru $path $arguments)
 
    if(-not($Global:HasRestarted))
    {
        Write-Host "Restarting computer in 5 seconds..."
        Start-Sleep -seconds 5
        Restart
    }

    CheckPrerequisites($process.ExitCode)
}

# Displays messages and restarts if needed
function CheckPrerequisites($exitCode){
    switch ($exitCode)
    {
        0 {
            Write-Host "Prerequisites installed successfully" -ForegroundColor Green 
        }
        1001 {
            Write-Host "Restart is needed" -ForegroundColor Yellow
            Restart
        }
        3010 {
            Write-Host "Restart is needed" -ForegroundColor Yellow
            Restart
        }
        default {
            Write-Host "Installation has failed" -ForegroundColor Red
        }
    }
    return $exitCode
}

# Installs SharePoint Binaries
function InstallSharepoint{
    Write-Verbose "Entering InstallSharepint function"
    Write-Host "Installing SharePoint..." -ForegroundColor Green

    $InstallArgs = "/config " + $Global:silentConfig
    Write-Verbose "InstallArgs: $InstallArgs"
    $InstallCmd = Join-Path $global:installPath "Setup.exe"
    Write-Verbose "InstallCmd: $InstallCmd"
    $sharepoint = (Start-Process -Wait -PassThru "$InstallCmd" -ArgumentList "$InstallArgs")

    switch($sharepoint.ExitCode)
    {
        0 {
            Write-Host "SharePoint successfully installed" -ForegroundColor Green
        }
        default{
            Write-Host "An error has occured. Code: " $sharepoint.ExitCode -ForegroundColor Red
        }
    }

    return $sharepoint.ExitCode
}

# Restarts the machine with the script as a startup task
function Restart{

    $valueArgs = "$global:powershell (" + $Global:ScriptLocal + ")"

    Set-ItemProperty -path $Global:RegKey -name $global:restartKey -value $valueArgs
    Restart-Computer
}

# Checks if a restart has occured and removes script from startup
function CheckRestart{
    if((Test-Path $Global:RegKey) -and (((Get-ItemProperty $Global:RegKey).$Global:restartKey) -ne $null))
    {
        $Global:HasRestarted = $true
        Remove-ItemProperty -path $Global:RegKey -name $Global:restartKey
    }
}

# Creates prompt for user to press key
function Wait-KeyPress {
    #Write-Host "Press any key to continue..."
    #$notused = $host.UI.RawUI.ReadKey("NoEcho","IncludeKeyDown") #Doesn't work in ISE
    Read-Host -Prompt "Press <ENTER> to continue..."
}

# Checks if resources needed for script are avaliable
function RunChecks{
    $valid = 1
    
    # Path to SP install files
    if(!(Test-Path $installPath))
    {
        InvalidPath($installPath)
        $valid = 0
    } 

    # PrerequisiteInstaller.exe
    $preReqFile = Join-Path $installPath prerequisiteinstaller.exe
    if(!(Test-Path $preReqFile))
    {
        InvalidPath($preReqFile)
        $valid = 0
    } 

    #Setup.exe
    $setupFile = Join-Path $installPath setup.exe
    if(!(Test-Path $setupFile))
    {
        InvalidPath($setupFile)
        $valid = 0
    } 

    #Silent config file for this script config
    $Global:silentConfig = Join-Path (Split-Path -parent $Global:ScriptLocal) SilentConfig.xml
    if(!(Test-Path $Global:silentConfig))
    {
        InvalidPath($Global:silentConfig)
        $valid = 0
    } 

    return $valid
}

# Prints error message on path not found
function InvalidPath($path)
{
    Write-Host "Path '" + $path + "' was not found" -ForegroundColor Red
}

function Create-SPFarm {
    # SQL Server variable 
    $SQLServer = "LTree"
    $SQLUsername = "LOCALDOMAIN\SPFarmService"
    $SQLPassword = "pw"
    $FarmPassphrase = "P@ssphr@se"
    $ConfigDB = "SharePoint_Config"
    $Global:Port = "50000"

    $FarmCredentials = New-Object System.Management.Automation.PSCredential $SQLUsername, (ConvertTo-SecureString $SQLPassword -AsPlainText -Force)

    Add-PSSnapin -Name "Microsoft.SharePoint.PowerShell"


    Write-Host "Creating SharePoint_Config database..." -ForegroundColor Green
    New-SPConfigurationDatabase -DatabaseServer $SQLServer -DatabaseName $ConfigDB -Passphrase (ConvertTo-SecureString $FarmPassphrase -AsPlainText -Force) -FarmCredentials $FarmCredentials
    
    if (-not $?) { 
        throw "Configuration database could not be setup"    
    }

    Write-Host "SharePoint_Config database created." -ForegroundColor Green

}

function Configure-SPFarm {

    Write-Host "Configuring SharePoint Farm..." -ForegroundColor Green
    Install-SPHelpCollection -All
    Write-Host " - Configuring resource security..." -ForegroundColor Green
    Initialize-SPResourceSecurity
    Write-Host " - Installing services, features and application content..." -ForegroundColor Green
    Install-SPService  
    Install-SPFeature -AllExistingFeatures
    Install-SPApplicationContent

    Write-Host " - Creating CentralAdmin..." -ForegroundColor Green
    New-SPCentralAdministration -Port $Global:Port -WindowsAuthProvider NTLM

    Write-Host " - Creating State Service Application..." -ForegroundColor Green
    $stateServiceName = "State Service Application"
    $stateService = New-SPStateServiceApplication -Name $stateServiceName

    New-SPStateServiceApplicationProxy -Name "$stateServiceName Proxy" -ServiceApplication $stateService –DefaultProxyGroup

    # Configure Usage and Health data collection
    #TODO

}

#endRegion

#region Script Logic

# Check if restart has occured
CheckRestart

# Check resources are avaliable
if((RunChecks) -eq 1)
{
    # Check/Install prerequisites
    if((InstallPrerequisites) -eq 0)
    {
        # Install SharePoint
        if((InstallSharepoint) -ne 0)
        {
            # Exit the script if SharePoint installation failed
            Wait-KeyPress
            Exit

        }

        # Install SharePoint Farm
        Create-SPFarm

        # Configure SharePoint Farm
        Configure-SPFarm

    }
} 

Write-Host "Exercise solution complete." -ForegroundColor Green
Wait-KeyPress

#endregion