# auth using the aad / graph endpoints. 

# load System.Web / ASP.NET assembly
Add-Type -AssemblyName System.Web

$gfd_auth_url = "https://login.microsoftonline.com/e16e56f2-9747-40a6-8189-09ba0f1fa61c/oauth2/v2.0/token"
$gfd_clientid = "41e5805b-929a-4009-b480-7a449e73a2e2"
$client_secret = "0-yZ~0c15K7w_uQiy3L-_5613al92QyYkUqq"
$scope = "https://graph.microsoft.com/.default"
$grant_type = "client_credentials"

function encode {
    ([string]$val) 
    return [System.Web.HttpUtility]::UrlEncode($val)
}

[System.Web.HttpUtility]::UrlEncode($grant_type)

$a1 = encode -val $scope

Write-Host $a1