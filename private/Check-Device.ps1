
function Test-Device {
    # param (
    #     OptionalParameters
    # )

    if ([System.Version][Environment]::OSVersion.Version.ToString() -lt [System.Version]"10.0")
	{
		Throw "Your Windows is unsupported. Upgrade to Windows 10 or higher"
	}

	# Checking Windows bitness
	if (-not [Environment]::Is64BitOperatingSystem)
	{
		Throw "Your Windows architecture is x86. x64 is required" 
	}
    
}

