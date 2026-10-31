param([string]$InFile, [string]$OutFile)
$bytes = [System.IO.File]::ReadAllBytes((Resolve-Path $InFile).Path)
if ($bytes.Length % 4 -ne 0) { Write-Error "size is not a multiple of 4"; exit 1 }
$lines = @()
for ($i = 0; $i -lt $bytes.Length; $i += 4) { $lines += [BitConverter]::ToUInt32($bytes, $i).ToString("x8") }
Set-Content -Path $OutFile -Value $lines -Encoding ASCII
