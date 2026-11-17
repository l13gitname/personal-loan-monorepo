# One command to verify the Flutter app locally (Windows PowerShell).
# Usage (from repo root):  ./scripts/check-flutter.ps1
$ErrorActionPreference = 'Stop'

Set-Location (Join-Path $PSScriptRoot '..\apps\consumer_app')

function Step($name, [scriptblock]$cmd) {
  Write-Host "`n=== $name ===" -ForegroundColor Cyan
  & $cmd
  if ($LASTEXITCODE -ne 0) { throw "$name failed (exit $LASTEXITCODE)" }
}

Step 'flutter --version' { flutter --version }
Step 'pub get'           { flutter pub get }
Step 'build_runner'      { dart run build_runner build --delete-conflicting-outputs }
Step 'format check'      { dart format --output=none --set-exit-if-changed lib test integration_test }
Step 'analyze'           { flutter analyze }
Step 'unit + widget tests' { flutter test }

Write-Host "`nAll checks passed." -ForegroundColor Green
