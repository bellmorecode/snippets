#**************************
$DefaultGW = "10.1.1.254"
$DNSServers = "10.1.1.101"
#$DNSServers = "10.1.1.100,10.1.1.101"

#**************************

#Get target machines from file
#$Computers = Get-Content -Path c:\computers.txt

#Get target machines from AD, modify SEARCHBASE parameter if necessary
$RootDSE = ([ADSI]"LDAP://RootDSE").defaultNamingContext
[array]$ADComputers = Get-ADComputer -Filter * -SearchBase "CN=Computers,$RootDSE" -Properties Name
[array]$Computers = @()
$ADComputers | ForEach-Object {$Computers += ($_.name)}

$Computers | ForEach-Object{
    [array]$NICs = Get-WmiObject -ComputerName $_ -class win32_networkadapterconfiguration -filter "(ipenabled = 'true') and (DHCPEnabled = 'False')"
    $NICs | ForEach-Object {
        $_.SetGateways($DefaultGW, 1)
        $_.SetDNSServerSearchOrder($DNSServers)
    }
}