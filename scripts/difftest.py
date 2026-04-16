#!/usr/bin/env python3
"""
difftest.py — Compare normalized DUT commit log against spike reference log.

Both logs must be in the canonical format produced by normalize_dut_log.py
and normalize_spike_log.py:

    COMMIT pc=0x<16h> inst=0x<8h> rd=<dd> wdata=0x<16h> rf_wen=<0|1>

Comparison rules:
  1. PC must match exactly (same instruction retired in same order).
  2. inst encoding must match exactly.
  3. If rf_wen=1 AND rd != x0 in the reference, wdata must match.
     (We trust the DUT rf_wen flag only for reporting, not gating the check.)

Usage:
    python3 scripts/difftest.py <dut_log> <spike_log> [--max-errors N]
"""

import argparse
import re
import sys
from dataclasses import dataclass
from typing import Optional


@dataclass
class CommitEntry:
    pc:     int
    inst:   int
    rd:     int
    wdata:  int
    rf_wen: int
    lineno: int


RE = re.compile(
    r'COMMIT\s+'
    r'pc=(0x[0-9a-fA-F]+)\s+'
    r'inst=(0x[0-9a-fA-F]+)\s+'
    r'rd=(\d+)\s+'
    r'wdata=(0x[0-9a-fA-F]+)\s+'
    r'rf_wen=([01])'
)


def parse_log(path: str):
    entries = []
    with open(path, "r", errors="replace") as f:
        for lineno, line in enumerate(f, 1):
            m = RE.search(line)
            if m:
                entries.append(CommitEntry(
                    pc     = int(m.group(1), 16),
                    inst   = int(m.group(2), 16),
                    rd     = int(m.group(3)),
                    wdata  = int(m.group(4), 16),
                    rf_wen = int(m.group(5)),
                    lineno = lineno,
                ))
    return entries


def fmt(e: CommitEntry) -> str:
    return (f"pc=0x{e.pc:016x} inst=0x{e.inst:08x} "
            f"rd=x{e.rd:02d} wdata=0x{e.wdata:016x} rf_wen={e.rf_wen}")


def compare(dut_log: str, ref_log: str, max_errors: int) -> int:
    dut = parse_log(dut_log)
    ref = parse_log(ref_log)

    print(f"[difftest] DUT: {len(dut)} commits  |  REF(spike): {len(ref)} commits")

    errors  = 0
    checked = 0
    limit   = min(len(dut), len(ref))

    for i in range(limit):
        d = dut[i]
        r = ref[i]
        checked += 1
        ok = True
        reasons = []

        if d.pc != r.pc:
            reasons.append(f"PC  dut=0x{d.pc:016x}  ref=0x{r.pc:016x}")
            ok = False

        if d.inst != r.inst:
            reasons.append(f"INST dut=0x{d.inst:08x}  ref=0x{r.inst:08x}")
            ok = False

        # Only compare wdata when reference says rf_wen=1 and rd != x0
        if r.rf_wen == 1 and r.rd != 0:
            if d.wdata != r.wdata:
                reasons.append(
                    f"WDATA(x{r.rd:02d}) dut=0x{d.wdata:016x}  ref=0x{r.wdata:016x}"
                )
                ok = False

        if not ok:
            errors += 1
            print(f"\n[MISMATCH] commit #{i+1}  (dut_line={d.lineno} ref_line={r.lineno})")
            print(f"  DUT: {fmt(d)}")
            print(f"  REF: {fmt(r)}")
            for reason in reasons:
                print(f"  >>> {reason}")
            if errors >= max_errors:
                print(f"\n[difftest] Stopped after {max_errors} error(s).")
                break

    print(f"\n[difftest] Checked {checked} instructions.")

    if len(dut) != len(ref):
        print(f"[WARNING] Commit count mismatch: DUT={len(dut)}  REF={len(ref)}")

    if errors == 0:
        print("[difftest] PASS — DUT matches reference for all checked instructions.")
        return 0
    else:
        print(f"[difftest] FAIL — {errors} mismatch(es) found.")
        return 1


def main():
    parser = argparse.ArgumentParser(description="Difftest log comparator (DUT vs spike)")
    parser.add_argument("dut_log",   help="Normalized DUT commit log")
    parser.add_argument("spike_log", help="Normalized spike commit log")
    parser.add_argument("--max-errors", type=int, default=10,
                        help="Stop after this many mismatches (default: 10)")
    args = parser.parse_args()

    sys.exit(compare(args.dut_log, args.spike_log, args.max_errors))


if __name__ == "__main__":
    main()
