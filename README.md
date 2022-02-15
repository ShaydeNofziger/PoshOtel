# PoshOtel

An Open Telemetry Client for use in PowerShell scripts

This is very experimental. Feel free to contribute via documentation, issues, tests, or PRs.

Currently, this will output synchronous events to an OTLP endpoint configured as below. NOTE: I have only tested with this Honeycomb so far.

`test/TestConsumer.ps1` is a script that has proof-of-concept examples while functionality is being built.

Here's a very basic trace in Honeycomb:
![image](https://user-images.githubusercontent.com/2453236/153727442-77d02af4-8d79-47b4-8488-b19af90dd1b1.png)


## Usage

```powershell
# Install dependencies and build the module, creating the manifest definition file
./build/build.ps1

Import-Module .\bin\PoshOtel.psd1

# These need to be set prior to calling the Initialize cmdlet

    # For export to a generic OTLP endpoint
    $env:OTEL_EXPORTER_OTLP_ENDPOINT = 'https://api.honeycomb.io:443'
    $env:OTEL_EXPORTER_OTLP_HEADERS = 'x-honeycomb-team=<<API_KEY>>,x-honeycomb-dataset=<<DATASET>>'
    $env:OTEL_EXPORTER_OTLP_TIMEOUT = '600000'
    $env:OTEL_EXPORTER_OTLP_PROTOCOL = 'grpc'

    # For export to an Azure Monitor / Application Insights endpoint
    $env:OTEL_EXPORTER_AZUREMONITOR_CONNECTIONSTRING = '<<CONNECTION_STRING>>'
    

Initialize-PoshOtel -ServiceName 'TestConsumer' -ServiceVersion '0.0.1'

$traceOperation = New-OtelTraceSpan -ServiceName 'TestConsumer' -ActivityName 'hello-world' -RootSpan
$null = $traceOperation.SetTag('user', $env:USERNAME)
$null = $traceOperation.SetTag('operation-description', 'Hello, World!')

Start-Sleep -Seconds 1

$null = $traceOperation.Stop()
$traceOperation.Dispose()

```

## Troubleshooting

### OpenTelemetry Diagnostics

OTEL Diagnostics logging can be enabled to help troubleshoot issues related to traces not making it to their destination.

Enable it by creating a file named `OTEL_DIAGNOSTICS.json` at the root of this repository with the following contents:

```json
{
    "LogDirectory": ".",
    "FileSize": 1024,
    "LogLevel": "Error"
}
```

Create a new powershell session and import the module from the location of the OTEL_DIAGNOSTICS.json file. This will generate a log file at the path indicated by `LogDirectory`.
