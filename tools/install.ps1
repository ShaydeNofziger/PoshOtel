$SrcDir = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath 'src'
$BinDir = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath 'bin'

# Get nuget.exe
if (-not (Test-Path -Path $PSScriptRoot\nuget.exe)) { Invoke-WebRequest -Uri 'https://dist.nuget.org/win-x86-commandline/latest/nuget.exe' -OutFile "$PSScriptRoot\nuget.exe" }

Write-Verbose -Message 'Installing packages...'
. $PSScriptRoot\nuget.exe install $SrcDir\packages.config -OutputDirectory $BinDir\packages -ExcludeVersion
