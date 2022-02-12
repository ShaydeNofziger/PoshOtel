# PoshOtel
An Open Telemetry Client for use in PowerShell scripts

## Environment Variables

```powershell
    $env:OTEL_EXPORTER_OTLP_ENDPOINT = 'https://api.honeycomb.io:443'
    $env:OTEL_EXPORTER_OTLP_HEADERS = 'x-honeycomb-team=<<API_KEY>>,x-honeycomb-dataset=<<DATASET>>'
    $env:OTEL_EXPORTER_OTLP_TIMEOUT = '600000'
    $env:OTEL_EXPORTER_OTLP_PROTOCOL = 'grpc'
```

