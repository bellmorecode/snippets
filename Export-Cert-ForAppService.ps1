# Export Certificate

$certpassword = (ConvertTo-SecureString -String 'gfdata@pass@word1' -AsPlainText -Force)
$certloc = "C:\Users\glenn\Desktop\gfdatacorp\certificates_gfdata.io\gfdata-cert.pfx"

Export-PfxCertificate -Cert Cert:\LocalMachine\My\65EB1520663A5CFAFEA333F5693845D80132A407 -FilePath $certloc -Password $certpassword