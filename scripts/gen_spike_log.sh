#!/usr/bin/env bash
# gen_spike_log.sh — Run spike on a RISC-V ELF and produce a normalized commit log.
#
# Usage:
#   ./scripts/gen_spike_log.sh <elf_file> [output_log]
#
# Output format (one line per committed instruction):
#   COMMIT pc=0x<pc> inst=0x<inst> rd=<rd> wdata=0x<wdata> rf_wen=<0|1>
#
# Requirements:
#   - spike (riscv-isa-sim) on PATH, with pk or bare-metal support
#   - ISA: rv64imac (adjust SPIKE_ISA below if needed)

set -euo pipefail

ELF="${1:?Usage: $0 <elf_file> [output_log]}"
OUT="${2:-spike_commit.log}"
SPIKE_ISA="${SPIKE_ISA:-rv64imac_zicsr_zifencei}"
SPIKE_MEM="${SPIKE_MEM:-0x80000000:0x10000000}"

if ! command -v spike &>/dev/null; then
    echo "[ERROR] 'spike' not found on PATH."
    echo "  Install: https://github.com/riscv-software-src/riscv-isa-sim"
    echo "  Or set PATH to include the spike binary."
    exit 1
fi

if [ ! -f "$ELF" ]; then
    echo "[ERROR] ELF file not found: $ELF"
    exit 1
fi

echo "[spike] Running: spike --isa=$SPIKE_ISA -l --log-commits -m$SPIKE_MEM $ELF"
echo "[spike] Raw log -> ${OUT}.raw"

# spike writes the commit log to stderr with -l / --log-commits
spike --isa="$SPIKE_ISA" -l --log-commits -m"$SPIKE_MEM" "$ELF" 2>"${OUT}.raw" || true

echo "[spike] Normalizing log -> $OUT"
python3 "$(dirname "$0")/normalize_spike_log.py" "${OUT}.raw" "$OUT"

echo "[spike] Done. $(wc -l < "$OUT") committed instructions logged."
