# Manually updated progress bar
Write-Progress -Activity "Manual update in progress" -Status " 0 Percent complete" -PercentComplete 0 

Start-Sleep -Seconds 2
Write-Progress -Activity "Manual update in progress" -Status "33 Percent complete" -PercentComplete 33 

Start-Sleep -Seconds 2
Write-Progress -Activity "Manual update in progress" -Status "66 Percent complete" -PercentComplete 66 

Start-Sleep -Seconds 2
Write-Progress -Activity "Manual update in progress" -Status "99 Percent complete" -PercentComplete 99

Start-Sleep -Seconds 2

# Dynamically updated progress bar
Write-Progress -Activity "Dynamic update in progress" -Status "Doing something important" -PercentComplete 0
Start-Sleep -Seconds 2

for ($i=1;$i -le 5;$i++){
    Write-Progress -Activity  "Dynamic update in progress" -Status "Doing something important" -PercentComplete ($i/5*100)
    Start-Sleep -Seconds 2
} 

