function Test-Device {
    # param (
    #     OptionalParameters
    # )
<#
test  # operatiing system, bit arcitechture, is a compatioble graohics card available, 7zip
if something doesnt match, throw an error
#>

    if ([System.Environment]::OSVersion.Version.Major -lt 10) {
        Throw "This script only supports Windows 10 and above. Your version: $($WindowsVersion.Major).$($WindowsVersion.Minor)"
    }

    if (-not [Environment]::Is64BitOperatingSystem) {
        Throw "This script only supports 64-bit operating systems."
    }

    $Apps = @("7z.exe", "nvidia-smi.exe ")
    foreach ($App in $Apps) {
        try {
            Get-Command -Name $App -ErrorAction SilentlyContinue
        }   
        catch {
            Throw "$App is not installed or not available in the PATH. Please install $App and try again."
        }
    }

}

Test-Device