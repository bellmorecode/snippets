#Import-Module ActiveDirectory
#Change the below line to match the local administrator account for all workstations:
$Username = "Administrator"
$Global:Output = @()
$Results=@()
$UnreachableOutputPath = "c:\output\unreachable.txt"

############################
#Change the below filter to match all workstations you want to hit. Ours start with "WPSA" etc...
#Get-adcomputer -Filter * | Select -expand name | Sort-Object
# OR
#$Computers = Get-Content "C:\ComputerList.txt" 
# OR
Add-Type -AssemblyName System.Windows.Forms
# Browse for file to open
$openFileDialog1 = New-Object System.Windows.Forms.OpenFileDialog
$openFileDialog1.Filter = "Text Files|*.txt|All Files|*.*"
$openFileDialog1.Title = "Computer Names Input File"
$openFileDialog1.ShowDialog()
$InputFileName = $openFileDialog1.FileName
$Computers = Get-Content -path $InputFileName
############################

#Functions to verify the PW Change
 Function Verify-Account ([string]$Computer, [string]$User, [string]$Pass) {

    Add-Type -AssemblyName System.DirectoryServices.AccountManagement
    $DS = New-Object System.DirectoryServices.AccountManagement.PrincipalContext('machine',$Computer)
    $Out = $DS.ValidateCredentials($User, $Pass)
    return $Out
    
}
###########################################
#Drew's Create-RandomPassword Function 
###########################################
function Create-RandomPassword 
( 
   [int] $minLength = 14, 
   [int] $maxLength = 20, 
   [bool] $useSymbols = $true, 
   [bool] $asSecureString = $false
) 
{ 
   [System.Security.Cryptography.RNGCryptoServiceProvider] $random = 
      new-object System.Security.Cryptography.RNGCryptoServiceProvider 
    # Get an array of all characters that can be used in the password
   [string] $choice = Get-CharacterChoice -useSymbols $useSymbols
    
   $randomPassword = $null
   if (($minLength -le $maxLength) -and 
      ($minLength -ge 6)) 
   { 
      # Allocate a byte array of dimension 1
      $randomNumber = new-object byte[] 1 
      if ($minLength -eq $maxLength) 
      { 
         [int] $length = $minLength
      } 
      else 
      { 
         # Calculate a random length between minLength and maxLength
         $random.GetBytes($randomNumber) 
         [int] $length = $minLength + $randomNumber[0] % 
                     ($maxLength - $minLength + 1) 
      } 
      # Allocate a byte array of dimension $length
      $randomSequence = new-object byte[] $length
      $hasUCase = $hasLCase = $hasNum = $false
      while(!$hasUCase -or !$hasLCase -or !$hasNum) 
      { 
         # Generate random sequence of bytes
         $random.GetBytes($randomSequence) 
         # Ensure that there is at least one number, uppercase
         # character and lowercase character in the sequence.
         $hasUCase = $hasLCase = $hasNum = $false
         foreach($b in $randomSequence) 
         { 
            [char]$char = $choice[$b % $choice.Length] 
            if ($char -ge 'A' -and $char -le 'Z') 
            { 
               $hasUCase = $true
            } 
             
            if ($char -ge 'a' -and $char -le 'z') 
            { 
               $hasLCase = $true
            } 
             
            if ($char -ge '0' -and $char -le '9') 
            { 
               $hasNum = $true
            } 
         } 
      } 
  
      if ($asSecureString) 
      { 
         $randomPassword = new-object System.Security.SecureString 
      } 
      else 
      { 
         [string] $randomPassword = ''
      } 
       
      # Assign the password from the sequence of random bytes
      foreach($b in $randomSequence) 
      { 
         [char]$char = $choice[$b % $choice.Length] 
         if ($asSecureString) 
         { 
            $randomPassword.AppendChar($char) 
         } 
         else 
         { 
            $randomPassword += $char
         } 
      } 
   } 
    
   return $randomPassword
} 
# Outputs an array of all the characters that the generated password
# can be made up of.
function Get-CharacterChoice 
( 
   [bool] $useSymbols = $true
) 
{ 
   if ($useSymbols) 
   { 
      [string] $choice = '!"#$%&''()*+,-./'
   } 
   else 
   { 
      [string] $choice = ''
   } 
    
   $choice += '0123456789'
   if ($useSymbols) 
   { 
      $choice += ':;<=>?@'
   } 
    
   $choice += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
   if ($useSymbols) 
   { 
      $choice += '[\]^_`'
   } 
    
   $choice += 'abcdefghijklmnopqrstuvwxyz'
   if ($useSymbols) 
   { 
      $choice += '{|}~'
   } 
    
   return $choice
} 
 
 Foreach($Computer in $computers) 
{ 
    If(test-Connection -ComputerName $Computer -BufferSize 16 -Count 1 -ea 0 -Quiet){
            
        $FileOut=@{}
        $FileOut.Computer = $Computer
        $FileOut.UserName = $UserName
        $FileOut.Password = Create-RandomPassword
        #Sets the password
        $de = [adsi]"WinNT://$Computer/$UserName,user" 
        $de.SetPassword($FileOut.Password) 
        $de.SetInfo() 
        #Verify new password has been set
        $FileOut.Verified = Verify-Account -Computer $Computer -User $Username -Pass $FileOut.Password
        $FileOut.Time_Changed = Get-Date -f MM/dd/yyyy_HH:mm
        $obj = New-Object -TypeName PSObject -Property $FileOut
        Write-Output $obj
        $Results += $obj
    }
    Else{

        $FileOut=@{}
        $FileOut.Computer = $Computer
        $FileOut.UserName = $UserName
        $FileOut.Password = "Offline"
        $FileOut.Verified = "Offline"
        $FileOut.Time_Changed = Get-Date -f MM/dd/yyyy_HH:mm
        $obj = New-Object -TypeName PSObject -Property $FileOut
        Write-Output $obj
        $FileOut = $null
        $Results += $obj

        #Also write failed file for input for next run
        Add-Content -Value $Computer -Path $UnreachableOutputPath
        
    }
        
}
$Date = get-date -Format MM-dd-yyyy
#Change the line below to match the location you want the csv file stored.
$Results | Export-Csv "C:\Workstations_$Date.csv" -NoTypeInformation
