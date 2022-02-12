using namespace System.Diagnostics
using namespace OpenTelemetry
using namespace OpenTelemetry.Trace
using namespace OpenTelemetry.Resources
using namespace OpenTelemetry.Exporter.Console
using namespace OpenTelemetry.Exporter.OpenTelemetryProtocol

function Get-OtelActivitySource {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string] $ServiceName
    )

    return [ActivitySource]::new($ServiceName)
}

function New-OtelTraceSpan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $ServiceName,
        [Parameter(Mandatory = $true)]
        [string] $ActivityName,
        [Parameter()]
        [ActivityKind] $ActivityKind = [ActivityKind]::Server,
        [Parameter()]
        [switch]$RootSpan
    )

    $activitySource = Get-OtelActivitySource -ServiceName $ServiceName
    $activity = $activitySource.StartActivity($ActivityName, $ActivityKind)

    if ($RootSpan) {
        $null = $activity.SetTag('trace.parent_id', $null)
    }

    return $activity
}

Export-ModuleMember -Function @(
    'Get-OtelActivitySource',
    'New-OtelTraceSpan'
)
