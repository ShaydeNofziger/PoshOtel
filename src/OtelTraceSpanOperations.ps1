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

    return [System.Diagnostics.ActivitySource]::new($ServiceName)
}

function New-OtelTraceSpan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $ServiceName,
        [Parameter(Mandatory = $true)]
        [string] $ActivityName,
        [Parameter()]
        [System.Diagnostics.ActivityKind] $ActivityKind = [System.Diagnostics.ActivityKind]::Server,
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

function Stop-OtelTraceSpan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [System.Diagnostics.Activity] $Activity
    )

    if ($Activity) {
        $Activity.Stop()
    }
    else {
        [System.Diagnostics.Activity]::Current.Stop()
    }
}

function Write-OtelTraceSpanEvent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$EventName,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [System.Diagnostics.Activity] $TargetActivity = [System.Diagnostics.Activity]::Current,

        [Parameter(Mandatory = $false)]
        [System.DateTimeOffset]$EventTime = [System.DateTimeOffset]::UtcNow,

        [Parameter(Mandatory = $false)]
        [System.Diagnostics.ActivityTagsCollection] $EventTags = [System.Diagnostics.ActivityTagsCollection]::new()
    )

    if ($null -eq $TargetActivity) {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                [System.ArgumentNullException]::new(
                    'TargetActivity',
                    'No Trace appears to be in progress. If a TargetActivity is not specified, the current Activity is used. Ensure a trace has been started via New-OtelTraceSpan before calling this command.'
                ),
                'NoTraceInProgress',
                [System.Management.Automation.ErrorCategory]::InvalidArgument,
                $null
            )
        )
    }

    $activityEvent = [System.Diagnostics.ActivityEvent]::new($EventName, $EventTime, $EventTags)

    return $TargetActivity.AddEvent($activityEvent)

}

Export-ModuleMember -Function New-OtelTraceSpan, Get-OtelActivitySource, Write-OtelTraceSpanEvent, Stop-OtelTraceSpan
