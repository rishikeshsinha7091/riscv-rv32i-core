Set-Location (Join-Path $PSScriptRoot "..")
$tests = @(Get-ChildItem tb\tb_*.v | ForEach-Object { $_.BaseName -replace '^tb_', '' })
Write-Host "found $($tests.Count) testbenches: $tests"
$failedNames = @()
foreach ($t in $tests) {
Remove-Item "sim\tb_${t}.vvp" -ErrorAction SilentlyContinue
$out = @(.\sim\run.cmd $t)
$code = $LASTEXITCODE
$passLines = @($out -match '^PASS: ')
$failLines = @($out -match '^FAIL: ')
$detail = "no count in the PASS line"
$ok = ($code -eq 0) -and ($passLines.Count -eq 1) -and ($failLines.Count -eq 0)
if ($ok -and ($passLines[0] -match '(\d+) (checks|cases)')) {
$detail = $matches[0]
if ([int]$matches[1] -eq 0) { $ok = $false; $detail = "0 checks" }
}
if ($ok) {
Write-Host ("PASS  {0,-16} {1}" -f $t, $detail) -ForegroundColor Green
} else {
$failedNames += $t
Write-Host ("FAIL  {0,-16} exit code {1}, {2} PASS line(s), {3} FAIL line(s)" -f $t, $code, $passLines.Count, $failLines.Count) -ForegroundColor Red
$failLines | Select-Object -First 3 | ForEach-Object { Write-Host "      $_" }
}
}
$total = $tests.Count
$passed = $total - $failedNames.Count
Write-Host "$passed of $total tests passed"
if ($failedNames.Count -gt 0) { Write-Host "FAILED: $failedNames" -ForegroundColor Red; exit 1 }
exit 0
