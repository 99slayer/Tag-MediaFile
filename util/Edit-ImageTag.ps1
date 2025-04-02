function Edit-ImageTag {
	param (
		[Parameter(Mandatory,Position=0,ValueFromPipeline)]
		[string]$Path,
		[string[]]$Include,
		[string[]]$Exclude
	)
	if (!$Include -and !$Exclude) {return}
	$File = [TagLib.File]::Create((Resolve-Path $Path))
	$Tags = $File.ImageTag.Keywords

	if ($Include) {
		foreach ($Tag in $Include) {
			$Tags += $Tag
		}
	}
	if ($Exclude) {
		$NewTags = @()
		foreach ($Tag in $Tags) {
			if ($Exclude.Contains(($Tag))) {continue}
			$NewTags += $Tag
		}
		$Tags = $NewTags
	}

	$File.EnsureAvailableTags()
	$File.ImageTag.Keywords = ($Tags)
	$File.Save()

	$SavedFile = [TagLib.File]::Create((Resolve-Path $Path))
	$SavedTags = $SavedFile.ImageTag.Keywords -join ''
	$ExpectedTags = $Tags -join ''

	if ($SavedTags -ne $ExpectedTags) {
		throw "METADATA NOT PROPERLY SAVED"
	}
}
