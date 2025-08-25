Get-ADComputer -Filter * -SearchBase "DC=course969,DC=com" | ForEach-Object {
    
    $computername = $_.name

    If(Test-Connection $computername -Quiet){
    
    $Admin = [ADSI]"WinNT://$computername/Administrator,User"
    $Admin.SetPassword("NewPassword")
    }

    Else{Add-Content -value "$computername local admin not updated" -Path "C:\Output\failedcomputers.txt"}
}

Get-Content -Path "Somefile.txt" | ForEach-Object {
    
    $computername = $_

    If(Test-Connection $computername -Quiet){
    
    $Admin = [ADSI]"WinNT://$computername/Administrator,User"
    $Admin.SetPassword("NewPassword")
    }

    Else{Add-Content -value "$computername local admin not updated" -Path "C:\Output\failedcomputers.txt"}
}