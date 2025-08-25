#========================================================================
# Created by:   Shane Cribbs
# Organization: Learning Tree International
#========================================================================
# Load assemblies
[void][reflection.assembly]::Load("System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")

# Check host name
If ($env:COMPUTERNAME -ne "LTREE"){
	[void][System.Windows.Forms.MessageBox]::Show("This script is designed for server ""LTREE"" only.`n SCRIPT ABORTING","Script Aborted")
	Exit
}

Write-Host "Host name validated" -ForegroundColor 'Green'

# Add the SP snappin
Write-Host "Loading the SharePoint snappin..." -ForegroundColor Green
Add-PSSnapin -Name "Microsoft.SharePoint.PowerShell"

#region Exercise Logic starts here
	# Delete the DeleteMe content database
    Write-Host "Removing content database DeleteMe..." -ForegroundColor 'Green'
    Remove-SPContentDatabase -Identity "DeleteMe" -Force -Confirm:$False -ErrorAction Continue

	# Provision a BLOB store (run SQL script)
    Write-Host "Provisioning a BLOB store in the content database..." -ForegroundColor 'Green'
    Invoke-Sqlcmd -InputFile "c:\course1532\rbs Files\Provision a BLOB Store on SQL Server.sql"

	# Install RBS
    Start-Process msiexec.exe -ArgumentList '/qb /i "C:\course1532\RBS Files\rbs_amd64.msi" TRUSTSERVERCERTIFICATE=true FILEGROUP=PRIMARY DBNAME="WSS_Content_80" DBINSTANCE="LTREE" FILESTREAMGROUP=FBSFilestreamProvider FILESTREAMSTORENAME=Filestream_Blob_Store' -Wait

	# Enable RBS
    $cdb = Get-SPContentDatabase -WebApplication http://ltree.localdomain.com
    $rbss = $cdb.RemoteBlobStorageSettings
    $rbss.Installed()
    $rbss.Enable()
    $rbss.SetActiveProviderName($rbss.GetProviderNames()[0])

    If (-not($rbss.Enabled)){Write-Host "ERROR: RBS was NOT enabled for some reason!" -ForegroundColor 'Red'}

	# Test RBS through document upload
    $filepath1 = "C:\Course1532\RBS files\Cloud Comp WP.pdf"
    $filename1 = "Cloud Comp WP.pdf"
    $filepath2 = "C:\Course1532\HR Company Policy.docx"
    $filename2 = "HR Company Policy.docx"
    $DocCenterURL = "http://ltree.localdomain.com/Documents/Documents/"
    $credentials = [System.Net.CredentialCache]::DefaultCredentials
    $webclient = New-Object -TypeName System.Net.WebClient
    $webclient.Credentials = $credentials

    $webclient.UploadFile($DocCenterURL + $filename1,"PUT",$filepath1)
    $webclient.UploadFile($DocCenterURL + $filename2,"PUT",$filepath2)


#endregion

[void][System.Windows.Forms.MessageBox]::Show("Solution script is complete.","Solution Script")
