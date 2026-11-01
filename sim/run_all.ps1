# Runs every testbench in tb\ and, if the RISC-V toolchain is installed, checks the C programs in sw\.
# Usage: .\sim\run_all.ps1           (exit code 0 = everything passed, 1 = something failed)
#        .\sim\run_all.ps1 -Strict   (a missing toolchain counts as a failure)
param([switch]$Strict)
Set-Location (Join-Path $PSScriptRoot "..")
$tests = @(Get-ChildItem tb\tb_*.v | ForEach-Object { $_.BaseName -replace '^tb_', '' })
Write-Host "found $($tests.Count) testbenches: $tests"
$failedNames = @()
$cCount = 0
# the 37 instructions, plus the short names that objdump prints for some of them (mv = addi, ret = jalr, ...)
$allowed = ("lui auipc jal jalr beq bne blt bge bltu bgeu lb lh lw lbu lhu sb sh sw " +
"addi slti sltiu xori ori andi slli srli srai add sub sll slt sltu xor srl sra or and " +
"nop mv not neg seqz snez sltz sgtz beqz bnez blez bgez bltz bgtz bgt ble bgtu bleu j jr ret li zext.b").Split(" ")
$programs = @(Get-ChildItem sw\*.c | ForEach-Object { $_.BaseName })
if (-not (Get-Command riscv-none-elf-gcc -ErrorAction SilentlyContinue)) {
if ($Strict) {
$cCount = 1
$failedNames += "c-programs"
Write-Host "FAIL  c programs       riscv-none-elf-gcc not found (-Strict)" -ForegroundColor Red
} else {
Write-Host "SKIP  c programs       riscv-none-elf-gcc not found, so the hex files in sw were NOT checked against their C sources" -ForegroundColor Yellow
}
} else {
foreach ($p in $programs) {
$cCount = $cCount + 1
$problems = @()
$files = @("sw\${p}.hex", "sw\${p}.data.hex")
$before = @{}
foreach ($f in $files) { $before[$f] = "missing"; if (Test-Path $f) { $before[$f] = (Get-FileHash $f -Algorithm SHA256).Hash } }
.\sw\build.ps1 $p
if ($LASTEXITCODE -ne 0) {
$problems += "build failed (see the message above)"
} else {
foreach ($f in $files) {
$after = "missing"
if (Test-Path $f) { $after = (Get-FileHash $f -Algorithm SHA256).Hash }
if ($after -ne $before[$f]) { $problems += "$f is out of date: a fresh build differs from it" }
}
}
$count = 0
if (Test-Path "sw\${p}.elf") {
foreach ($line in @(riscv-none-elf-objdump -d "sw\${p}.elf")) {
if ($line -match '^\s+[0-9a-f]+:\s+([0-9a-f]+)\s+(\S+)') {
$count = $count + 1
if ($matches[1].Length -ne 8) { $problems += "not a 32-bit instruction: $line" } elseif ($allowed -notcontains $matches[2]) { $problems += "instruction not supported: $($matches[2])" }
}
}
if ($count -eq 0) { $problems += "no instructions found in the disassembly" }
}
if ($problems.Count -eq 0) {
Write-Host ("PASS  {0,-16} {1} instructions, all supported, hex up to date" -f "c:$p", $count) -ForegroundColor Green
} else {
$failedNames += "c:$p"
Write-Host ("FAIL  {0,-16} {1} problem(s)" -f "c:$p", $problems.Count) -ForegroundColor Red
$problems | Select-Object -First 3 | ForEach-Object { Write-Host "      $_" }
}
}
}
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
$total = $tests.Count + $cCount
$passed = $total - $failedNames.Count
Write-Host "$passed of $total tests passed"
if ($failedNames.Count -gt 0) { Write-Host "FAILED: $failedNames" -ForegroundColor Red; exit 1 }
exit 0
