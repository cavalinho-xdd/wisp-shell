#!/usr/bin/env bash
# Lists the user's Hyprland lua keybinds as JSON for SettingsPageKeybinds.qml.
# Read-only: scans ~/.config/hypr/**/*.lua for single-line hl.bind(...) calls.
# A bind is marked "editable" only when its dispatcher is a plain, self-contained
# hl.dsp.* call. scripts/apply_hypr_keybind.py only ever rewrites the key string
# and leaves the dispatcher untouched, so binds through a named lua function
# (e.g. a local `wisp_step_workspace(...)`) would actually rebind fine too —
# they're locked anyway as a conservative safety margin, since this listing
# can't tell a safe local function from one with side effects worth a second look.
python3 - <<'EOF'
import re, json, glob, os

hypr_dir = os.path.join(os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config"), "hypr")
files = sorted(set(
    glob.glob(os.path.join(hypr_dir, "*.lua"))
    + glob.glob(os.path.join(hypr_dir, "**/*.lua"), recursive=True)
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
