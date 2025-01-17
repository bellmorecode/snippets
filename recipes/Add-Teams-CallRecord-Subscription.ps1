# Load CSharp Assembly for HttpUtility
Add-Type -AssemblyName System.Web

$client_state = "bellmore-code-telemetry-callrecords"
$notifyUrl = "https://gfdatafunx.azurewebsites.net/api/subs/callRecords/hook?code=CcZmuUjYN1jsjeJWqGX1De6OXN4Kv3JMV078geg1pnJZtCYJWRYaPA=="
$lifecycleUrl = "https://gfdatafunx.azurewebsites.net/api/subs/callRecords/feed/refresh?code=LfH5lIKBY1HCjyxdjJAPcb2dQozXIj0PhzPy9AaRyy6z8tnVIGXteg=="

# resourceURL
$subs_url = "https://graph.microsoft.com/v1.0/subscriptions"
# scope
$scope = [System.Web.HttpUtility]::UrlEncode("https://graph.microsoft.com/.default")

# auth details
$apikey = "186753e1-5f9c-4084-99b6-81040a4eaba6"
$secret = [System.Web.HttpUtility]::UrlEncode("z6YK.~K1zxuQi~W1b-6969Qgg.mXO_hrR3")
$tenant = "e16e56f2-9747-40a6-8189-09ba0f1fa61c"

# request preparation
$auth_url = "https://login.microsoftonline.com/$tenant/oauth2/v2.0/token"
$auth_body = "client_id=$apikey&client_secret=$secret&scope=$scope&grant_type=client_credentials"

# make authorization request
$resp = Invoke-WebRequest -UseBasicParsing -Uri $auth_url -Method "POST" -Body $auth_body
# get auth token from response
$respObj = ConvertFrom-Json $resp.Content
# create bearer token
$dict = @{"Authorization"="Bearer $($respObj.access_token)";"Content-Type"="application/json"}

# make subscription request object
$body = "{""changeType"":""created,updated"",""lifecycleNotificationUrl"":""$lifecycleUrl"",""notificationUrl"":""$notifyUrl"",""resource"":""/communications/callRecords"",""expirationDateTime"":""2021-06-24T23:59:59.9999999Z"", ""clientState"":""$client_state""}"

# send subscription request
$resp2 = Invoke-WebRequest -UseBasicParsing -Uri $subs_url -Method "POST" -Body $body -Headers $dict

# show result
Write-Host $resp2.Content

https://gfdatafunx.azurewebsites.net/api/subs/callRecords/hook?code=CcZmuUjYN1jsjeJWqGX1De6OXN4Kv3JMV078geg1pnJZtCYJWRYaPA==

