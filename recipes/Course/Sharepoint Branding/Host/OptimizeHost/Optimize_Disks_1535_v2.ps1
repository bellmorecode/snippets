#========================================================================
# Created on:   11/5/2013
# Created by:   Shane Cribbs
# Filename: Optimize_Disks_170.ps1   
#========================================================================

#region Customizations

# arrDisksToConvert is a comman separated list of disks to convert 
# Do NOT include the .vmdk extention on the disk name, i.e.
$arrDisksToConvert = @("C:\Ltree\VMs\1535 SharePoint\Windows_Server_2008_x64")


##### NO CUSTOMIZATIONS BELOW THIS POINT #####

#endregion

#region Functions and Assemblies

function Flatten-VirtualDisk ($DiskPathName)
{
	If (Test-Path -Path "$DiskPathName-flat.vmdk")
    {
	    Write-Host "$DiskPathName-flat.vmdk already exists.  Skipping disk conversion for this disk."
    }
    Else
    {
	    Write-Host "`nConverting $DiskPathName.vmdk"
	    & "$PSSCriptRoot\vmware-vdiskmanager.exe" -n "$DiskPathName.vmdk" "$DiskPathName-growable.vmdk" 2> $null
	    & "$PSSCriptRoot\vmware-vdiskmanager.exe" -r "$DiskPathName-growable.vmdk" -t 2 "$DiskPathName.vmdk" 2> $null

    }
}

# Load the Windows.Forms assembly for the notification windows
[void][reflection.assembly]::Load("System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")

#endregion

#region Script Logic

# Warn the user of the time delay
$ConfirmationText = "You are about to convert growable VM disks to flat disks.`n`nThis could take over an hour and a considerable amount of disk space. Would you like to continue?"

if([System.Windows.Forms.MessageBox]::Show($ConfirmationText, "VMware Disk Conversion",[System.Windows.Forms.MessageBoxButtons]::YesNo) -ne "Yes")
{
	Exit
} 

# Check to make sure you can find the conversion utility
If (-not(Test-Path -Path "$PSScriptRoot\vmware-vdiskmanager.exe")){
	$MissingVDMText = "`n$PSScriptRoot\vmware-vdiskmanager.exe could not be found.`n`nPlease place the utility in the same folder with this script and try again."
	[void][System.Windows.Forms.MessageBox]::Show($MissingVDMText,"ERROR")
	
	Exit
}

Write-Host "`n`n`n`n`n`n`nWARNING:  DO NOT CLOSE THIS WINDOW`nWhen the script is complete, you will receive a notification prompt...`n`n"

# Initialize $counter to keep track of element number for progress bar
$counter = 0

# Convert the disks
ForEach ($disk in $arrDisksToConvert){
    $percentcomplete = [decimal]::Round($counter / ($arrDisksToConvert.Count) * 100)
    Write-Progress -Activity "Disk conversion" -Status "$percentcomplete percent complete" -PercentComplete $percentcomplete
    
    Flatten-VirtualDisk -DiskPathName $disk
    $counter++

    $percentcomplete = [decimal]::Round($counter / ($arrDisksToConvert.Count) * 100)
    Write-Progress -Activity "Disk conversion" -Status "$percentcomplete percent complete" -PercentComplete $percentcomplete
}


#Remove Optimize Disks shortcut from desktop
Remove-Item -Path "C:\Users\Public\Desktop\Optimize*Disk*.lnk"


[void][System.Windows.Forms.MessageBox]::Show("Script is complete.  Virtual disks have been converted.`n`nIf necessary, this script can be run again from $PSScriptRoot","Virtual Disk Conversion")

#endregion