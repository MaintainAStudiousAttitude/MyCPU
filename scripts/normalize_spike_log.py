#!/usr/bin/env python3
"""
normalize_spike_log.py — Convert raw spike --log-commits output to the
canonical COMMIT log format used by the difftest comparator.

Raw spike line format (two variants observed in the wild):

  Variant A (spike >= 1.1):
    core   0: 3 0x0000000080000000 (0x000101b7) x 3 0x0000000000010000
    core   0: 3 0x0000000080000010 (0x0051b023) mem 0x0000000000010000

  Variant B (older spike):
    core   0: 0x0000000080000000 (0x000101b7) x3  0x0000000000010000

Output format:
    COMMIT pc=0x<16-hex-digits> inst=0x<8-hex-digits> rd=<dd> wdata=0x<16-hex-digits> rf_wen=<0|1>
"""

import re
import sys


# Variant A: "core   0: <priv> <pc> (<insn>) x <rd> <val>"  (reg write)
#            "core   0: <priv> <pc> (<insn>) mem <addr>"     (store/load, no reg write shown)
# Some spike versions use "x <rd>" with a space, others "x<rd>" without.
RE_A_REG  = re.compile(
    r'core\s+\d+:\s+\d+\s+'          # "core   0: 3 "
    r'(0x[0-9a-f]+)\s+'              # pc
    r'\((0x[0-9a-f]+)\)\s+'          # inst
    r'x\s*(\d+)\s+'                  # "x 3" or "x3"
    r'(0x[0-9a-f]+)'                 # value
)
RE_A_MEM  = re.compile(
    r'core\s+\d+:\s+\d+\s+'
    r'(0x[0-9a-f]+)\s+'
    r'\((0x[0-9a-f]+)\)\s+'
    r'mem\s+(0x[0-9a-f]+)'
)
RE_A_NOREG = re.compile(
    r'core\s+\d+:\s+\d+\s+'
    r'(0x[0-9a-f]+)\s+'
    r'\((0x[0-9a-f]+)\)\s*$'
)

# Variant B (older): "core   0: <pc> (<insn>) x<rd>  <val>"
RE_B_REG  = re.compile(
    r'core\s+\d+:\s+'
    r'(0x[0-9a-f]+)\s+'
    r'\((0x[0-9a-f]+)\)\s+'
    r'x(\d+)\s+'
    r'(0x[0-9a-f]+)'
)
RE_B_MEM  = re.compile(
    r'core\s+\d+:\s+'
    r'(0x[0-9a-f]+)\s+'
    r'\((0x[0-9a-f]+)\)\s+'
    r'mem\s+(0x[0-9a-f]+)'
)
RE_B_NOREG = re.compile(
    r'core\s+\d+:\s+'
    r'(0x[0-9a-f]+)\s+'
    r'\((0x[0-9a-f]+)\)\s*$'
)


def fmt_pc(s: str) -> str:
    return f"0x{int(s, 16):016x}"

def fmt_inst(s: str) -> str:
    return f"0x{int(s, 16):08x}"

def fmt_wdata(s: str) -> str:
    return f"0x{int(s, 16):016x}"


def parse_line(line: str):
    """Return (pc, inst, rd, wdata, rf_wen) or None if line is not a commit."""
    line = line.rstrip()

    for pat, has_reg in [
        (RE_A_REG, True), (RE_B_REG, True),
        (RE_A_MEM, False), (RE_B_MEM, False),
        (RE_A_NOREG, False), (RE_B_NOREG, False),
    ]:
        m = pat.search(line)
        if m:
            pc   = fmt_pc(m.group(1))
            inst = fmt_inst(m.group(2))
            if has_reg:
                rd     = int(m.group(3))
                wdata  = fmt_wdata(m.group(4))
                rf_wen = 0 if rd == 0 else 1  # x0 writes are suppressed
            else:
                rd     = 0
                wdata  = "0x0000000000000000"
                rf_wen = 0
            return pc, inst, rd, wdata, rf_wen

    return None


def main():
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <raw_spike_log> <output_log>")
        sys.exit(1)

    in_path  = sys.argv[1]
    out_path = sys.argv[2]

    with open(in_path, "r", errors="replace") as fin, \
         open(out_path, "w") as fout:
        for line in fin:
            result = parse_line(line)
            if result is None:
                continue
            pc, inst, rd, wdata, rf_wen = result
            fout.write(
                f"COMMIT pc={pc} inst={inst} rd={rd:02d} wdata={wdata} rf_wen={rf_wen}\n"
            )


if __name__ == "__main__":
    main()
