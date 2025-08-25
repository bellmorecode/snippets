$ExcelApp = New-Object -comobject Excel.Application

$ExcelApp.Visible = $True

$WB = $ExcelApp.Workbooks.Add()
$c = $WB.Worksheets.Item(1)

$c.Cells.Item(1,1) = "A value in cell A1."
$WB.SaveAs("C:\Scripts\Test.xls")

$ExcelApp.Quit()
