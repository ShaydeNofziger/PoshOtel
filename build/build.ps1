[CmdletBinding()]
param(
    [string]$Version = '0.0.1'
)

$ErrorActionPreference = 'Stop'

$ProjectRootPath = Split-Path -Path $PSScriptRoot -Parent
$BuildDirectoryPath = Join-Path -Path $ProjectRootPath -ChildPath 'build'
$SrcDirectoryPath = Join-Path -Path $ProjectRootPath -ChildPath 'src'
$BinDirectoryPath = Join-Path -Path $ProjectRootPath -ChildPath 'bin'

$MODULE_GUID = [Guid]::new('2CA13CCF-8751-4D25-9CBF-998727787367')

if (Test-Path "$BuildDirectoryPath\secrets.ps1") {
    Write-Verbose 'secrets.ps1 file found. Loading secrets...'
    . $BuildDirectoryPath\secrets.ps1
}

Remove-Item -Path $BinDirectoryPath -Recurse -Force

Write-Verbose -Message 'Installing required dependencies...'
. $ProjectRootPath\tools\install.ps1

Write-Verbose -Message 'Copying src files to bin directory...'
Copy-Item -Path "$SrcDirectoryPath\*.ps1", "$SrcDirectoryPath\*.psm1" -Destination $BinDirectoryPath -Force

$RequiredFilesList = Get-ChildItem -Path $BinDirectoryPath -Recurse -File

$RequiredFiles = @()
$relativePathSubstringIndex = $BinDirectoryPath.Length + 1 # the length of the path + 1 for the slash
foreach($RequiredFile in $RequiredFilesList) {
    $RequiredFiles += $RequiredFile.FullName.Substring($relativePathSubstringIndex)
}

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
    Tags = @('PSEdition_Desktop')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    FileList = $RequiredFiles
    PowerShellVersion = '5.1'
    CompatiblePSEditions = @('Desktop')
}

Write-Verbose -Message 'Creating module manifest...'
Write-Verbose -Message ($NewModuleManifestSplat | ConvertTo-Json)
New-ModuleManifest @NewModuleManifestSplat

Test-ModuleManifest -Path $NewModuleManifestSplat.Path

# TODO: Pester tests
