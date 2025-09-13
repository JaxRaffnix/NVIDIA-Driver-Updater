
function Get-CurrentDriverVersion {
    # param (
    #     OptionalParameters
    # )
    
    if (Test-Path -Path "$env:SystemRoot\System32\DriverStore\FileRepository\nv_*\nvidia-smi.exe")
	{
		# The NVIDIA System Management Interface (nvidia-smi) is a command line utility, based on top of the NVIDIA Management Library (NVML)
		$CurrentDriverVersion = nvidia-smi.exe --format=csv,noheader --query-gpu=driver_version
	}
	else
	{
		[System.Version]$Driver = (Get-CimInstance -ClassName Win32_VideoController | Where-Object -FilterScript {$_.Name -match "NVIDIA"}).DriverVersion
  		if ($Driver)
    		{
      		
			$CurrentDriverVersion = ("{0}{1}" -f $Driver.Build, $Driver.Revision).Substring(1).Insert(3,'.')
   		}
     		else
       		{
			Throw "No NVIDIA card detected." 
   		}
	}

	Write-Host "Current version: $CurrentDriverVersion"
	# Write-Information -MessageData "" -InformationAction Continue

    return $CurrentDriverVersion
}

# Get-CurrentDriverVersion


function Get-LatestDriverVersion {
    # param (
    #     OptionalParameters
    # )

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

	if ($Host.Version.Major -eq 5)
	{
		# Progress bar can significantly impact cmdlet performance
		# https://github.com/PowerShell/PowerShell/issues/2138
		$Script:ProgressPreference = "SilentlyContinue"
	}

	# Checking latest driver version from Nvidia website
	$Parameters = @{
		Uri             = "https://www.nvidia.com/Download/API/lookupValueSearch.aspx?TypeID=3"
		UseBasicParsing = $true
	}
	[xml]$Content = (Invoke-WebRequest @Parameters).Content
	$CardModelName = (Get-CimInstance -ClassName CIM_VideoController | Where-Object -FilterScript {($_.AdapterDACType -notmatch "Internal") -and ($_.Status -eq "OK")}).Caption.Split(" ")
	if (-not $CardModelName)
	{
		Throw "There's no active videocard in system" 
	}

	# Remove the first word in full model name. E.g. "NVIDIA"
	$CardModelName = [string]$CardModelName[1..($CardModelName.Count)]
	$ParentID = ($Content.LookupValueSearch.LookupValues.LookupValue | Where-Object -FilterScript {$_.Name -match $CardModelName}).ParentID | Select-Object -First 1
	$Value = ($Content.LookupValueSearch.LookupValues.LookupValue | Where-Object -FilterScript {$_.Name -match $CardModelName}).Value | Select-Object -First 1

	# https://github.com/fyr77/EnvyUpdate/wiki/Nvidia-API
	# osID=57 — Windows x64/Windows 11
	# languageCode=1033 — English language
	# dch=1 — DCH drivers
	# https://nvidia.custhelp.com/app/answers/detail/a_id/4777/~/nvidia-dch%2Fstandard-display-drivers-for-windows-10-faq
	# upCRD=0 — Game Ready Driver
	$Parameters = @{
		Uri             = "https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php?func=DriverManualLookup&psid=$ParentID&pfid=$Value&osID=57&languageCode=1033&beta=null&isWHQL=1&dltype=-1&dch=1&upCRD=0"
		UseBasicParsing = $true
	}
	$Data = Invoke-RestMethod @Parameters

	if ($Data.IDS.downloadInfo.Version)
	{
		$LatestVersion = $Data.IDS.downloadInfo.Version
		Write-Host "Latest version: $LatestVersion" 
		# Write-Information -MessageData "" -InformationAction Continue
	}
	else
	{
		Throw  "Something went wrong"
	}

    # return $LatestVersion

	# TODO: move version compparison to a gloabl function
    # Comparing installed driver version to latest driver version from Nvidia
	# if (-not $Clean -and ([System.Version]$LatestVersion -eq [System.Version]$CurrentDriverVersion))
	# {
	# 	Throw "The current installed NVidia driver is the same as the latest one" 
	# }

	$DownloadsFolder = Get-ItemPropertyValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "{374DE290-123F-4565-9164-39C4925E467B}"
	if (-not (Test-Path -Path "$DownloadsFolder\$LatestVersion-desktop-win10-win11-64bit-international-dch-whql.exe"))
	{
		# Downloading installer
		try
		{
			$Parameters = @{
				Uri             = $Data.IDS.downloadInfo.DownloadURL
				OutFile         = "$DownloadsFolder\$LatestVersion-desktop-win10-win11-64bit-international-dch-whql.exe"
				UseBasicParsing = $true
				Verbose         = $true
			}
			Invoke-WebRequest @Parameters
		}
		catch [System.Net.WebException]
		{
			Throw "Connection cannot be established"
		}
	}

	Write-Warning -Message "Downloading..."
 	Write-Warning -Message $Data.IDS.downloadInfo.DownloadURL
    
}

Get-LatestDriverVersion


# Extracting installer
	


function Extract-Driver {
    param (
        $FilePath,
        $LatestVersion,
        $DestinationFolder = "$env:USERPROFILE\Downloads\NVIDIA Driver $LatestVersion"
    )

    # TODO: test 7zip / nanazip install

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
		$FilePath,
		# Extract these files and folders
		"Display.Driver HDAudio NVI2 NVApp NVApp.MessageBus NVCpl PhysX EULA.txt ListDevices.txt setup.cfg setup.exe",
		# Specifies a destination directory where files are to be extracted
		"-o`"C:\Users\Jax\Downloads\NVidia`""
	)
	$Parameters = @{
		FilePath     = "7z.exe"
		ArgumentList = $Arguments
		NoNewWindow  = $true
		Wait         = $true
	}
	Start-Process @Parameters

    $SetupExePath = Join-Path -Path $DestinationFolder -ChildPath "setup.exe"
    if (Test-Path $SetupExePath) {
        Start-Process -FilePath $SetupExePath -Wait
    } else {
        Write-Error "setup.exe not found in $DestinationFolder"
    }
    
}