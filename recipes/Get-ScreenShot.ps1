Function Get-ScreenShot
{
	<#
	.SYNOPSIS
		Get screenshot.

	.DESCRIPTION
		Use Get-ScreenShot to get screen view from all or specific screen to image file.
		
	.PARAMETER Path
		Destination of screenshots.
	
	.PARAMETER FileName
		Screenshot file name. Default is Screenshot.png.

	.PARAMETER Type
		Specifies an image format type. Allowet are "jpg", "bmp", "emf", "gif", "ico", "png", "tif", "wmf". Default is png. 
		
	.PARAMETER ScreenNumber	
	    Number of screen to get screenshot. Default is 0 - all screens.

	.EXAMPLE
		Get full screenshot.
		
		Get-Screen
	
	.EXAMPLE
		Get screenshot from second screen only.

		Get-Screen -Path p:\ -FileName PSScreenShot.png -ScreenNumber 2
		
	.NOTES
		Author: Michal Gajda
		Blog  : http://commandlinegeeks.com/
		
	.LINK
		http://msdn.microsoft.com/en-us/library/system.windows.forms.screen.aspx
		http://msdn.microsoft.com/en-us/library/system.drawing.bitmap.aspx
		http://msdn.microsoft.com/en-us/library/system.drawing.graphics.aspx
	#>
	[CmdletBinding()]
	Param
	(
		[String]$Path = (Get-Location).Path,
		[String]$FileName = "Screenshot",
		[ValidateSet("jpg", "bmp", "emf", "gif", "ico", "png", "tif", "wmf")]
		[String]$Type = "png",
		[Int]$ScreenNumber = 0
	)
	
	#Load Assembly
	[void] [Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
	[void] [Reflection.Assembly]::LoadWithPartialName("System.Drawing")
	
	#Get screens details
	$Screens = [System.Windows.Forms.Screen]::AllScreens
	
	#Choose screenshot size
	If($ScreenNumber -eq 0)
	{
		#Full screen
		ForEach ($Screen in $Screens) 
		{
			$MaxWidth  += $Screen.Bounds.Width
			if($MaxHeight -lt $Screen.Bounds.Height)
			{
				$MaxHeight  = $Screen.Bounds.Height
			}	
			
			$ScreensSize = New-Object PSObject -Property @{
				X = 0
				Y = 0
				Width = $MaxWidth
				Height = $MaxHeight
			}
		}
	}
	elseif($ScreenNumber -le $Screens.Count)
	{
		#Custom screen
		if($ScreenNumber -ge 2)
		{
			$sn = $ScreenNumber
			while($sn-2 -ge 0)
			{
				$X += $Screens[$sn-2].Bounds.Width
				$sn--
			}
			$Y = 0
		}
		else
		{
			$X = 0
			$Y = 0
		}
		
		$ScreensSize = New-Object PSObject -Property @{
			X = $X
			Y = $Y
			Width = $Screens[$ScreenNumber-1].Bounds.Width
			Height = $Screens[$ScreenNumber-1].Bounds.Height
		}
	}
	else
	{
		Write-Error "Wrong screen" -ErrorAction Stop
	}

	#Choose image type
	Switch($Type)
	{
		{$_ -eq "jpg"} {$ImageFormat = [System.Drawing.Imaging.ImageFormat]::Jpeg; Break}
		{$_ -eq "bmp"} {$ImageFormat = [System.Drawing.Imaging.ImageFormat]::Bmp; Break}
		{$_ -eq "emf"} {$ImageFormat = [System.Drawing.Imaging.ImageFormat]::Emf; Break}
		{$_ -eq "gif"} {$ImageFormat = [System.Drawing.Imaging.ImageFormat]::Gif; Break}
		{$_ -eq "ico"} {$ImageFormat = [System.Drawing.Imaging.ImageFormat]::Icon; Break}
		{$_ -eq "png"} {$ImageFormat = [System.Drawing.Imaging.ImageFormat]::Png; Break}
		{$_ -eq "tif"} {$ImageFormat = [System.Drawing.Imaging.ImageFormat]::Tiff; Break}
		{$_ -eq "wmf"} {$ImageFormat = [System.Drawing.Imaging.ImageFormat]::Wmf; Break}
	}
				
	#Generate file name
	$i = 1
	Do
	{
		$Name = $FileName -replace ".$Type",""
		
		if($i -gt 1)
		{
			$Name += "-$i"
		}
		
		$FullPath = Join-Path -Path $Path -ChildPath "$Name.$Type"
		$i++
	}
	while(Test-Path -Path $FullPath)
	
	#Generate screenshot
	$Size = New-Object System.Drawing.Size $ScreensSize.Width, $ScreensSize.Height
	$Bitmap = New-Object System.Drawing.Bitmap $ScreensSize.Width, $ScreensSize.Height
	$Screenshot = [Drawing.Graphics]::FromImage($Bitmap)
	$Screenshot.CopyFromScreen($ScreensSize.X, $ScreensSize.Y, 0, 0, $Size)
	$Bitmap.Save($FullPath,$ImageFormat)
	$Screenshot.Dispose()
	$Bitmap.Dispose()
}
