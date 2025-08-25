#========================================================================
# Created on:   11/19/2013 12:36 AM
# Created by:   Shane Cribbs
# Organization:    
#========================================================================


# [array]$usbdrives = Get-WmiObject win32_diskdrive -filter 'InterfaceType = "USB"'
[array]$usbdrives = Get-WmiObject win32_diskdrive -filter 'InterfaceType = "IDE"'

If ($usbdrives.count -gt 0){
	$usbPartitions = $usbdrives | `
	  ForEach-Object {gwmi -Query "ASSOCIATORS OF {Win32_DiskDrive.DeviceID=`"$($_.DeviceID.replace('\','\\'))`"} WHERE AssocClass = Win32_DiskDriveToDiskPartition"} 

	[array]$usbLetters = $usbPartitions `
	  |  %{gwmi -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID=`"$($_.DeviceID)`"} WHERE AssocClass = Win32_LogicalDiskToPartition"} `
	  | ForEach-Object {$_.DeviceID}

	Write-Host $usbLetters[0]
	
	# Load the Windows.Forms assembly for the notification windows
	[void][reflection.assembly]::Load("System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
	
	$ConfirmationText = "Would you like to capture the local Windows installation to an image?"

	if([System.Windows.Forms.MessageBox]::Show($ConfirmationText, "Image Capture",[System.Windows.Forms.MessageBoxButtons]::YesNo) -ne "Yes")
	{
		Exit
	}
	
}
ELSE{
	Write-Host "No USB drives found"
}
