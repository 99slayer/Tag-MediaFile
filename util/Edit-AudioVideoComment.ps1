function Edit-AudioVideoComment {
	param (
		[Parameter(Mandatory,Position=0,ValueFromPipeline)]
		[string]$Path,
		[string[]]$Include,
		[string[]]$Exclude
	)
	if (!$Include -and !$Exclude) {return}

	[System.Reflection.Assembly]::LoadFrom((Resolve-Path "TagLibSharp.dll")) | Out-Null
	$File = [TagLib.File]::Create((Resolve-Path $Path))

	$File.Tag.Comment = $Include -join ' | ';
	Start-Sleep -Seconds 2
	$File.Save()

	$Expected = $Include -join ' | '
	$Saved = $File.Tag.Comment
	if ($Expected -ne $Saved) {
		throw "METADATA NOT PROPERLY SAVED"
	}
}
