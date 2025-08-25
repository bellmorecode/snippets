$Cred = Get-Credential

$RemService = Get-WmiObject -Class win32_service -ComputerName D1 -Credential $Cred `
  | Where-Object {$_.Name -ilike "spooler"}

$RemService.StartService()
