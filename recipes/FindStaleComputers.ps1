$StaleAge = "30"
$ReportFilePath = "C:\Course969\stalecomputers.csv"

Search-ADAccount -AccountInactive -TimeSpan "$StaleAge.00:00:00" -ComputersOnly | `
   select-object -Property distinguishedname,LastLogonDate | `
   export-csv -path $ReportFilePath



