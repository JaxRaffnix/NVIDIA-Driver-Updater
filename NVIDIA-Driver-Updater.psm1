# Import all private helpers
Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -Recurse | ForEach-Object {
     . $_.FullName
}

# Import all public functions
Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" -Recurse | ForEach-Object {
     . $_.FullName
}

# Export functions whose names match public file names and actually exist
$functionsToExport = Get-ChildItem "$PSScriptRoot\Public\*.ps1" | ForEach-Object {
     $funcName = $_.BaseName
     if (Get-Command $funcName -CommandType Function -ErrorAction SilentlyContinue) {
          $funcName
     }
}
Export-ModuleMember -Function $functionsToExport