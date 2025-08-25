$navOpenInNewTab = 2048
$navOpenInBackgroundTab = 4096

$ie = New-Object -ComObject "InternetExplorer.Application"
$ie.Navigate("www.google.com")
$ie.Navigate("news.google.com",2048)
$ie.Navigate("www.microsoft.com",4096)
$ie.Visible = $True