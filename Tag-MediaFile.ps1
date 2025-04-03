Add-Type -AssemblyName System.Windows.Forms

<#
.SYNOPSIS
An interactive script that iterates over a group of files and allows users to add tags via the terminal. The tagged files are moved into a new directory.

.PARAMETER Path
Path of the target directory.

.PARAMETER Copy
Create file copies in the target directory after the tagged files are moved.

.PARAMETER Secondary
Open files on the users secondary monitor.

.NOTES
All non-jpg image formats are converted to jpgs. The converted files are stored in their own directory.

Due to certain library limitations audio and video files have their comments changed rather than their tags.

Using media players other than VLC will cause problems.
#>

function Tag-MediaFile {
	param (
		[Parameter(Position=0,Mandatory=$true,ValueFromPipeline)]
		[string]$Path,
		[switch]$Copy,
		[switch]$Secondary
	)
	Get-ChildItem -Path ".\util" | ForEach-Object {. $($_.FullName)}
	[System.Reflection.Assembly]::LoadFrom((Resolve-Path "TagLibSharp.dll")) | Out-Null
	$Path = [IO.Path]::GetFullPath(($Path))

	$ToJpg = @(
		".bmp", ".gif", ".pbm", ".pgm",
		".ppm", ".pnm", ".pcx", ".png",
		".tiff", ".dng", ".svg"
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

	# Convert to jpgs
	foreach ($extension in $ToJpg) {
		$FileGroup = Get-ChildItem $Path -File -Filter "*$($extension)"
		$FileGroup | ConvertTo-Jpg
		$FileGroup | Move-Item -Destination "$($Path)\converted"
	}

	$Files = Get-ChildItem -Path $Path -File | Sort-Object -Descending

	if (!$Files) {
		Write-Warning "NO FILES FOUND"
		return;
	}

	foreach ($File in $Files) {
		if (
			$File.Extension -eq ".jpg" -or 
			$File.Extension -eq ".jpeg"
		) {$FileType = "image"} 
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
		Start-Sleep -Milliseconds 200

		$Monitors = Get-DesktopMonitors
		$Monitor = If ($Secondary) {$Monitors[0]} Else {$Monitors[1]}

		Set-DesktopWindow -Name $File.Name -Top $Monitor.PositionTop -Left $Monitor.PositionLeft
		if ($Secondary) {[System.Windows.Forms.SendKeys]::SendWait("%{TAB}")}

		$FileData = [TagLib.File]::Create((Resolve-Path $File))
		if ($FileType -eq "image") {$Tags = $FileData.ImageTag.Keywords}

		$UnwantedTags = ''
		$NewTags = ''

		if ($Tags) {
			Write-Host "Existing tags:"
			Write-Host "$($Tags)"
			$RemoveTag = Read-Host -Prompt "Would you like to remove any tags? Y/N"

			if ($RemoveTag -eq 'y') {
				$UnwantedTags = Read-Host -Prompt 'REMOVE <tag>;<tag>'
			}
		}

		$NewTags = Read-Host -Prompt 'ADD <tag>;<tag>'
		Set-DesktopWindow -Name $File.Name -State Close
		Start-Sleep -Milliseconds 200

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

			Set-DesktopWindow -Name $File.Name -State Close
			Start-Sleep -Milliseconds 200

			Remove-Item -Path $File
			Rename-Item -Path "$($Path)\$($FileBackup)" -NewName $OriginalName
		}
	}
}
