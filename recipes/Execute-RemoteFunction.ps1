Function Run-On ($computername) {
    $AdminUser = "Bob-admin"
    $SSPassword = Read-Host -AsSecureString -Prompt "Password"

    $AdminCreds = New-Object -TypeName System.Management.Automation.PSCredential($AdminUser,$SSPassword)

    Invoke-Command -ComputerName $ComputerName -Credential $AdminCreds -ScriptBlock {Get-Service}
}