#!/usr/bin/env python3
# write_custom_keybinds.py <hypr_dir> <json items>
#
# Regenerates hypr/keybinds_custom.lua from scratch — this file is 100%
# wisp-managed (unlike keybinds.lua, which mixes wisp-dots defaults with
# whatever the user hand-edits), so a full rewrite on every add/edit/remove
# is safe where line-patching keybinds.lua would not be.
#
# items: [{ "keyStr": "SUPER + T", "luaExpr": "hl.dsp.exec_cmd(\"kitty\")",
#           "description": "Open terminal" }, ...]
import json
import os
import sys

hypr_dir = sys.argv[1]
items = json.loads(sys.argv[2])

lines = [
    "-- Wisp custom keybinds -- managed entirely by Settings > Keybinds > Add keybind.",
    "-- Hand edits here will be overwritten the next time a keybind is added, edited, or removed.",
    "",
]

for it in items:
    key = (it.get("keyStr") or "").strip()
    expr = (it.get("luaExpr") or "").strip()
    if not key or not expr:
        continue
    desc = (it.get("description") or "").replace("\\", "\\\\").replace('"', '\\"')
    lines.append('hl.bind("%s", %s, { description = "%s" })' % (key, expr, desc))

with open(os.path.join(hypr_dir, "keybinds_custom.lua"), "w") as f:
    f.write("\n".join(lines) + "\n")

print("ok")
