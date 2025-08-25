$version = "1.0.0.0"
$welcomemsg = "GFDATACorp Cloud Backup Toolkit - v. $version"
$accname = "gfd";
$key = "YOUR KEY HERE!!!!!";

Function PutCloudFile ($loc, $subdir, $root) {
    Write-Host "Copy $loc to $subdir "
    $ctx = New-AzureStorageContext -StorageAccountName $accname -StorageAccountKey $key
    $container = Get-AzureStorageContainer -Name "remotebackup" -Context $ctx
    $container.CloudBlobContainer.Uri.AbsoluteUri
    if ($container) {
        $targetPath = ($loc.Substring($root.Length + 1)).Replace("\", "/")
        Write-Verbose "Uploading $("\" + $loc.Substring($root.Length + 1)) to $($container.CloudBlobContainer.Uri.AbsoluteUri + "/" + $targetPath)"
        Set-AzureStorageBlobContent -File $loc -Container $container.Name -Blob $targetPath -Context $ctx -Force:$Force | Out-Null

    }
}

Write-Host $welcomemsg
Write-Host "What directory do you want to copy?" 
$input = Read-Host "Local Directory Path"

$files = [System.IO.Directory]::GetFiles($input, "*", [System.IO.SearchOption]::AllDirectories)
$fileCount = $files.Count
foreach($file in $files) {
    PutCloudFile -loc $file -subdir "backup" -root $input
}
Write-Host "$fileCount files copied"
