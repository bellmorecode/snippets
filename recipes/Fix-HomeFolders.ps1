# Define the folder containing your data
# BE SURE TO INCLUDE THE TRAILING \
$global:HomeFolderRoot = "U:\"

Function Configure-HomeFolder ([string][Parameter(Mandatory=$True)]$UserName) {

        # Grant user full control to the new home folder
        icacls ("$HomeFolderRoot$UserName") /grant ("$UserName" + ':(OI)(CI)M') /T
        Write-Host -Object ("$HomeFolderRoot$Username")

}

$HomeFolders = Get-ChildItem -Path $HomeFolderRoot
$HomeFolders | ForEach-Object {Configure-HomeFolder -UserName $_}

