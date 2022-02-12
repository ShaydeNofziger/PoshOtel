using namespace System.Diagnostics
using namespace OpenTelemetry
using namespace OpenTelemetry.Trace
using namespace OpenTelemetry.Resources
using namespace OpenTelemetry.Exporter.Console
using namespace OpenTelemetry.Exporter.OpenTelemetryProtocol

# TODO: Is Global scope necessary to maintain the instance and not let it be disposed?
$Global:PoshOtelTracerProvider = $null

$ProjectRoot = Split-Path -Path $PSScriptRoot -Parent
$BinDirectory = Join-Path -Path $ProjectRoot -ChildPath 'bin'

function InternalInitializeOtlpTracerProvider {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $ServiceName,
        [Parameter(Mandatory = $true)]
        [string] $ServiceVersion
    )

    <#
            internal const string EndpointEnvVarName = "OTEL_EXPORTER_OTLP_ENDPOINT";
            internal const string HeadersEnvVarName = "OTEL_EXPORTER_OTLP_HEADERS";
            internal const string TimeoutEnvVarName = "OTEL_EXPORTER_OTLP_TIMEOUT";
            internal const string ProtocolEnvVarName = "OTEL_EXPORTER_OTLP_PROTOCOL";
    #>

    $resourceBuilder = [OpenTelemetry.Resources.ResourceBuilder]::CreateDefault()
    $resourceBuilder = [ResourceBuilderExtensions]::AddService($resourceBuilder, $ServiceName, $ServiceVersion)
    $tracerProviderBuilder = [OpenTelemetry.Sdk]::CreateTracerProviderBuilder().AddSource($ServiceName)
    $tracerProviderBuilder = [TracerProviderBuilderExtensions]::SetResourceBuilder($tracerProviderBuilder, $resourceBuilder)
    # uncomment this line to enable the console exporter
    # TODO: Add a parameter to enable/disable the console exporter -- DebugPreference??
    # $tracerProviderBuilder = [ConsoleExporterHelperExtensions]::AddConsoleExporter($tracerProviderBuilder)

    $tracerProviderBuilder = [OtlpTraceExporterHelperExtensions]::AddOtlpExporter($tracerProviderBuilder)

    # TODO: Add check to ensure we don't register this more than once. ReadOnly variable??
    $Global:PoshOtelTracerProvider = [TracerProviderBuilderExtensions]::Build($tracerProviderBuilder)
}

function InternalRegisterTypes {
    [CmdletBinding()]
    param()

    # TODO: Make versioning easier
    # Note: These are in a specific order to ensure inner dependencies are loaded before their consuming dependencies.
    [string[]]$TypesToAdd = @(
        "$BinDirectory\OpenTelemetry.Api.1.2.0-rc2\lib\netstandard2.0\OpenTelemetry.Api.dll",
        "$BinDirectory\OpenTelemetry.1.2.0-rc2\lib\netstandard2.0\OpenTelemetry.dll",
        "$BinDirectory\Google.Protobuf.3.15.5\lib\netstandard2.0\Google.Protobuf.dll",
        "$BinDirectory\Grpc.Core.Api.2.43.0\lib\netstandard2.0\Grpc.Core.Api.dll",
        "$BinDirectory\Grpc.Core.2.43.0\lib\netstandard2.0\Grpc.Core.dll",
        "$BinDirectory\OpenTelemetry.Exporter.Console.1.2.0-rc2\lib\netstandard2.0\OpenTelemetry.Exporter.Console.dll",
        "$BinDirectory\OpenTelemetry.Exporter.OpenTelemetryProtocol.1.2.0-rc2\lib\netstandard2.0\OpenTelemetry.Exporter.OpenTelemetryProtocol.dll"
    )

    foreach ($PathToType in $TypesToAdd) {
        Add-Type -Path $PathToType
    }
}

function Initialize-PoshOtel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $ServiceName,
        [Parameter(Mandatory = $true)]
        [string] $ServiceVersion
    )

    InternalInitializeOtlpTracerProvider -ServiceName $ServiceName -ServiceVersion $ServiceVersion
}

InternalRegisterTypes

Export-ModuleMember -Function @(
    'Initialize-PoshOtel'
)
