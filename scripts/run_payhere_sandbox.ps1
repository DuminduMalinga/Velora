param([string]$DeviceId = '')

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $projectRoot 'config/payhere.local.json'
if (-not (Test-Path -LiteralPath $configPath)) {
    throw 'Copy config/payhere.example.json to config/payhere.local.json and configure your Sandbox secret first.'
}

# Gradle's generated Windows wrapper echoes encoded Dart defines when DEBUG is set.
$previousDebug = $env:DEBUG
Push-Location $projectRoot
try {
    $env:DEBUG = ''
    $flutterArgs = @('run', '--dart-define-from-file=config/payhere.local.json')
    if ($DeviceId) { $flutterArgs += @('-d', $DeviceId) }
    & flutter @flutterArgs
    $flutterExitCode = $LASTEXITCODE
} finally {
    $env:DEBUG = $previousDebug
    Pop-Location
}
exit $flutterExitCode
