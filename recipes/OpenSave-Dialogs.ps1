#========================================================================
# Created with: SAPIEN Technologies, Inc., PowerShell Studio 2012 v3.1.24
# Created on:   7/16/2014 9:01 PM
# Created by:   Shane Cribbs
# Organization: 
# Filename:     
#========================================================================

# Import the assembly once for the script
Add-Type -AssemblyName System.Windows.Forms

# Browse for file to open
$openFileDialog1 = New-Object System.Windows.Forms.OpenFileDialog
$openFileDialog1.Filter = "Text Files|*.txt|All Files|*.*"
$openFileDialog1.ShowDialog()
$InputFileName = $openFileDialog1.FileName
Write-Host "Input file is $InputFileName"

# Browse for file to save
$saveFileDialog1 = New-Object System.Windows.Forms.SaveFileDialog
$saveFileDialog1.Filter = "Text File|*.txt|All Types|*.*"
$saveFileDialog1.ShowDialog()
$OutputFileName = $saveFileDialog1.FileName
Write-Host "Output file is $OutputFileName"
