#*****************************************************
# Get list of computers from a text file
$computers = Get-Content -Path "C:\Scripts\computers.txt"

#Get list of computers from AD, modify SEARCHBASE parameter if necessary
#$RootDSE = ([ADSI]"LDAP://RootDSE").defaultNamingContext
#[array]$ADComputers = Get-ADComputer -Filter * -SearchBase "CN=Computers,$RootDSE" -Properties Name
#[array]$Computers = @()
#$ADComputers | ForEach-Object {$Computers += ($_.name)}

$OutputFile = "C:\Scripts\DiskInfo.csv"
$ErrorFile = "C:\Scripts\LowDiskErrors.txt"
# Percentage of free space before logging an error
$MinFreeSpacePercentage = "10"
#*****************************************************

# Add a header to the output file
Set-Content -Path $outputfile -Value "ComputerName,DeviceID,Size,FreeSpace"

# Loop through each computer
$computers | ForEach-Object {
    $Computer = "$_"
    [array]$disks = Get-WmiObject -Class Win32_LogicalDisk -ComputerName $_ | Where-Object {$_.DriveType -eq 3} | `
    # For every drive you find on the computer, do the following
  
    # Loop through each drive found on the computer
    ForEach-Object {
        $DeviceID = $_.DeviceID
        $FreeSpace = $_.freespace
        $Size = $_.size 

        $Results = "$Computer,$DeviceID,$Size,$FreeSpace"

        # Write results to output file
        Add-Content -Path $outputfile -Value $Results

        # If minimum free space not available, add info to error report
        If (($FreeSpace/$Size) -le ($MinFreeSpacePercentage/100)){
            Add-Content -Value "$Computer drive $DeviceID has below $MinFreeSpacePercentage% free disk space" -Path $ErrorFile
            }
    }

}