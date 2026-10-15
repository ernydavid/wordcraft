param(
  [Parameter(Mandatory = $true, ValueFromRemainingArguments = $true)]
  [string[]] $Files
)
$ErrorActionPreference = 'Stop'

if (-not $env:WINDOWS_CERTIFICATE) {
  Write-Warning "WINDOWS_CERTIFICATE is not configured. Skipping signing: $($Files -join ', ')"
  exit 0
}

$SignToolCommand = Get-Command signtool.exe -ErrorAction SilentlyContinue
if ($SignToolCommand) {
  $SignTool = $SignToolCommand.Source
} else {
  $SdkBin = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10\bin'
  $Tool = Get-ChildItem $SdkBin -Filter signtool.exe -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match '\\x64\\signtool\.exe$' } |
    Sort-Object FullName -Descending | Select-Object -First 1
  if (-not $Tool) { throw 'signtool.exe was not found. Install Windows SDK.' }
  $SignTool = $Tool.FullName
}

$TempDir = if ($env:RUNNER_TEMP) { $env:RUNNER_TEMP } else { [IO.Path]::GetTempPath() }
$Pfx = Join-Path $TempDir ("words-sign-" + [Guid]::NewGuid().ToString("N") + ".pfx")
try {
  [IO.File]::WriteAllBytes($Pfx, [Convert]::FromBase64String($env:WINDOWS_CERTIFICATE))
  $Options = @(
    'sign', '/fd', 'SHA256', '/td', 'SHA256',
    '/tr', 'http://timestamp.digicert.com',
    '/f', $Pfx, '/d', 'Words'
  )
  if ($env:WINDOWS_CERTIFICATE_PASSWORD) {
    $Options += @('/p', $env:WINDOWS_CERTIFICATE_PASSWORD)
  }
  foreach ($file in $Files) {
    $Resolved = (Resolve-Path $file).Path
    & $SignTool @Options $Resolved
    if ($LASTEXITCODE -ne 0) { throw "Signing failed for $Resolved (code $LASTEXITCODE)" }
    & $SignTool verify /pa /v $Resolved
    if ($LASTEXITCODE -ne 0) { throw "Signature verification failed for $Resolved" }
    Write-Host "Signed and verified $Resolved"
  }
} finally {
  Remove-Item -Force $Pfx -ErrorAction SilentlyContinue
}
