<#
	An interactive file tagging function.
	Edits image file tags.
	Edits video/audio file comments.
	TEST TEST TEST
#>

Add-Type -AssemblyName System.Windows.Forms

function Tag-MediaFile {
	param (
		[Parameter(Position=0,Mandatory=$true,ValueFromPipeline)]
		[string]$Path,
		[switch]$Copy
	)
	Get-ChildItem -Path ".\util" | ForEach-Object {. $($_.FullName)}
	$Path = [IO.Path]::GetFullPath(($Path))
	$Files = Get-ChildItem -Path $Path -File | Sort-Object -Descending

	if (!$Files) {
		Write-Warning "NO FILES FOUND"
		return;
	}

	$ImageExtensions = @(
		".bmp", ".gif", ".jpeg", ".jpg", 
		".pbm", ".pgm", ".ppm", ".pnm", 
		".pcx", ".png", ".tiff", ".dng", 
		".svg"
	)
	$AudioExtensions = @(
		".aa", ".aax", ".aac", ".iff",
		".ape", ".dsf", ".flac", ".m4a",
		".m4b", ".m4p", ".mp3", ".mpc",
		".mpp", ".ogg", ".oga", ".wav",
		".wma", ".wv", ".webm"
	)
	$VideoExtensions = @(
		".mkv", ".ogv", ".avi", ".wmv",
		".asf", ".mp4", ".m4p", ".m4v",
		".mpeg", ".mpg", ".mpe", ".mpv",
		".mpg", ".m2v"
	)

	New-Item -Path $Path -ItemType Directory -Name tagged -ErrorAction Ignore | Out-Null
	New-Item -Path $Path -ItemType Directory -Name converted -ErrorAction Ignore | Out-Null

	foreach ($File in $Files) {
		if ($File.Extension -in $ImageExtensions) {$FileType = "image"} 
		elseif (
			$File.Extension -in $VideoExtensions -or
			$File.Extension -in $AudioExtensions
		) {$FileType = "audiovideo"}
		else {continue}

		$Count = 1
		while (Test-Path -Path "$($Path)\$($File.BaseName)-$($Count)$($File.Extension)") {
			$Count++
		}
		$FileBackup = "$($File.BaseName)-$($Count)$($File.Extension)"
		Copy-Item $File.FullName -Destination "$($Path)\$($FileBackup)"

		Start-Process $File
		Start-Sleep -Milliseconds 300

		Set-DesktopWindow -Name $File.Name -Height 500 -Width 500 -Left 1910 -Top 0
		[System.Windows.Forms.SendKeys]::SendWait("%{TAB}")

		$FileData = Get-FileMetaData $File
		$UnwantedTags = ''
		$NewTags = ''

		if ($FileData.Tags) {
			Write-Host "Existing tags:"
			Write-Host "$($FileData.Tags)"
			$RemoveTag = Read-Host -Prompt "Would you like to remove any tags? Y/N"

			if ($RemoveTag -eq 'y') {
				$UnwantedTags = Read-Host -Prompt 'REMOVE <tag>;<tag>'
			}
		}

		$NewTags = Read-Host -Prompt 'ADD <tag>;<tag>'
		Set-DesktopWindow -Name $File.Name -State Close

		$OriginalName = $File.Name
		try {
			if ($FileType -eq "image") {
				Edit-ImageTag -Path $File.FullName -Include $NewTags.Split(';') -Exclude $UnwantedTags.Split(';')
			} elseif ($FileType -eq "audiovideo") {
				Edit-AudioVideoComment -Path $File.FullName -Include $NewTags.Split(';') -Exclude $UnwantedTags.Split(';')
			}
			if ($Copy) {
				Move-Item -Path $File.FullName -Destination "$($Path)\tagged\"
				Rename-Item -Path "$($Path)\$($FileBackup)" -NewName $OriginalName
			} else {
				Move-Item -Path $File.FullName -Destination "$($Path)\tagged\"
				Remove-Item -Path "$($Path)\$($FileBackup)"
			}
		} catch {
			Write-Warning "Problem editing $($File.Name)"
			Write-Error $_.Exception.Message

			Remove-Item -Path $File
			Rename-Item -Path "$($Path)\$($FileBackup)" -NewName $OriginalName
		}
	}
}
