Import-Module ActiveDirectory

# Retrieve all user accounts that begin with a number
[array]$Users = Get-ADUser -Filter * -Properties Description | Where-Object {$_.SamAccountName -ilike "[0-9]*"}

$Users | ForEach-Object {

    $FirstName = $_.GivenName
    $LastName = $_.Surname
    $OldDN = $_.DistinguishedName
    $NewUsername = $FirstName + "." + $LastName

    $StudentID = $_.SamAccountName
    $UPN = $_.UserPrincipalName -replace "$StudentID","$NewUsername"

    # Let the admin know what's happening
    Write-Host "Renaming $StudentID to $NewUserName"

    #Update user information
    Set-ADUser -Identity $OldDN `
               -DisplayName $NewUserName `
               -Description $StudentID `
               -SamAccountName $NewUsername `
               -UserPrincipalName $UPN

    #Rename the object in the AD to change its name
    Rename-ADObject -Identity $OldDN -NewName $NewUsername   
}
