# build.ps1 – bygger den portabla zip-filen för Antifon-tangenter i dist\.
# Zip-filen innehåller den OFÖRÄNDRADE officiella AutoHotkey64.exe, omdöpt till
# Antifon-tangenter.exe, bredvid skriptet: startad utan argument läser den skriptet
# med samma namn (Antifon-tangenter.ahk). Fungerar i Windows PowerShell 5.1 och 7.
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$root = $PSScriptRoot
$tools = Join-Path $root 'build'
$dist = Join-Path $root 'dist'
New-Item -ItemType Directory -Force $tools | Out-Null

# versionen ur skriptets första rad ("; Antifon-tangenter — v1.2.3")
$header = (Get-Content (Join-Path $root 'Antifon-tangenter.ahk') -TotalCount 3 -Encoding UTF8) -join ' '
$version = if ($header -match 'v(\d+\.\d+\.\d+)') { $Matches[1] } else { '0.0.0' }
Write-Host "Bygger Antifon-tangenter $version"

$base = Join-Path $tools 'base\AutoHotkey64.exe'
if (-not (Test-Path $base)) {
    Write-Host 'Hämtar AutoHotkey v2 …'
    $rels = Invoke-RestMethod 'https://api.github.com/repos/AutoHotkey/AutoHotkey/releases'
    $v2 = $rels | Where-Object { $_.tag_name -like 'v2.0*' } | Select-Object -First 1
    $asset = $v2.assets | Where-Object { $_.name -like 'AutoHotkey_2*.zip' } | Select-Object -First 1
    Invoke-WebRequest $asset.browser_download_url -OutFile (Join-Path $tools 'ahk2.zip')
    Expand-Archive (Join-Path $tools 'ahk2.zip') (Join-Path $tools 'base') -Force
}

$stage = Join-Path $dist 'Antifon-tangenter'
if (Test-Path $stage) { Remove-Item -Recurse -Force $stage }
New-Item -ItemType Directory -Force $stage | Out-Null
Copy-Item $base (Join-Path $stage 'Antifon-tangenter.exe')
Copy-Item (Join-Path $root 'Antifon-tangenter.ahk') $stage
Copy-Item (Join-Path $root 'README.md') (Join-Path $stage 'README.md')
Copy-Item (Join-Path $root 'LICENSE') $stage

$zip = Join-Path $dist "Antifon-tangenter-$version.zip"
if (Test-Path $zip) { Remove-Item $zip }
Compress-Archive -Path $stage -DestinationPath $zip
Write-Host "Klart: $zip"
