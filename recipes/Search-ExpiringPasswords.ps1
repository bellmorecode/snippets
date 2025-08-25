$maxPasswordAge = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge.Days

$CheckDays = (get-date).AddDays(7 - $maxPasswordAge).ToShortDateString()

Get-ADUser -filter {Enabled -eq $true -and PasswordNeverExpires -eq $False -and PasswordLastSet -gt 0} -Properties * | `
  Where-Object {($_.PasswordLastSet).ToShortDateString() -eq $CheckDays} | `
  Select-Object *