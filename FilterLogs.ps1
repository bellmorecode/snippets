Function Filter-LogFile { 
    param ( [string] $logLine )

    $transCmt = "SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED";
    $moduleInfoLookup = "SELECT ClientNumber, Password, ModuleID FROM FW_CFGSysConfig, CFGModuleConfiguration WHERE ModuleID"
    $metadataQuery1 = "SELECT dataType, ISNULL(tableName,/*N*/'') as tableName, FW_CustomColumns.Name as ColName, FW_CustomColumns.Infocenterarea , FW_CustomColumns.LimitToList FROM FW_CustomColumns"
    # If line contains these patterns skip
    if ($logLine -eq "Go" -or $logLine -eq "GO") { return $true; }
    
    if ($logLine.Contains("IF EXISTS (SELECT name FROM sysobjects WHERE name = 'setContextInfo'")) { return $true; }
    if ($logLine.Contains($metadataQuery1)) { return $true; }
    if ($logLine.Contains($transCmt)) { return $true; }
    if ($logLine.Contains($moduleInfoLookup)) { return $true; }
    if ($logLine.StartsWith("/* RSID:"))  { return $true; }
    if ($logLine.StartsWith("SELECT Code AS Code, Label AS Label, 'Y' AS Filtered FROM CFGLCCodes"))  { return $true; }
    if ($logLine.StartsWith("SELECT VisibleFlg FROM RPGrd"))  { return $true; }
    if ($logLine.StartsWith("SELECT OrgLevels, Org1Start, Org1Length, Org2Start, Org2Length, Org3Start, Org3Length, Org4Start, Org4Length, Org5Start, Org5Length, VariableOrgLevels FROM CFGFormat"))  { return $true; }
    if ($logLine.StartsWith("SELECT Code, Description FROM CFGProjectStatus ORDER BY Description"))  { return $true; }
    return $false;
}

$sourcePath = "C:\Users\glenn\Desktop\WB DOMO\Utilization-output.sql"
$outputpath = "C:\Users\glenn\Desktop\WB DOMO\Utilization-output-modified.sql"

$all_lines = [System.IO.File]::ReadAllLines($sourcePath)

$newlist = "", "", ""
$newlist.Clear()
foreach($line in $all_lines) 
{
    $shouldFilter = Filter-LogFile -logLine $line
    if (!$shouldFilter) {
        Write-Host $line
        $newlist += $line
    }
}
if ($newlist.Count -gt 0) {
    WRite-Host "Output File" -ForegroundColor Green
    [System.IO.File]::WriteAllLines($outputpath, $newlist)
    Start-Process -FilePath $outputpath
}