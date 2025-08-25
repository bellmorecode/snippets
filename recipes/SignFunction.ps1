Function Sign-MyScript ([Parameter(Mandatory=$True)]$FilePath) {

  $Cert = (Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert)[0]

  Set-AuthenticodeSignature -Certificate $Cert -FilePath $FilePath

}