
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