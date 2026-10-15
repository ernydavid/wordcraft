param([ValidateSet('x64')][string]$Arch='x64')
$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$Dist = Join-Path $Root 'dist\release'
New-Item -ItemType Directory -Force -Path $Dist | Out-Null
$VersionText = Get-Content -Raw (Join-Path $Root 'Cargo.toml')
$Pkg = ($VersionText -split '\[workspace.package\]')[1] -split '\[' | Select-Object -First 1
if ($Pkg -notmatch '(?m)^version\s*=\s*"([^"]+)"') { throw 'Cannot find version' }
$Version = $Matches[1]
$MsiVersion = ($Version -split '-')[0]
$Target = 'x86_64-pc-windows-msvc'
$TargetDir = if ($env:CARGO_TARGET_DIR) { $env:CARGO_TARGET_DIR } else { Join-Path $Root 'target' }
$Stage = Join-Path $TargetDir 'words-stage\x64'
New-Item -ItemType Directory -Force -Path $Stage | Out-Null
$env:WORDCRAFT_REQUIRE_WINRES = '1'
& cargo build --release --locked -p wordcraft --target $Target
if ($LASTEXITCODE -ne 0) { throw 'Windows Rust build failed' }
$Exe = Join-Path $Stage 'Words.exe'
Copy-Item (Join-Path $TargetDir "$Target\release\wordcraft.exe") $Exe -Force
foreach ($file in @('LICENSE-MIT','LICENSE-APACHE','NOTICE','ATTRIBUTION.md')) {
  Copy-Item (Join-Path $Root $file) $Stage -Force
}
if ($env:WINDOWS_CERTIFICATE) {
  $Pfx = Join-Path $env:RUNNER_TEMP 'words-signing.pfx'
  try {
    [IO.File]::WriteAllBytes($Pfx,[Convert]::FromBase64String($env:WINDOWS_CERTIFICATE))
    $signTool = Get-Command signtool.exe -ErrorAction SilentlyContinue
    if (-not $signTool) {
      $signTool = Get-ChildItem "${env:ProgramFiles(x86)}\Windows Kits\10\bin" -Filter signtool.exe -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -match '\\x64\\signtool\.exe$' } | Sort-Object FullName -Descending | Select-Object -First 1
    }
    if (-not $signTool) { throw 'Windows SDK signtool.exe not found' }
    $sign = @('sign','/fd','SHA256','/td','SHA256','/tr','http://timestamp.digicert.com','/f',$Pfx,'/d','Words')
    if ($env:WINDOWS_CERTIFICATE_PASSWORD) { $sign += @('/p',$env:WINDOWS_CERTIFICATE_PASSWORD) }
    & $signTool.Source @sign $Exe
    if ($LASTEXITCODE -ne 0) { throw 'Signing failed' }
  } finally { Remove-Item $Pfx -Force -ErrorAction SilentlyContinue }
} else { Write-Warning 'Unsigned Windows beta: use a code-signing certificate before public release' }
$Msi = Join-Path $Dist "Words-$Version-Windows-$Arch.msi"
& wix build (Join-Path $PSScriptRoot 'words.wxs') -arch x64 `
  -d "Version=$MsiVersion" -d "BinDir=$Stage" `
  -d "IconPath=$(Join-Path $Root 'branding\words\generated\words.ico')" -o $Msi
if ($LASTEXITCODE -ne 0) { throw 'WiX MSI packaging failed' }
$PortableZip = Join-Path $Dist "Words-$Version-Windows-$Arch-portable.zip"
if (Test-Path $PortableZip) { Remove-Item $PortableZip -Force }
Compress-Archive -Path (Join-Path $Stage '*') -DestinationPath $PortableZip
Write-Host "Created $Msi and $PortableZip"
