Param ([Parameter(Mandatory=$true)][string]$username)

for ($i=1;$i -le 10;$i++){

	#Create bad credentials
	$password = convertto-securestring -String "BadP@ssword@!" -AsPlainText -Force
	$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password

	#Use bad credentials to lockout account
	New-PSDrive -Credential $cred -Name "Bogus" -Root "\\dc1\ipc$" -PSProvider FileSystem -ErrorAction 'SilentlyContinue'
}

If ($Error[0].Exception.Message -ieq "The referenced account is currently locked out and may not be logged on to"){
	Write-Host "`nAccount $UserName locked out!"
	Start-Sleep -Seconds 3
}
Else {
	Write-Host "`nAccount lockout FAILED:`n"
	$error[0]
	Start-Sleep -Seconds 3
}