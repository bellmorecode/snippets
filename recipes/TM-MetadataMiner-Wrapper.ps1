# Execution Policy
# Get-ExecutionPolicy # IF RESTRICTED, ELEVATE
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted

# Install-Module -Name PnP.PowerShell
# Project Site Analyzer Recipes
# ===================================
$clientid = "b916db6f-17df-423e-af66-3043dcd54137"
$secret = "Q9QVMhUh52YcvFOyXvFuRFvKUl0XBbHhmT00f4JehiU="
# $spadminurl = "https://moderntech-admin.sharepoint.com"
$spurl = "https://moderntech.sharepoint.com/sites/tmconnect"

Add-Type -Path .\datatools\metadata-miner\bin\Debug\net5.0\metadata-miner.dll
$writer = new-object metadataminer.TMConnectStatsWriter
WRite-Host "Loaded dotnet tools" -ForegroundColor Green

Function Save-TermsWarehouseStats {
    param([string]$filename,[string]$url,[int]$oType,[string[]]$keywords)

    try {
        $writer.Write($filename, $url, $oType, $keywords)
        Write-Host "." -NoNewline -ForegroundColor Blue
    } catch  {
        Write-Host "!" -NoNewline -ForegroundColor Red
        WRite-Host $_ -ForegroundColor Red;
    }

    #Write-Host "do it" -ForegroundColor Blue
}

Connect-PnPOnline -url $spurl -ClientId $clientid -ClientSecret $secret -WarningAction Ignore
Get-PnpSite 
$list = Get-PnPList "TM Connect Docs" -ThrowExceptionIfListNotFound
WRite-Host "Total Item(s): $($list.ItemCount)" -ForegroundColor Black
$results = Get-PnpListItem -List "TM Connect Docs" -Fields "ID","LinkFilename","FileDirRef", "FileLeafRef", "FileRef"
for($r = 0; $r -lt $results.Length; $r++) { 
    $item = $results[$r]
    $full_path = [string]$item.FieldValues["FileRef"]
    
    # if ($full_path.LastIndexOfAny("/Data Sheets and Guides/") -gt -1) {
        
        #Write-Host $full_path, $objType, $name
       try {
        $url_parts = $full_path.split('/');
        $objType = [int]$item.FieldValues["FSObjType"];
        $name = [string]$item.FieldValues["FileLeafRef"];

        Save-TermsWarehouseStats -filename $name -url $full_path -oType $objType -keywords $url_parts 
        
       } Catch {
           WRite-Host $_ -ForegroundColor DarkRed
       }
        
    # }  
}

# The app identifier has been successfully created.
# Client Id:  	b916db6f-17df-423e-af66-3043dcd54137
# Client Secret:  	Q9QVMhUh52YcvFOyXvFuRFvKUl0XBbHhmT00f4JehiU=
# Title:  	TMConnect Inspector
# App Domain:  	tmconnectapp.gfdatacorp.com
# Redirect URI:  	https://tmconnectapp.gfdatacorp.com