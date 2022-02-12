# Configuring

TestConsumer.ps1 assumes a secrets.ps1 file in the same directory as the script.
Use this to set environment variables / secrets for the otlp configuration

Template:

```powershell
$env:OTEL_EXPORTER_OTLP_ENDPOINT = 'https://api.honeycomb.io:443'
$env:OTEL_EXPORTER_OTLP_HEADERS = 'x-honeycomb-team=<<API-KEY>>,x-honeycomb-dataset=<<DATASET>>'
$env:OTEL_EXPORTER_OTLP_TIMEOUT = '600000'
$env:OTEL_EXPORTER_OTLP_PROTOCOL = 'grpc'
```
