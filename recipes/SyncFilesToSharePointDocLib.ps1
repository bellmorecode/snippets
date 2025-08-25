# PowerShell script to sync files in a Directory to SharePoint (2007) 
# using the SharePoint SOAP Web Services.

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted

# Constants
$copyWsUrl = "http://hb2ksrvr17/_vti_bin/copy.asmx?WSDL"
$listsWsUrl = "http://hb2ksrvr17/_vti_bin/lists.asmx?WSDL"             

# Web Service Proxy Definition
$copyService = New-WebServiceProxy -Uri $copyWsUrl -UseDefaultCredential -Namespace "HB"

# Global Variables
$spsiteurl = "http://hb2ksrvr17/"
$libname = "Test_SensitiveDocs"
$syncroot = "\\Hb2ksrvr22\AutoStoreProcessedFilesOutput"
$syncroot_finished = "C:\_autostore_temp"
$cs = ""

if (![System.IO.Directory]::Exists($syncroot_finished)) {
    [System.IO.Directory]::CreateDirectory($syncroot_finished)
}

$fuse = 5
$counter = 1

Add-Type -AssemblyName "System, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089"
Add-Type -AssemblyName "System.Data, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089"
Add-Type -AssemblyName "System.Xml, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089"
Add-Type -AssemblyName "System.Core, Version=3.5.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089"
# Is .NET Loaded? Tester
#[String]::Format("{0:d}", [DateTime]::Now)
#RESET
Function Clear-Directory {
    param ( $path )

    foreach($file in [System.IO.Directory]::GetFiles($path)) {
        Remove-Item -LiteralPath $file
    }
}
Function Get-ConnectionString {
    param([switch]$Autostore,[switch]$CMSOpen)
    
    $cs = "unknown database switch"
    
    if ($AutoStore) {
        $cs = "Data Source=hb2ksrvr3;Initial Catalog=HBFlowPort;User Id=autostoreadmin;Password=autostore;Connection Timeout=120";
    }
    if ($CMSOpen) {
        $cs = "Data Source=vohbsrvr06;Initial Catalog=cmsopen;User Id=autostoreadmin;Password=autostore;Connection Timeout=120"
    }    
    return $cs    
}
Function Add-MatterDetails {
    param([Object[]]$recdata)
    
    $cs = Get-ConnectionString -CMSOpen
    $cn = new-object System.Data.SqlClient.SqlConnection $cs
    $cn.Open()
    #Write-Host "Connected"
    $sql = [string]::Format("select matter_code, matter_name from HBM_Matter where matter_code ='{0}'", $recdata[1])
    $cmd = $cn.CreateCommand()
    $cmd.CommandText = $sql
    $da = new-object System.Data.SqlClient.SqlDataAdapter $cmd
    $dt = new-object System.Data.DataTable "cmsopendata"
    $rowsReturned = $da.Fill($dt)
    $da.Dispose()
    $cmd.Dispose();
    $cn.Close()
    $cn.Dispose()
    $cn = $null
    $results = "Unitialized","No Status"
    if ($rowsReturned -gt 0) {
        $row = [System.Data.DataRow]$dt.Rows[0]
        $cells = $row.ItemArray;
        $mattername = $cells[1]
        $recdata += $mattername
        
    } else {
        "CMSOpen Record not found"
        $recdata += "Error"
        $recdata += "Matter-not found"
    }
    $dt.Dispose()
    return $recdata
}

Function Get-AutoStore-Record {
    param ([string]$LiteralPath)
    
    $cs = Get-ConnectionString -Autostore
    $cn = new-object System.Data.SqlClient.SqlConnection $cs
    $cn.Open()
    #Write-Host "Connected"

    # get some records from autostore table
    $sql = "select top 10 Searchkey, MatterCode, BillingCode, DocumentDate, AttorneyCode, ScanDate, [ServerID], NumberOfPages, PDFFileName, Status, DateProcessed, RecId, IsAutoCapture, Narrative, EmailAddress, OfficeId, DCN1, DCN2 FROM [dbo].[_AUTOSTORE_RECORD] where PDFFileName = '$LiteralPath'"
    #$sql
    $cmd = $cn.CreateCommand()
    $cmd.CommandText = $sql
    $da = new-object System.Data.SqlClient.SqlDataAdapter $cmd
    $dt = new-object System.Data.DataTable "autostorerecord"
    $rowsReturned = $da.Fill($dt)

    $da.Dispose()
    $cmd.Dispose();

    $cn.Close()
    $cn.Dispose()
    $cn = $null
   
    $results = "Unitialized","No Status"
    
    if ($rowsReturned -gt 0) {
        $row = [System.Data.DataRow]$dt.Rows[0]
        $cells = $row.ItemArray;
        $mattercode = $cells[1]
        $billingcode = $cells[2]
        $attorneycode = $cells[4]
        $emailAddress = $cells[14]
        $dcn1 = [string]::format("{0}", $cells[16]).Trim() # lot of leading spaces

        $results = "Success", $mattercode, $billingcode, $attorneycode, $dcn1
        return $results
        
    } else {
        "Autostore Record not found"
        $results = "Error","Record-not found"
        return $results
    }
    
    $dt.Dispose()
    
    return $results
}

