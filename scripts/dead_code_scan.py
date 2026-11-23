#!/usr/bin/env python3
"""Cheap dead-code scan for the MoonBit sources.

Reports every top-level definition (function, method, private helper) whose
name occurs nowhere else in `src/`.  A name that only appears in its own
definition line is dead by construction.

Exit code is 1 when dead definitions are found, so `verify.sh` fails loudly.

Note: this is a *name-level* heuristic.  It cannot see a public definition
that is only used from outside the module (there is none here: the project is
a single module plus an executable) nor a definition used only through a
trait method.  Every remaining public definition is referenced by a test.
"""
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FILES = sorted(glob.glob(os.path.join(ROOT, "src", "**", "*.mbt"), recursive=True))


def main():
    src = {f: open(f, encoding="utf-8").read() for f in FILES}
    blob = "\n".join(src.values())
    defs = []
    for f, t in src.items():
        for i, line in enumerate(t.split("\n"), start=1):
            m = re.match(r"^(?:pub )?fn ([A-Za-z0-9_]+)\:\:([A-Za-z0-9_]+)", line)
            if m:
                defs.append((f, m.group(2), i))
                continue
            m = re.match(r"^(?:pub )?fn ([A-Za-z0-9_]+)\(", line)
            if m:
                defs.append((f, m.group(1), i))
    dead = [(f, n, i) for f, n, i in defs if len(re.findall(r"\b" + re.escape(n) + r"\b", blob)) <= 1]
    print(f"scanned {len(defs)} definitions in {len(FILES)} files")
    for f, n, i in dead:
        print(f"  DEAD  {os.path.relpath(f, ROOT)}:{i}  {n}")
    if dead:
        print(f"{len(dead)} dead definition(s)")
        return 1
    print("no dead definitions")
    return 0


if __name__ == "__main__":
    sys.exit(main())
