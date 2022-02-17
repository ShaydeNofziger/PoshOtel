using namespace Azure.Monitor.OpenTelemetry.Exporter;
using namespace System.Diagnostics
using namespace OpenTelemetry
using namespace OpenTelemetry.Trace
using namespace OpenTelemetry.Resources
using namespace OpenTelemetry.Exporter.Console
using namespace OpenTelemetry.Exporter.OpenTelemetryProtocol

# TODO: Is Global scope necessary to maintain the instance and not let it be disposed?
[System.Collections.Generic.Dictionary[[string],[OpenTelemetry.Trace.TracerProvider]]]$Global:PoshOtelTracerProviders = [System.Collections.Generic.Dictionary[[string],[OpenTelemetry.Trace.TracerProvider]]]::new()

function Initialize-PoshOtel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $ServiceName,
        [Parameter(Mandatory = $true)]
        [string] $ServiceVersion,
        [Parameter(Mandatory = $false)]
        [switch] $AddConsoleExporter,
        [Parameter(Mandatory = $false)]
        [switch] $AddAzureMonitorTraceExporter,
        [Parameter(Mandatory = $false)]
        [switch] $AddGenericOtlpExporter,
        [Parameter(Mandatory = $false)]
        [switch] $Force
    )

    if ($Global:PoshOtelTracerProviders.ContainsKey("${ServiceName}+${ServiceVersion}")) {
        if ($Force) {
            $Global:PoshOtelTracerProviders.Remove("${ServiceName}+${ServiceVersion}")
        }
        else {
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    [System.InvalidOperationException]::new(
                        "Tracer provider already exists for service ${ServiceName}, version ${ServiceVersion}. Use -Force to overwrite."
                    ),
                    'TracerProviderAlreadyExists',
                    [System.Management.Automation.ErrorCategory]::InvalidOperation,
                    $null
                )
            )
        }
    }

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

    if ($AddConsoleExporter) {
        $tracerProviderBuilder = [ConsoleExporterHelperExtensions]::AddConsoleExporter($tracerProviderBuilder)
    }

    if ($AddAzureMonitorTraceExporter) {
        $tracerProviderBuilder = [AzureMonitorExporterHelperExtensions]::AddAzureMonitorTraceExporter($tracerProviderBuilder, [System.Action[Azure.Monitor.OpenTelemetry.Exporter.AzureMonitorExporterOptions]]{
            param($options)
            $options.ConnectionString = $env:OTEL_EXPORTER_AZUREMONITOR_CONNECTIONSTRING
        })
    }

    if ($AddGenericOtlpExporter) {
        $tracerProviderBuilder = [OtlpTraceExporterHelperExtensions]::AddOtlpExporter($tracerProviderBuilder)
    }

    # TODO: Add check to ensure we don't register this more than once. ReadOnly variable??
    $Global:PoshOtelTracerProviders.Add("${ServiceName}+${ServiceVersion}", [TracerProviderBuilderExtensions]::Build($tracerProviderBuilder)) | Out-Null
}

function Remove-PoshOtelTraceExporter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $ServiceName,

        [Parameter(Mandatory = $true)]
        [string] $ServiceVersion
    )

    begin {
        $ProviderDictionaryKey = "${ServiceName}+${ServiceVersion}"
    }

    process {
        $TracerProvider = $null
        if ($Global:PoshOtelTracerProviders.TryGetValue($ProviderDictionaryKey, [ref] $TracerProvider)) {
            Write-Verbose -Message 'Hit It!'
            $TracerProvider.Dispose()
            $Global:PoshOtelTracerProviders.Remove($ProviderDictionaryKey) | Out-Null
        }
        else {
            $PSCmdlet.ThrowTerminatingError("Tracer provider does not exist for service ${ServiceName}, version ${ServiceVersion}")
        }
    }

    end {

    }
}

Export-ModuleMember -Function Initialize-PoshOtel, Remove-PoshOtelTraceExporter
