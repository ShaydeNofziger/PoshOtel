[CmdletBinding()]
param(
    [string]$Version = '0.0.1'
)

if (Test-Path "$PSScriptRoot\secrets.ps1") {
    Write-Verbose 'secrets.ps1 file found. Loading secrets...'
    . $PSScriptRoot\secrets.ps1
}

Write-Verbose -Message 'Installing required dependencies...'
. $PSScriptRoot\tools\install.ps1

Copy-Item -Path "$PSScriptRoot\src\*.ps1", "$PSScriptRoot\src\*.psm1" -Destination "$PSScriptRoot\bin" -Force -Verbose

New-ModuleManifest -Path $PSScriptRoot\bin\PoshOtel.psd1 -RequiredAssemblies(
    # TODO: How to support multiple versions of the same assembly for consumers?
    'Google.Protobuf.3.15.5\lib\netstandard2.0\Google.Protobuf.dll',
    'Grpc.Core.2.43.0\lib\netstandard2.0\Grpc.Core.dll',
    'Grpc.Core.Api.2.43.0\lib\netstandard2.0\Grpc.Core.Api.dll',
    'OpenTelemetry.1.2.0-rc2\lib\netstandard2.0\OpenTelemetry.dll',
    'OpenTelemetry.Api.1.2.0-rc2\lib\netstandard2.0\OpenTelemetry.Api.dll',
    'OpenTelemetry.Exporter.Console.1.2.0-rc2\lib\netstandard2.0\OpenTelemetry.Exporter.Console.dll',
    'OpenTelemetry.Exporter.OpenTelemetryProtocol.1.2.0-rc2\lib\netstandard2.0\OpenTelemetry.Exporter.OpenTelemetryProtocol.dll'
) -RootModule 'PoshOtel.psm1' -Author 'Shayde Nofziger' -ModuleVersion $Version -Description 'An Open Telemetry Client for use in PowerShell scripts' -Guid ([Guid]::new('2CA13CCF-8751-4D25-9CBF-998727787367')) -CompanyName 'PoshOtel' -Verbose

# TODO: Pester tests
