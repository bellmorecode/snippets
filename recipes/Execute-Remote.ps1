$AdminUser = "Bob-admin"
$SSPassword = Read-Host -AsSecureString -Prompt "Password"

$AdminCreds = New-Object -TypeName System.Management.Automation.PSCredential($AdminUser,$SSPassword)

Get-Content -Path "C:\pcs.txt" | ForEach-Object {
    Invoke-Command -ComputerName $_ -Credential $AdminCreds -ScriptBlock {<#Some code#>}
}