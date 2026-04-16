#!/usr/bin/env bash
# run_difftest.sh — One-shot difftest: simulate DUT + run spike, then compare.
#
# Usage:
#   ./scripts/run_difftest.sh <elf_file> [work_dir]
#
# Prerequisites:
#   - spike on PATH (see scripts/gen_spike_log.sh)
#   - mill on PATH or ./mill wrapper present
#   - Python 3
#
# Environment overrides:
#   SPIKE_ISA  — default: rv64imac_zicsr_zifencei
#   SPIKE_MEM  — default: 0x80000000:0x10000000
#   MAX_ERRORS — max mismatches before aborting compare (default: 10)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

ELF="${1:?Usage: $0 <elf_file> [work_dir]}"
WORK_DIR="${2:-$REPO_ROOT/difftest_work}"
MAX_ERRORS="${MAX_ERRORS:-10}"

mkdir -p "$WORK_DIR"

ELF_ABS="$(realpath "$ELF")"
HEX_FILE="$WORK_DIR/program.hex"
DUT_RAW="$WORK_DIR/dut_raw.log"
DUT_NORM="$WORK_DIR/dut_commit.log"
SPIKE_RAW="$WORK_DIR/spike_raw.log"
SPIKE_NORM="$WORK_DIR/spike_commit.log"

echo "============================================================"
echo " MyCPU Difftest (log comparison vs spike)"
echo "  ELF      : $ELF_ABS"
echo "  Work dir : $WORK_DIR"
echo "============================================================"

# ------------------------------------------------------------------
# Step 1: Convert ELF → hex for the Chisel TestHarness
# ------------------------------------------------------------------
echo ""
echo "[1/4] Converting ELF to hex (for DUT simulation)..."
if command -v riscv64-unknown-elf-objcopy &>/dev/null; then
    riscv64-unknown-elf-objcopy -O binary "$ELF_ABS" "$WORK_DIR/program.bin"
    xxd -e -g 8 "$WORK_DIR/program.bin" \
        | awk '{print $2}' \
        > "$HEX_FILE"
    echo "  -> $HEX_FILE"
else
    echo "[WARN] riscv64-unknown-elf-objcopy not found; skipping hex conversion."
    echo "       Provide $HEX_FILE manually and re-run."
fi

# ------------------------------------------------------------------
# Step 2: Run DUT simulation and capture stdout
# ------------------------------------------------------------------
echo ""
echo "[2/4] Running DUT simulation..."
cd "$REPO_ROOT"
MILL="${REPO_ROOT}/mill"
if [ ! -x "$MILL" ]; then
    MILL="mill"
fi

# Run the BenchmarkSpec (which loads a hex file).
# Override the hex path by passing it as a system property, then capture stdout.
# The COMMIT lines are printed to stdout by Chisel printf.
"$MILL" MyCPU.test.runMain org.scalatest.run MyCPU.BenchmarkSpec \
    -DHEX_PATH="$HEX_FILE" 2>&1 | tee "$DUT_RAW" || true

echo ""
echo "[3/4] Normalizing DUT log..."
python3 "$SCRIPT_DIR/normalize_dut_log.py" "$DUT_RAW" "$DUT_NORM"
echo "  -> $DUT_NORM  ($(wc -l < "$DUT_NORM") commit entries)"

# ------------------------------------------------------------------
# Step 3: Run spike reference
# ------------------------------------------------------------------
echo ""
"$SCRIPT_DIR/gen_spike_log.sh" "$ELF_ABS" "$SPIKE_NORM"

# ------------------------------------------------------------------
# Step 4: Compare
# ------------------------------------------------------------------
echo ""
echo "[4/4] Comparing logs..."
python3 "$SCRIPT_DIR/difftest.py" \
    "$DUT_NORM" "$SPIKE_NORM" \
    --max-errors "$MAX_ERRORS"
