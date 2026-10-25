#!/usr/bin/env python3
"""qmllint over every .qml in the repo, failing only on warnings that are not
in the baseline.

    scripts/lint.py                     # check, exit 1 on new warnings
    scripts/lint.py --update-baseline   # accept the current warnings

The baseline (scripts/lint-baseline.txt) holds one line per warning as
"file<TAB>category<TAB>message" without line numbers, so moving code around
does not count as a new warning. Update it in the same commit that fixes
warnings, so the count only goes down.

Imports resolve through the Quickshell VFS that .qmlls.ini points to. The file
is created by `touch .qmlls.ini` and filled in by Quickshell on the next start
or reload of the shell.
"""

import json
import subprocess
import sys
import tempfile
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BASELINE = ROOT / "scripts" / "lint-baseline.txt"
# /usr/bin/qmllint is the Qt 5 one; it cannot read Qt 6 code.
QMLLINT = "/usr/lib/qt6/bin/qmllint"


def build_dir():
    ini = ROOT / ".qmlls.ini"
    if ini.exists():
        for line in ini.read_text().splitlines():
            if line.startswith("buildDir="):
                return line.split("=", 1)[1].strip('"')
    sys.exit(
        "lint: .qmlls.ini is missing or not filled in yet.\n"
        "      Run `touch .qmlls.ini`, then start or reload the shell once."
    )


def qml_files():
    out = subprocess.run(
        ["git", "ls-files", "-co", "--exclude-standard", "*.qml"],
        cwd=ROOT, capture_output=True, text=True, check=True,
    ).stdout.split()
    return [f for f in out if not f.startswith("probes/")]


def run_qmllint(files):
    with tempfile.NamedTemporaryFile(suffix=".json") as tmp:
        # qmllint exits non-zero whenever there are warnings; the JSON is the result.
        subprocess.run(
            [QMLLINT, "-I", build_dir(), "--json", tmp.name, *files],
            cwd=ROOT, capture_output=True,
        )
        data = json.loads(Path(tmp.name).read_text() or "{}")
    if "files" not in data:
        sys.exit("lint: qmllint produced no report")
    found = []
    for f in data["files"]:
        for w in f.get("warnings", []):
            if w.get("type") != "warning":
                continue
            key = "\t".join((f["filename"], w.get("id", "?"), w["message"].replace("\n", " ")))
            found.append((key, w.get("line", 0), w.get("column", 0)))
    return found


def main():
    update = "--update-baseline" in sys.argv[1:]
    found = run_qmllint(qml_files())
    current = Counter(k for k, _, _ in found)

    if update:
        BASELINE.write_text("".join(k + "\n" for k in sorted(current.elements())))
        print(f"lint: baseline updated, {sum(current.values())} warnings")
        return 0

    baseline = Counter(BASELINE.read_text().splitlines()) if BASELINE.exists() else Counter()
    new = current - baseline
    fixed = baseline - current

    if new:
        left = Counter(new)
        for key, line, col in found:
            if left[key]:
                left[key] -= 1
                file, cat, msg = key.split("\t")
                print(f"{file}:{line}:{col}: [{cat}] {msg}")
        print(f"lint: {sum(new.values())} new warning(s)")
        return 1

    msg = f"lint: no new warnings ({sum(current.values())} in baseline)"
    if fixed:
        msg += f"; {sum(fixed.values())} fixed, run with --update-baseline"
    print(msg)
    return 0


if __name__ == "__main__":
    sys.exit(main())
