function Install-NVIDIA-Driver {
    # param (
    #     OptionalParameters
    # )

    Write-Host "Starting NVIDIA Driver Installation..." -ForegroundColor Cyan

    Test-Device

    $NvidiaGPU = Get-WmiObject Win32_VideoController | Where-Object { $_.Name -like "*NVIDIA*" }
    if ($null -eq $NvidiaGPU) {
        Throw "No NVIDIA GPU found on this system."
    }
    $CurrentDriverVersion = $NvidiaGPU.DriverVersion
    Write-Host "Current driver version: $CurrentDriverVersion"

    

    $LatestDriverVersion = Get-LatestDriverVersion

    if ($LatestDriverVersion -eq $CurrentDriverVersion) {
        Throw "You already have the latest driver version installed: $CurrentDriverVersion"
    }

    $DownloadLoation = Download-LatestDriver

    $ExtractedFolder = Extract-Driver -FilePath $DownloadLoation -LatestVersion $LatestDriverVersion

    Start-Installation $ExtractedFolder
    
}