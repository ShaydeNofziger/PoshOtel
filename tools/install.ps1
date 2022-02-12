# Get nuget.exe
if (-not (Test-Path -Path $PSScriptRoot\nuget.exe)) { Invoke-WebRequest -Uri 'https://dist.nuget.org/win-x86-commandline/latest/nuget.exe' -OutFile "$PSScriptRoot\nuget.exe" }
. $PSScriptRoot\nuget.exe install $PSScriptRoot\packages.config -OutputDirectory $PSScriptRoot\..\bin

