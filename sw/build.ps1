param([string]$Name)
if (-not $Name) { Write-Host "usage: .\sw\build.ps1 NAME"; exit 1 }
Set-Location (Join-Path $PSScriptRoot "..")
$flags = @("-march=rv32i", "-mabi=ilp32", "-O1", "-ffreestanding", "-mno-relax", "-fno-asynchronous-unwind-tables", "-fno-unwind-tables")
$src = "sw\$Name.c"
$obj = "sw\$Name.o"
$elf = "sw\$Name.elf"
$map = "sw\$Name.map"
$bin = "sw\$Name.bin"
$dbin = "sw\$Name.data.bin"
$hex = "sw\$Name.hex"
$dhex = "sw\$Name.data.hex"
Remove-Item sw\start.o, $obj, $elf, $map, $bin, $dbin, $hex, $dhex -ErrorAction SilentlyContinue
riscv-none-elf-gcc @flags -c sw\start.S -o sw\start.o
if ($LASTEXITCODE -ne 0) { Write-Host "FAILED: assembling start.S"; exit 1 }
riscv-none-elf-gcc @flags -c $src -o $obj
if ($LASTEXITCODE -ne 0) { Write-Host "FAILED: compiling $Name.c"; exit 1 }
riscv-none-elf-gcc @flags -nostdlib -T sw\link.ld "-Wl,--no-relax" "-Wl,-Map=$map" sw\start.o $obj -lgcc -o $elf
if ($LASTEXITCODE -ne 0) { Write-Host "FAILED: linking"; exit 1 }
riscv-none-elf-objcopy -O binary -j .text $elf $bin
if ($LASTEXITCODE -ne 0) { Write-Host "FAILED: extracting code"; exit 1 }
.\sw\bin2hex.ps1 $bin $hex
if ($LASTEXITCODE -ne 0) { Write-Host "FAILED: converting code"; exit 1 }
$hasData = riscv-none-elf-objdump -h $elf | Select-String '\s\.data\s'
if ($hasData) {
riscv-none-elf-objcopy -O binary -j .data $elf $dbin
if ($LASTEXITCODE -ne 0) { Write-Host "FAILED: extracting data"; exit 1 }
.\sw\bin2hex.ps1 $dbin $dhex
if ($LASTEXITCODE -ne 0) { Write-Host "FAILED: converting data"; exit 1 }
}
Write-Host "built ${Name}: $((Get-Content $hex).Count) code words"
