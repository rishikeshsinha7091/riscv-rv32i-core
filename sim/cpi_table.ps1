# cpi_table.ps1: runs tb_pipe_vs_single and prints the CPI table as Markdown.
# It refuses to print if the testbench did not pass or if a row breaks pipe = N + 3 + S + 2R.
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")
$out = & .\sim\run.cmd pipe_vs_single
if (-not ($out | Select-String -SimpleMatch "PASS: pipe_vs_single")) {
Write-Host "FAIL: pipe_vs_single did not print PASS, so no table"
exit 1
}
$rows = [ordered]@{}
foreach ($line in $out) {
if ($line -match '^INFO: (\S+) N=(\d+) cycles single=(\d+) pipe=(\d+) stalls=(\d+) redirects=(\d+)\s*$') {
$rows[$Matches[1]] = [pscustomobject]@{
N = [int]$Matches[2]
Single = [int]$Matches[3]
Pipe = [int]$Matches[4]
S = [int]$Matches[5]
R = [int]$Matches[6]
}
}
}
$groups = [ordered]@{
"Compiled C programs (built with -O1)" = @("c_first", "c_fib", "c_sort", "c_bits")
"Assembly programs" = @("checksum", "alu_ops", "mem_ops", "branch_ops", "jal_ops", "loop_sum", "alu_full", "upper_jalr", "branch_all", "byte_ops", "unsupported")
"Hazard programs (written to stress the hazard logic)" = @("hazard_alu", "bypass_d3", "load_use", "flush_ctl")
}
foreach ($g in $groups.Keys) {
foreach ($n in $groups[$g]) {
if (-not $rows.Contains($n)) {
Write-Host "FAIL: no INFO line for $n"
exit 1
}
}
}
$bad = 0
foreach ($name in $rows.Keys) {
$r = $rows[$name]
$want = $r.N + 3 + $r.S + 2 * $r.R
if ($r.Pipe -ne $want) {
Write-Host "FAIL: $name pipe=$($r.Pipe) but N + 3 + S + 2R = $want"
$bad = $bad + 1
}
}
if ($bad -gt 0) {
exit 1
}
$culture = [System.Globalization.CultureInfo]::InvariantCulture
foreach ($g in $groups.Keys) {
Write-Output "### $g"
Write-Output ""
Write-Output "| Program | N | Single-cycle cycles | Pipeline cycles | CPI single | CPI pipeline | Pipeline extra cycles over N (fill + stalls + flushes) |"
Write-Output "|---|---|---|---|---|---|---|"
$sumN = 0
$sumSingle = 0
$sumPipe = 0
$sumStalls = 0
$sumJumps = 0
foreach ($name in $groups[$g]) {
$r = $rows[$name]
$cs = ($r.Single / $r.N).ToString("F3", $culture)
$cp = ($r.Pipe / $r.N).ToString("F3", $culture)
Write-Output "| $name | $($r.N) | $($r.Single) | $($r.Pipe) | $cs | $cp | 3 + $($r.S) + $(2 * $r.R) |"
$sumN = $sumN + $r.N
$sumSingle = $sumSingle + $r.Single
$sumPipe = $sumPipe + $r.Pipe
$sumStalls = $sumStalls + $r.S
$sumJumps = $sumJumps + $r.R
}
$count = $groups[$g].Count
$ts = ($sumSingle / $sumN).ToString("F3", $culture)
$tp = ($sumPipe / $sumN).ToString("F3", $culture)
Write-Output "| Total | $sumN | $sumSingle | $sumPipe | $ts | $tp | $(3 * $count) + $sumStalls + $(2 * $sumJumps) |"
Write-Output ""
}
exit 0