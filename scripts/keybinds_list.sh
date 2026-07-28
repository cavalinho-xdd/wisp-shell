#!/usr/bin/env bash
# Lists the user's Hyprland lua keybinds as JSON for SettingsPageKeybinds.qml.
# Read-only: scans ~/.config/hypr/**/*.lua for single-line hl.bind(...) calls.
# A bind is "editable" (rebindable at runtime) only when its dispatcher is a
# self-contained hl.dsp.* expression — lines referencing local lua variables
# can't be re-evaluated through `hyprctl eval`, so they're shown locked.
python3 - <<'EOF'
import re, json, glob, os

files = sorted(set(
    glob.glob(os.path.expanduser("~/.config/hypr/*.lua"))
    + glob.glob(os.path.expanduser("~/.config/hypr/**/*.lua"), recursive=True)
))

pat = re.compile(r'^\s*hl\.bind\(\s*"([^"]+)"\s*,\s*(.*)\)\s*$')
desc_pat = re.compile(r'description\s*=\s*"([^"]*)"')
editable_pat = re.compile(r'^hl\.dsp\.[\w.]+\(.*\)\s*(,\s*\{.*\})?$', re.S)

binds = []
for f in files:
    try:
        lines = open(f, errors="ignore").readlines()
    except OSError:
        continue
    for line in lines:
        m = pat.match(line.rstrip())
        if not m:
            continue
        key, rest = m.group(1), m.group(2).strip()
        d = desc_pat.search(rest)
        binds.append({
            "key": key,
            "rest": rest,
            "desc": d.group(1) if d else "",
            "file": os.path.basename(f),
            "editable": bool(editable_pat.match(rest)) and ".." not in rest,
        })

print(json.dumps(binds))
EOF
