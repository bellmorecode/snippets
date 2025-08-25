# gwmi Win32_SystemDriver | Where-Object { $_.DisplayName -like "*HID*" }

# devmgmt.msc

# Find Plug & Play (PNP) devices with "touch" in the name
$devices = Get-PnpDevice  | where friendlyname -like "*touch*" 

# $devices | Disable-PnpDevice -Confirm:$false

$devices | Enable-PnpDevice -Confirm:$false