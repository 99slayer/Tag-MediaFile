# Tag-MediaFile
Iterates over the media files in a directory, opening them and allowing users to add tags via their terminal. The tagged files are moved into a new subdirectory.

## Overview
My first powershell project! Finding a specific media file among the thousands I have can be a real hassle. So I wanted to create something to help make searching through them easier.

## Installation
Follow these steps to install the project locally:

1. Clone the project\
`git clone git@github.com:99slayer/Tag-MediaFile.git`
2. Install [DesktopManager](https://github.com/EvotecIT/DesktopManager) powershell module\
`Install-Module DesktopManager -Force -Verbose`
3. Download `taglibsharp.nupkg` [here](https://www.nuget.org/packages/TagLibSharp).\
![installation image 1](/assets/installation-image-1.png)\
Extract the contents and move `TagLibSharp.dll` from `\taglibsharp<version #>\lib\netstandard2.0`\
![installation image 2](/assets/installation-image-2.png)\
-to the project's root directory.

## Usage
First, dot source Tag-MediaFile.ps1.\
<small>(please note, your path will most likely be different)</small>\
`. C:\PowerShell\Projects\Tag-MediaFile\Tag-MediaFile.ps1`

Then run the project!\
`Tag-MediaFile -Path <target directory path>`

#### Things to note
* All non-jpg image formats are converted to jpgs. The converted files are stored in their own directory.
* Due to certain library limitations audio and video files have their comments changed rather than their tags.
* Currently if your default media player is not VLC the project will not work correctly.

## Credit
This project utilizes:
* [taglib-sharp](https://github.com/mono/taglib-sharp)
* [DesktopManager](https://github.com/EvotecIT/DesktopManager)
* Also the ConvertTo-Jpg function is a slightly altered version of [this](https://www.powershellgallery.com/packages/NullKit/1.2.0/Content/media%5CConvertTo-Jpg.ps1).
