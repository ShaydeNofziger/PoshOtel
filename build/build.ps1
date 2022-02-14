[CmdletBinding()]
param(
    [string]$Version = '0.0.1'
)

$ErrorActionPreference = 'Stop'

$ProjectRootPath = Split-Path -Path $PSScriptRoot -Parent -Resolve
$BuildDirectoryPath = Join-Path -Path $ProjectRootPath -ChildPath 'build' -Resolve
$SrcDirectoryPath = Join-Path -Path $ProjectRootPath -ChildPath 'src' -Resolve
$ToolsDirectoryPath = Join-Path $ProjectRootPath -ChildPath 'tools' -Resolve
$BinDirectoryPath = Join-Path -Path $ProjectRootPath -ChildPath 'bin'

Invoke-ScriptAnalyzer -Settings $BuildDirectoryPath\PSScriptAnalyzerSettings.psd1 -Path $SrcDirectoryPath -ReportSummary

$MODULE_GUID = [Guid]::new('2CA13CCF-8751-4D25-9CBF-998727787367')

if (Test-Path "$BuildDirectoryPath\secrets.ps1") {
    Write-Verbose 'secrets.ps1 file found. Loading secrets...'
    . $BuildDirectoryPath\secrets.ps1
}

Remove-Item -Path $BinDirectoryPath -Recurse -Force

Write-Verbose -Message 'Installing required dependencies...'
. $ToolsDirectoryPath\install.ps1

Write-Verbose -Message 'Copying src files to bin directory...'
Copy-Item -Path "$SrcDirectoryPath\*.ps1", "$SrcDirectoryPath\*.psm1" -Destination $BinDirectoryPath -Force

# All files under the bin directory are packaged here, currently. Anything in bin is considered part of the module.
# Any operations to clean-up and add to the file list should be done prior to this step.
# TODO: How to include only the exact dlls and resource files we need? dll's and runtime directory?
$RequiredFiles = @()
$RequiredFilesList = Get-ChildItem -Path $BinDirectoryPath -Recurse -File
foreach($RequiredFile in $RequiredFilesList) {
    $RequiredFiles += $RequiredFile.FullName.Substring(
        # relative pathing from the root of the module
        # the length of the path to the root + 1 for the slash
        $BinDirectoryPath.Length + 1
    )
}

# This grabs all of the DLLs in the bin directory that target netstandard2.0 for load at module-import time.
$RequiredAssemblyFileList = $RequiredFilesList | Where-Object -Property FullName -Like '*\lib\netstandard2.0\*' |  Where-Object -Property Extension -eq '.dll' | Select-Object -Property Name, FullName, BaseName
$RequiredAssemblies = @()
foreach ($RequiredAssemblyFile in $RequiredAssemblyFileList) {
    $RequiredAssemblies += "packages\$($RequiredAssemblyFile.BaseName)\lib\netstandard2.0\$($RequiredAssemblyFile.Name)"
}


$NewModuleManifestSplat = @{
    Path = "$BinDirectoryPath\PoshOtel.psd1"
    RequiredAssemblies = $RequiredAssemblies
    RootModule = 'PoshOtel.psm1'
    Author = 'Shayde Nofziger'
    ModuleVersion = $Version
    Description = 'An Open Telemetry Client for use in PowerShell scripts'
    Guid = $MODULE_GUID
    CompanyName = 'PoshOtel'
    ProjectUri = 'https://github.com/ShaydeNofziger/PoshOtel'
    LicenseUri = 'https://github.com/ShaydeNofziger/PoshOtel/blob/main/LICENSE'
    Tags = @('PSEdition_Desktop', 'PSEdition_Core', 'Windows')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    FileList = $RequiredFiles
    CompatiblePSEditions = @('Desktop', 'Core')
    PowerShellVersion = '5.1'
}

Write-Verbose -Message 'Creating module manifest...'
Write-Verbose -Message ($NewModuleManifestSplat | ConvertTo-Json)
New-ModuleManifest @NewModuleManifestSplat

Test-ModuleManifest -Path $NewModuleManifestSplat.Path

# TODO: Pester tests
