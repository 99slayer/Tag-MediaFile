# Doesn't work well with webp format
function Get-FileMetaData {
	[CmdletBinding()] # <=== idk if we need this??
	param (
		[Parameter(Position=0,ValueFromPipeline)]
		[object]$File
	)

	foreach ($F in $File) {
		$MetaDataObject = [ordered] @{}

		# $F type check
		if ($F -is [string]) {
			if ($F -and (Test-Path -LiteralPath $F)) {
				$FileInformation = Get-ItemProperty -Path $F

				if ($FileInformation -is [System.IO.DirectoryInfo]) {
					continue
				}
			} else {
				Write-Warning "Get-FileMetaData - Doesn't exists. Skipping $F."
				continue
			}
		} elseif ($F -is [System.IO.DirectoryInfo]) {
			#Write-Warning "Get-FileMetaData - Directories are not supported. Skipping $F."
			continue
		} elseif ($F -is [System.IO.FileInfo]) {
			$FileInformation = $F
		} else {
			Write-Warning "Get-FileMetaData - Only files are supported. Skipping $F."
			continue
		}

		$ShellApplication = New-Object -ComObject Shell.Application
		$ShellFolder = $ShellApplication.Namespace($FileInformation.Directory.FullName)
		$ShellFile = $ShellFolder.ParseName($FileInformation.Name)
		$MetaDataProperties = [ordered] @{}

		0..400 | ForEach-Object -Process {
			$DataValue = $ShellFolder.GetDetailsOf($null, $_)
			$PropertyValue = (Get-Culture).TextInfo.ToTitleCase($DataValue.Trim()).Replace(' ', '')

			if ($PropertyValue -ne '') {
				$MetaDataProperties["$_"] = $PropertyValue
			}
		}

		# saves valid existing properties to MetaDataObject
		foreach ($Key in $MetaDataProperties.Keys) {
			# <property> : <value>
			$Property = $MetaDataProperties[$Key]
			$Value = $ShellFolder.GetDetailsOf($ShellFile, [int] $Key)

			if ($Property -in 'Attributes', 'Folder', 'Type', 'SpaceFree', 'TotalSize', 'SpaceUsed') {
				continue
			}
			if (($null -ne $Value) -and ($Value -ne '')) {
				$MetaDataObject["$Property"] = $Value
			}
		}

		if ($FileInformation.VersionInfo) {
			$SplitInfo = ([string] $FileInformation.VersionInfo).Split([char]13)

			foreach ($Item in $SplitInfo) {
				$Property = $Item.Split(":").Trim()
				if ($Property[0] -and $Property[1] -ne '') {
					if ($Property[1] -in 'False', 'True') {
						$MetaDataObject["$($Property[0])"] = [bool] $Property[1]
					} else {
						$MetaDataObject["$($Property[0])"] = $Property[1]
					}
				}
			}
		}
		
		$MetaDataObject["Attributes"] = $FileInformation.Attributes
		$MetaDataObject['IsReadOnly'] = $FileInformation.IsReadOnly
		$MetaDataObject['IsHidden'] = $FileInformation.Attributes -like '*Hidden*'
		$MetaDataObject['IsSystem'] = $FileInformation.Attributes -like '*System*'
		[PSCustomObject] $MetaDataObject
	}
}
