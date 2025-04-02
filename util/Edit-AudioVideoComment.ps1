function Edit-AudioVideoComment {
	param (
		[Parameter(Mandatory,Position=0,ValueFromPipeline)]
		[string]$Path,
		[string[]]$Include,
		[string[]]$Exclude
	)
	if (!$Include -and !$Exclude) {return}
	$File = [TagLib.File]::Create((Resolve-Path $Path))

	$File.Tag.Comment = $Include -join '|';
	Start-Sleep -Milliseconds 200
	$File.Save()

	$SavedFile = [TagLib.File]::Create((Resolve-Path $Path))
	$Expected = $Include -join '|'
	$Saved = $SavedFile.Tag.Comment

	if ($Saved -ne $Expected) {
		throw "METADATA NOT PROPERLY SAVED"
	}
}
