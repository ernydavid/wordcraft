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
& (Join-Path $PSScriptRoot 'sign.ps1') $Exe
$Msi = Join-Path $Dist "Words-$Version-Windows-$Arch.msi"
& wix build (Join-Path $PSScriptRoot 'words.wxs') -arch x64 `
  -d "Version=$MsiVersion" -d "BinDir=$Stage" `
  -d "IconPath=$(Join-Path $Root 'branding\words\generated\words.ico')" `
  -d "DocumentIconDir=$(Join-Path $Root 'branding\words\generated\documents')" -o $Msi
if ($LASTEXITCODE -ne 0) { throw 'WiX MSI packaging failed' }
& (Join-Path $PSScriptRoot 'sign.ps1') $Msi
$PortableZip = Join-Path $Dist "Words-$Version-Windows-$Arch-portable.zip"
if (Test-Path $PortableZip) { Remove-Item $PortableZip -Force }
Compress-Archive -Path (Join-Path $Stage '*') -DestinationPath $PortableZip
Write-Host "Created $Msi and $PortableZip"
