#!/usr/bin/env python3
# apply_hypr_keybind.py <orig_key> <new_key>
#
# Rewrites the key string of a matching hl.bind("<orig_key>", ...) line,
# in place, in whichever ~/.config/hypr/*.lua file actually declares it.
# Same set of files keybinds_list.sh reads to list binds in the first place.
# Direct dotfile edit, no runtime-only hl.unbind/hl.bind injection — the
# caller runs `hyprctl reload` afterwards to apply it.
import glob
import os
import re
import sys

orig_key, new_key = sys.argv[1], sys.argv[2]

hypr_dir = os.path.join(os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config"), "hypr")
files = sorted(
    set(
        glob.glob(os.path.join(hypr_dir, "*.lua"))
        + glob.glob(os.path.join(hypr_dir, "**/*.lua"), recursive=True)
    )
)

pat = re.compile(r'(hl\.bind\(\s*")' + re.escape(orig_key) + r'("\s*,)')
replacement = "\\g<1>" + new_key.replace("\\", "\\\\") + "\\g<2>"

for path in files:
    try:
        with open(path) as f:
            text = f.read()
    except OSError:
        continue
    new_text, n = pat.subn(replacement, text, count=1)
    if n:
        with open(path, "w") as f:
            f.write(new_text)
        print(f"rebound in {path}")
        sys.exit(0)

print("bind not found", file=sys.stderr)
sys.exit(1)
