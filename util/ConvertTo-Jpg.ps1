function ConvertTo-Jpg {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true)]
		$Files,
		[Parameter(Mandatory = $false, Position = 1)]
		[int]$Quality = 100
	)
	begin {
		Write-Verbose "Conversion start"
		$qualityEncoder = [System.Drawing.Imaging.Encoder]::Quality
		$encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
		# Set JPEG quality level here: 0 - 100 (inclusive bounds)
		$encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter($qualityEncoder, $Quality)
		$jpegCodecInfo = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
	}
	process {
		$Files | ForEach-Object {
			$fullName = $_.Fullname
			$image = [System.Drawing.Image]::FromFile($fullName)
			$filePath = "{0}\{1}.jpg" -f $($_.DirectoryName), $($_.BaseName)
			$image.Save($filePath, $jpegCodecInfo, $encoderParams)
			$image.Dispose()
		}
	}
	end {
		Write-Verbose "Conversion done"
	}
}
