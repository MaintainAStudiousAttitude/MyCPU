#!/usr/bin/env python3
"""
normalize_dut_log.py — Filter and normalize COMMIT lines from the DUT simulation log.

The DUT (Chisel simulation) mixes various printf lines with the COMMIT entries.
This script extracts only the COMMIT lines and normalizes the hex formatting.

Raw DUT COMMIT format (emitted by rob.scala):
    COMMIT pc=0x80000000 inst=0x000101b7 rd=3 wdata=0x10000 rf_wen=1

Normalized output:
    COMMIT pc=0x0000000080000000 inst=0x000101b7 rd=03 wdata=0x0000000000010000 rf_wen=1
"""

import re
import sys

RE_COMMIT = re.compile(
    r'COMMIT\s+'
    r'pc=(0x[0-9a-fA-F]+)\s+'
    r'inst=(0x[0-9a-fA-F]+)\s+'
    r'rd=(\d+)\s+'
    r'wdata=(0x[0-9a-fA-F]+)\s+'
    r'rf_wen=([01])'
)


def main():
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <raw_dut_log> <output_log>")
        sys.exit(1)

    in_path  = sys.argv[1]
    out_path = sys.argv[2]

    with open(in_path, "r", errors="replace") as fin, \
         open(out_path, "w") as fout:
        for line in fin:
            m = RE_COMMIT.search(line)
            if m is None:
                continue
            pc     = f"0x{int(m.group(1), 16):016x}"
            inst   = f"0x{int(m.group(2), 16):08x}"
            rd     = int(m.group(3))
            wdata  = f"0x{int(m.group(4), 16):016x}"
            rf_wen = int(m.group(5))
            fout.write(
                f"COMMIT pc={pc} inst={inst} rd={rd:02d} wdata={wdata} rf_wen={rf_wen}\n"
            )


if __name__ == "__main__":
    main()
