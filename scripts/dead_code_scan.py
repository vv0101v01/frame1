#!/usr/bin/env python3
"""Strict dead-code scanner for the MoonBit sources.

Improvements over the naive token scanner:
  1. Strips `// ...` and `/// ...` comment lines and string literals before
     counting references, so doc-comments never mask dead code.
  2. Distinguishes `Type::method` definitions from free `fn name(...)`
     definitions: a method `Type::m` is alive only if `Type::m` appears more
     than once OR `.m(` appears as a dot-method call, preventing common bare
     identifiers (`zero`, `one`, `set`, `total`, `monomial`, ...) from
     masking unused methods.
  3. Scans top-level `struct` and `enum` declarations as well.

Exit code is 1 when dead definitions are found, so `verify.sh` fails loudly.
"""
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FILES = sorted(glob.glob(os.path.join(ROOT, "src", "**", "*.mbt"), recursive=True))

STRING_RE = re.compile(r'"(?:\\.|[^"\\])*"')


def strip_code_line(line: str) -> str:
    s = line.lstrip()
    if s.startswith("//"):
        return ""
    no_str = STRING_RE.sub('""', line)
    idx = no_str.find("//")
    if idx >= 0:
        no_str = no_str[:idx]
    return no_str


def main() -> int:
    src = {f: open(f, encoding="utf-8").read() for f in FILES}
    stripped_lines = []
    defs = []
    for f, t in src.items():
        for i, line in enumerate(t.split("\n"), start=1):
            clean = strip_code_line(line)
            stripped_lines.append(clean)
            m = re.match(
                r"^(?:pub(?:\([a-z]+\))?\s+)?fn\s+([A-Za-z0-9_]+)::([A-Za-z0-9_]+)",
                clean,
            )
            if m:
                defs.append(("method", f, f"{m.group(1)}::{m.group(2)}", m.group(1), m.group(2), i))
                continue
            m = re.match(
                r"^(?:pub(?:\([a-z]+\))?\s+)?fn\s+([A-Za-z0-9_]+)\s*[\(\[]",
                clean,
            )
            if m and m.group(1) != "main":
                defs.append(("fn", f, m.group(1), "", m.group(1), i))
                continue
            m = re.match(
                r"^(?:pub(?:\([a-z]+\))?\s+)?(?:struct|enum)\s+([A-Za-z0-9_]+)\b",
                clean,
            )
            if m:
                defs.append(("type", f, m.group(1), "", m.group(1), i))

    blob = "\n".join(stripped_lines)
    dead = []
    for kind, f, display, ty, name, line_no in defs:
        if kind == "method":
            qual_hits = len(
                re.findall(r"\b" + re.escape(ty) + r"::" + re.escape(name) + r"\b", blob)
            )
            dot_hits = len(re.findall(r"\." + re.escape(name) + r"\s*\(", blob))
            # Definition line itself accounts for 1 `Type::method` occurrence.
            if (qual_hits - 1) + dot_hits <= 0:
                dead.append((f, display, line_no))
        else:
            hits = len(re.findall(r"\b" + re.escape(name) + r"\b", blob))
            if hits <= 1:
                dead.append((f, display, line_no))

    print(f"scanned {len(defs)} definitions (functions, methods, types) in {len(FILES)} files")
    for f, display, line_no in dead:
        print(f"  DEAD  {os.path.relpath(f, ROOT)}:{line_no}  {display}")
    if dead:
        print(f"{len(dead)} dead definition(s)")
        return 1
    print("no dead definitions")
    return 0


if __name__ == "__main__":
    sys.exit(main())
