$ProjectDirectory = Split-Path -Path $PSScriptRoot -Parent
$PathToModule = Join-Path -Path $ProjectDirectory -ChildPath 'src\Poshotel.psm1'

. "$PSScriptRoot\secrets.ps1"

Remove-Module 'PoshOtel' -ErrorAction Ignore
Import-Module $PathToModule

if ($null -eq $Global:TestConsumerInitialized) {
    $Global:TestConsumerInitialized = $false
}
if (-not ($Global:TestConsumerInitialized)) {
    Initialize-PoshOtel -ServiceName 'TestConsumer' -ServiceVersion '0.0.1'
    $Global:TestConsumerInitialized = $true
}

function Invoke-TracedCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OperationName,
        [Parameter(Mandatory = $true)]
        [string]$OperationDescription,
        [Parameter(Mandatory = $true)]
        [scriptblock]$CommandToInvoke,
        [Parameter(Mandatory = $false)]
        [array]$Arguments = @()
    )

    $traceOperation = New-OtelTraceSpan -ServiceName 'TestConsumer' -ActivityName $OperationName -RootSpan
    $null = $traceOperation.SetTag('user', $env:USERNAME)
    $null = $traceOperation.SetTag('operation-description', $OperationDescription)

    try {
        $CommandToInvoke.Invoke($Arguments)
    }
    catch {
        $null = $traceOperation.SetTag('error', $_.Exception.Message)
        $null = $traceOperation.Stop()
        throw
    }

    $null = $traceOperation.Stop()
    $traceOperation.Dispose()
}

Invoke-TracedCommand -OperationName 'Outer Command' -OperationDescription 'Outer Command Host' -CommandToInvoke {
    param($Path)
    Invoke-TracedCommand -OperationName 'Get-ChildItem => test directory' -OperationDescription 'Inner Command' -CommandToInvoke {
        param($InnerPath)
        Get-ChildItem -Path $InnerPath
    } -Arguments $Path
    Invoke-TracedCommand -OperationName 'Get-ChildItem => src directory' -OperationDescription 'Inner Command' -CommandToInvoke {
        param($InnerPath)
        Get-ChildItem -Path "$InnerPath\..\src"
    } -Arguments $Path
} -Arguments @($PSScriptRoot)
