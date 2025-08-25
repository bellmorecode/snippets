#========================================================================
# Created with: SAPIEN Technologies, Inc., PowerShell Studio 2012 v3.1.19
# Created on:   8/5/2013 4:17 PM
# Created by:   Shane Cribbs
# Organization: 
# Filename:     
#========================================================================

$ie = New-Object -ComObject "InternetExplorer.Application"

$ie.navigate("http://msdn.microsoft.com")
$ie.visible = $True

while ($ie.Busy) {
	Start-Sleep -Milliseconds 500
}

Start-Sleep -Seconds 2

# Read the webpage into the $doc variable
$doc = $ie.Document

#Get the TexBox and Button objects
$tbDesc = $doc.GetElementbyId("tbDesc")
$cbTrustedSource = $doc.GetElementById("agree")
$btnContinue = $doc.GetElementById("nextbutton")

$tbDesc.Value = "TestPC-PowerShell"
while ($ie.Busy) {
	Start-Sleep -Milliseconds 500
}

$cbTrustedSource.Click()
$btnContinue.Click()

while ($ie.Busy) {
	Start-Sleep -Milliseconds 500
}

$btnInstall = $doc.GetElementById("downloadnow")
$btnInstall.Click()

Start-Sleep -Seconds 2

$wshell = new-object -com wscript.shell
#$wshell.appactivate("Save As")
$wshell.sendkeys("%s")
$wshell.sendkeys("{Enter}")