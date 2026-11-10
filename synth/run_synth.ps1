# synth/run_synth.ps1
# Synthesizes core and core_pipe with Yosys (run inside WSL) and reports area and logic depth.
# Run from the repository root:  .\synth\run_synth.ps1
# Area : generic cells, no technology library. imem and dmem are black boxes.
# Depth: longest chain of cells between flip-flops. imem and dmem are zero-delay wires.

if (-not (Test-Path 'rtl\core.v')) {
Write-Host 'FAIL: run this script from the repository root (rtl\core.v not found).'
exit 1
}

# Register bits in the code: PC 32 + register file 1024 (+ pipeline registers 439)
$HandFF = @{ 'core' = 1056; 'core_pipe' = 1495 }
$Files = 'rtl/alu.v rtl/control.v rtl/core.v rtl/core_pipe.v rtl/fwd_unit.v rtl/hazard_unit.v rtl/immgen.v rtl/load_align.v rtl/pc_reg.v rtl/pipe_reg.v rtl/regfile.v rtl/store_align.v'
$OutDir = 'synth\out'
$Checks = 0
$Errors = 0
New-Item -ItemType Directory -Force $OutDir | Out-Null

function Check([bool]$Ok, [string]$Message) {
$script:Checks++
if (-not $Ok) {
$script:Errors++
Write-Host "FAIL: $Message"
}
}

function Invoke-Yosys([string]$Commands, [string]$LogFile) {
$lines = wsl yosys -p $Commands 2>&1 | ForEach-Object { "$_" }
$code = $LASTEXITCODE
$lines | Set-Content -Encoding ASCII $LogFile
Check ($code -eq 0) "yosys exited with code $code, see $LogFile"
return $lines
}

function Get-Cells([string[]]$Lines) {
$start = 0
for ($i = 0; $i -lt $Lines.Count; $i++) {
if ($Lines[$i] -match '^=== ') { $start = $i }
}
$cells = @{}
$reported = -1
for ($i = $start + 1; $i -lt $Lines.Count; $i++) {
if ($Lines[$i] -match 'Number of cells:\s+(\d+)') { $reported = [int]$Matches[1] }
elseif ($Lines[$i] -match '^\s+(\S+)\s+(\d+)\s*$') { $cells[$Matches[1]] = [int]$Matches[2] }
}
$ff = 0
$meta = 0
$sum = 0
foreach ($k in $cells.Keys) {
$sum += $cells[$k]
if ($k -match '^\$_S?DFF') { $ff += $cells[$k] }
elseif ($k -eq '$scopeinfo' -or $k -eq 'imem' -or $k -eq 'dmem') { $meta += $cells[$k] }
}
return @{ Reported = $reported; Sum = $sum; FF = $ff; Meta = $meta; Logic = $sum - $ff - $meta }
}

$version = (wsl yosys -V 2>&1 | ForEach-Object { "$_" }) -join ''
Check ($version -match '^Yosys') 'Yosys not found in WSL'
if ($Errors -gt 0) { exit 1 }
Write-Host $version

$Area = @{}
foreach ($name in 'core', 'core_pipe') {
$cmd = "read_verilog synth/memstubs.v; read_verilog -I rtl $Files; hierarchy -check -top $name; setattr -set keep 1 c:u_imem c:u_dmem; synth -top $name -flatten -nordff; stat"
$log = @(Invoke-Yosys $cmd "$OutDir\${name}_area.log")
$s = Get-Cells $log
Check ($s.Reported -eq $s.Sum) "$name area: cell types add up to $($s.Sum), tool reports $($s.Reported)"
Check ($s.FF -le $HandFF[$name]) "$name area: $($s.FF) flip-flops, more than the $($HandFF[$name]) register bits in the code"
Check ($s.FF -gt 1000) "$name area: almost nothing left, the design was deleted"
Check ((@($log | Select-String -CaseSensitive 'Latch inferred')).Count -eq 0) "$name area: latch inferred"
Check ((@($log | Select-String 'Found and reported [1-9]')).Count -eq 0) "$name area: the check pass reported problems"
$Area[$name] = $s
Write-Host ("{0,-10} flip-flops {1,5}  logic cells {2,5}  total {3,5}" -f $name, $s.FF, $s.Logic, ($s.Sum - $s.Meta))
}
$Depth = @{}
foreach ($name in 'core', 'core_pipe') {
if ($name -eq 'core') { $keep = 'w:pc w:store_data w:be' } else { $keep = 'w:pc w:mm_wdata w:mm_be' }
$cmd = "read_verilog synth/memwire.v; read_verilog -I rtl $Files; hierarchy -check -top $name; setattr -set keep 1 $keep; synth -top $name -flatten -nordff; ltp -noff"
$log = @(Invoke-Yosys $cmd "$OutDir\${name}_depth.log")
$m = @($log | Select-String 'Longest topological path in \S+ \(length=(\d+)\)')
Check ($m.Count -eq 1) "$name depth: no path length found"
$Depth[$name] = 0
if ($m.Count -eq 1) { $Depth[$name] = [int]$m[0].Matches[0].Groups[1].Value }
Check ($Depth[$name] -gt 10) "$name depth: path of only $($Depth[$name]) cells, the design was deleted"
}
Check ($Depth['core_pipe'] -lt $Depth['core']) 'the pipeline path is not shorter than the single-cycle path'

$ratio = $Depth['core_pipe'] / $Depth['core']
$out = @(
"Yosys version : $version",
'Flow          : synth -flatten -nordff, generic cells, no technology library',
'Memories      : imem and dmem are black boxes (area) and zero-delay wires (depth); their area and access time are NOT included',
'Cell counts   : exclude the $scopeinfo bookkeeping cells and the two black-box cells',
'Depth         : longest chain of cells between flip-flops (Yosys ltp -noff); not a clock period',
'',
('{0,-10} {1,11} {2,12} {3,7} {4,20}' -f 'design', 'flip-flops', 'logic cells', 'total', 'logic depth (cells)'),
('{0,-10} {1,11} {2,12} {3,7} {4,20}' -f 'core', $Area['core'].FF, $Area['core'].Logic, ($Area['core'].Sum - $Area['core'].Meta), $Depth['core']),
('{0,-10} {1,11} {2,12} {3,7} {4,20}' -f 'core_pipe', $Area['core_pipe'].FF, $Area['core_pipe'].Logic, ($Area['core_pipe'].Sum - $Area['core_pipe'].Meta), $Depth['core_pipe']),
'',
('Depth ratio core_pipe / core = {0:N2}' -f $ratio),
'Break-even from the C-program cycle counts (595 / 863): the pipeline wins only if its clock period is below 0.69 times the single-cycle clock period.',
'The depth ratio is not a period ratio. See the README for the limits.'
)

if ($Errors -eq 0) {
$out | Set-Content -Encoding ASCII 'synth\results.txt'
$out | ForEach-Object { Write-Host $_ }
Write-Host "PASS: SYNTH, $Checks checks, 0 errors"
exit 0
}
Write-Host "FAIL: SYNTH, $Checks checks, $Errors errors"
exit 1
