<#
	.SYNOPSIS
	Check for the latest NVIdia driver version, and if it's lower than the current one download

	.PARAMETER Clean
	Delete the old driver, reset settings and install the newest one

	.EXAMPLE
	UpdateNVidiaDriver

	.NOTES
	Supports Windows 10 x64 & Windows 11 only
 
	.NOTES
	Installer 2.0 Command Line Guide

	.NOTES
	https://docs.nvidia.com/sdk-manager/sdkm-command-line-install/index.html
#>
function UpdateNVidiaDriver
{

	

	

	

	

	# Get the latest 7-Zip download URL
	try
	{
		$Parameters = @{
			Uri             = "https://sourceforge.net/projects/sevenzip/best_release.json"
			UseBasicParsing = $true
			Verbose         = $true
		}
		$bestRelease = (Invoke-RestMethod @Parameters).platform_releases.windows.filename.replace("exe", "msi")
	}
	catch [System.Net.WebException]
	{
		Write-Warning -Message "Connection cannot be established"
		exit
  		pause
	}

	# Download the latest 7-Zip x64
	try
	{
		$Parameters = @{
			Uri             = "https://unlimited.dl.sourceforge.net/project/sevenzip$($bestRelease)?viasf=1"
			OutFile         = "$DownloadsFolder\7Zip.msi"
			UseBasicParsing = $true
			Verbose         = $true
		}
		Invoke-WebRequest @Parameters
	}
	catch [System.Net.WebException]
	{
		Write-Warning -Message "Connection cannot be established"
		exit
  		pause
	}

	# Expand 7-Zip
	$Arguments = @(
		"/a `"$DownloadsFolder\7Zip.msi`""
		"TARGETDIR=`"$DownloadsFolder\7zip`""
		"/qb"
	)
	Start-Process "msiexec" -ArgumentList $Arguments -Wait

	# Delete the installer once it completes
	Remove-Item -Path "$DownloadsFolder\7Zip.msi" -Force

	# Extracting installer
	# Based on 7-zip.chm
	$Arguments = @(
		# Extracts files from an archive with their full paths in the current directory, or in an output directory if specified
		"x",
		# standard output messages. disable stream
		"-bso0",
		# progress information. redirect to stdout stream
		"-bsp1",
		# error messages. redirect to stdout stream
		"-bse1",
		# Overwrite All existing files without prompt
		"-aoa",
		# What to extract
		"$DownloadsFolder\$LatestVersion-desktop-win10-win11-64bit-international-dch-whql.exe",
		# Extract these files and folders
		"Display.Driver HDAudio NVI2 NVApp NVApp.MessageBus NVCpl PhysX EULA.txt ListDevices.txt setup.cfg setup.exe",
		# Specifies a destination directory where files are to be extracted
		"-o`"$DownloadsFolder\NVidia`""
	)
	$Parameters = @{
		FilePath     = "$DownloadsFolder\7zip\Files\7-Zip\7z.exe"
		ArgumentList = $Arguments
		NoNewWindow  = $true
		Wait         = $true
	}
	Start-Process @Parameters

	<# Remove unnecessary dependencies from setup.cfg
	[xml]$setup = Get-Content -Path "$DownloadsFolder\NVidia\setup.cfg" -Encoding UTF8 -Force
	($setup.setup.manifest.file | Where-Object -FilterScript {@("`${{EulaHtmlFile}}", "`${{FunctionalConsentFile}}", "`${{PrivacyPolicyFile}}") -contains $_.name }) | ForEach-Object {
		$_.ParentNode.RemoveChild($_)
	}
	$setup.Save("$DownloadsFolder\NVidia\setup.cfg")
	#>

	$Parameters = @{
		Path    = "$DownloadsFolder\7zip", "$DownloadsFolder\$LatestVersion-desktop-win10-win11-64bit-international-dch-whql.exe"
		Recurse = $true
		Force   = $true
	}
	Remove-Item @Parameters

	Invoke-Item -Path "$DownloadsFolder\NVidia"
}

UpdateNVidiaDriver
