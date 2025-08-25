Function Get-LoggedOnUser ($computer="localhost"){
    (Get-WmiObject -Class Win32_ComputerSystem -ComputerName $computer).username
}