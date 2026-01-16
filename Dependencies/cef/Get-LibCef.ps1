param(
  [Parameter(Mandatory=$true)][string]$Owner,
  [Parameter(Mandatory=$true)][string]$Repo,
  [Parameter(Mandatory=$true)][string]$Tag,
  [Parameter(Mandatory=$true)][string]$AssetName,
  [Parameter(Mandatory=$true)][string]$ExpectedSha256,
  [Parameter(Mandatory=$true)][string]$OutPath,
  [string]$Token = ""
)

$ErrorActionPreference = "Stop"

$headers = @{}
if ($Token -and $Token.Trim().Length -gt 0) {
  $headers["Authorization"] = "token $Token"
}

# GitHub release asset direct download URL
$assetUrl = "https://github.com/$Owner/$Repo/releases/download/$Tag/$AssetName"

$tmp = "$OutPath.download"
if (Test-Path $tmp) { Remove-Item -Force $tmp }

Write-Host "Downloading $AssetName from $assetUrl ..."
Invoke-WebRequest -Uri $assetUrl -OutFile $tmp -Headers $headers -UseBasicParsing

$hash = (Get-FileHash $tmp -Algorithm SHA256).Hash.ToUpperInvariant()
if ($hash -ne $ExpectedSha256.ToUpperInvariant()) {
  Remove-Item -Force $tmp
  throw "SHA256 mismatch for $AssetName. Expected $ExpectedSha256 but got $hash"
}

$dir = Split-Path -Parent $OutPath
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }

Move-Item -Force $tmp $OutPath
Write-Host "OK: Installed $AssetName -> $OutPath"