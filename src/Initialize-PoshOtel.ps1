using namespace System.Diagnostics
using namespace OpenTelemetry
using namespace OpenTelemetry.Trace
using namespace OpenTelemetry.Resources
using namespace OpenTelemetry.Exporter.Console
using namespace OpenTelemetry.Exporter.OpenTelemetryProtocol

# TODO: Is Global scope necessary to maintain the instance and not let it be disposed?
$Global:PoshOtelTracerProvider = $null

function InternalInitializeOtlpTracerProvider {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $ServiceName,
        [Parameter(Mandatory = $true)]
        [string] $ServiceVersion
    )

    <#
        Per the OTLP .NET documentation, these values can be configured via environment variables.
            EndpointEnvVarName = "OTEL_EXPORTER_OTLP_ENDPOINT"
            HeadersEnvVarName = "OTEL_EXPORTER_OTLP_HEADERS"
            TimeoutEnvVarName = "OTEL_EXPORTER_OTLP_TIMEOUT"
            ProtocolEnvVarName = "OTEL_EXPORTER_OTLP_PROTOCOL"
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

Export-ModuleMember -Function Initialize-PoshOtel