#Copy-ItemToSharePoint
Function Copy-ItemToSharePoint {
    param ([string]$LiteralPath, [string]$OrigPath) 
    
    $result = $true

    $filename = [System.IO.Path]::GetFileNameWithoutExtension($LiteralPath)
    $filepath = [System.IO.Path]::GetFileName($LiteralPath)
    #$raw = [System.IO.File]::ReadAllBytes($LiteralPath)

    
    $recdata = Get-AutoStore-Record -LiteralPath $OrigPath 
    
    if ($recdata[2] -ne "RD06") {
        #Write-Host "Skipping, not RD06... " $recdata[2]
        $result = $false
    }
    
    $recdata = Add-MatterDetails -recdata $recdata
    
    if ($result) {
        Write-Host "Copy $filepath to SharePoint"
        
        Write-Host $recdata
        
        Copy-Item -LiteralPath $OrigPath -Destination $LiteralPath
        
        Add-SPDocLibItem -LiteralPath $LiteralPath -Metadata $recdata
    
        Write-Host "++++++++++++++++"
        Write-Host ""
    }
    
    return $result
}

Function Add-SPDocLibItem {
    param([string]$LiteralPath, [string[]]$Metadata)

    $condensed_mattername = Clean-MatterName -MatterName $Metadata[5] -Omit " "    
    $filename = [string]::Format("{0}_{1}_{2}", $Metadata[3], $condensed_mattername, $Metadata[4])
    
    $targetDocExt = [System.IO.Path]::GetExtension($filePath);
    $destinationUrl = $spsiteurl + $libname + "/" + $filename + $targetDocExt;
    $destinationUrls = [string[]]@( $destinationUrl );
    

    [HB.FieldInformation]$titleField = new-object HB.FieldInformation
    $titleField.DisplayName = "Title"
    $titleField.InternalName = "Title"
    $titleField.Type = "Text"
    $titleField.Value = $filename
    # Item Title Pattern: [AttorneyCode]_[MatterName-NoSpaces]_[DCN1]
    
    [HB.FieldInformation]$matterField = new-object HB.FieldInformation
    $matterField.DisplayName = "Matter"
    $matterField.InternalName = "Matter"
    $matterField.Type = "Text"
    $matterField.Value = $Metadata[5]
    
    [HB.FieldInformation]$billingCodeField = new-object HB.FieldInformation
    $billingCodeField.DisplayName = "BillingCode"
    $billingCodeField.InternalName = "BillingCode"
    $billingCodeField.Type = "Text"
    $billingCodeField.Value = $Metadata[2]   
        
    [HB.FieldInformation[]]$info = new-object HB.FieldInformation[] 3
    $info[0] = $titleField
    $info[1] = $matterField
    $info[2] = $billingCodeField
    
    $result2 = new-object HB.CopyResult[] 0
    [byte[]]$data = [System.IO.File]::ReadAllBytes($LiteralPath)
    [UInt32]$ret = $copyService.CopyIntoItems($destinationUrl, $destinationUrls, $info, $data, [ref]$result2)
    
    #$result2[0].DestinationUrl
    
    
}

Function Clean-MatterName {
    param([string]$MatterName, [string]$Omit)
    
    #if ($MatterName -eq $null) return [string]::Empty;
    
    while ($MatterName.IndexOf($Omit) -ge 0) {
        $MatterName = $MatterName.Replace($Omit,"")
    }
    return $MatterName
}

Function Push-ToSP-Demo {
            
    # Create the service            
    $copyService = New-WebServiceProxy -Uri $copyWsUrl -UseDefaultCredential -Namespace "HB"
             
  
    #$listService = New-WebServiceProxy -Uri $listsWsUrl -Namespace ListsWs -UseDefaultCredential 
    
    $filePath = "C:\_autostore_temp\20170428120715_1_29a.pdf"
    
    $targetDocName = [System.IO.Path]::GetFileName($filePath);
    $destinationUrl = $spsiteurl + $libname + "/" + $targetDocName;
    $destinationUrls = [string[]]@( $destinationUrl );

    [HB.FieldInformation]$i1 = new-object HB.FieldInformation
    $i1.DisplayName = "Title"
    $i1.InternalName = "Title"
    $i1.Type = "Text"
    $i1.Value = "Temp"
    
    $i1
    
    [HB.FieldInformation[]]$info = new-object HB.FieldInformation[] 1
    $info[0] = $i1
    $result2 = new-object HB.CopyResult[] 0
    [byte[]]$data = [System.IO.File]::ReadAllBytes($filePath)
    [UInt32]$ret = $copyService.CopyIntoItems($destinationUrl, $destinationUrls, $info, $data, [ref]$result2)
    
    $result2[0].DestinationUrl
    
    $result2
}

# Main Program :: Start Here.
# return

$d1Exists = [System.IO.Directory]::Exists($syncroot)
$d2Exists = [System.IO.Directory]::Exists($syncroot_finished)

$allcount = 0
$rd06Count = 0

if ($d1Exists -and $d2Exists) {
    Write-Host "SPSync Autostore Plugin"
    Write-Host "Target Directory: " $syncroot
    Write-Host "'Processed Items' Directory" $syncroot_finished
    
    Write-Host "RD06 Sensitive Docs - Import Job"
    
    $unsorted_fileslist = [System.IO.Directory]::GetFiles($syncroot);
    $sorted = $unsorted_fileslist | sort

    for ($ptr = $sorted.length - 1; $ptr -ge 0; $ptr--)
    {
        $file = $sorted[$ptr];   
        $status = "new"

        $finished_name = $file.Replace($syncroot, $syncroot_finished)
        $allcount++
        if ([System.IO.File]::Exists($finished_name)) {
            $status = "synced"
            $allcount--
        }
        if ($status -eq "new") {   
            $result = Copy-ItemToSharePoint -LiteralPath $finished_name -OrigPath $file
            if ($result) {
                $rd06Count++
                Write-Host $allcount " processed, " $rd06count " RD06 Sensitive Docs found."
                if ($counter -ge $fuse) {
                    Write-Host "Processed $fuse item(s)... quitting. FUSE"
                    return
                }
                $counter++
            }
        }        
    }
}
