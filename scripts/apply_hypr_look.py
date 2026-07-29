#!/usr/bin/env python3
# apply_hypr_look.py <hypr_dir> <gaps_in> <gaps_out> <border_size> <rounding>
#                     <blur_enabled 0|1> <blur_size> <blur_passes> <anim_enabled 0|1>
#
# Writes the Hyprland "Look & Feel" settings directly into the user's real
# general.lua/animations.lua, then the caller runs `hyprctl reload` — no
# separate runtime-injection layer, no override state to wipe. This IS the
# user's config now.
import re
import sys
import os

hypr_dir = sys.argv[1]
gaps_in, gaps_out, border_size, rounding = sys.argv[2:6]
blur_enabled, blur_size, blur_passes = sys.argv[6:9]
anim_enabled = sys.argv[9]

gpath = os.path.join(hypr_dir, "general.lua")
with open(gpath) as f:
    g = f.read()

g = re.sub(r"gaps_in\s*=\s*\d+", f"gaps_in = {gaps_in}", g, count=1)
g = re.sub(r"gaps_out\s*=\s*\d+", f"gaps_out = {gaps_out}", g, count=1)
g = re.sub(r"border_size\s*=\s*\d+", f"border_size = {border_size}", g, count=1)
g = re.sub(r"rounding\s*=\s*\d+", f"rounding = {rounding}", g, count=1)

blur_bool = "true" if blur_enabled == "1" else "false"


def blur_sub(m):
    return f"{m.group(1)}{blur_bool}{m.group(2)}{blur_size}{m.group(3)}{blur_passes}"


g = re.sub(
    r"(blur\s*=\s*\{\s*enabled\s*=\s*)(?:true|false)(,\s*size\s*=\s*)\d+(,\s*passes\s*=\s*)\d+",
    blur_sub,
    g,
    count=1,
)

with open(gpath, "w") as f:
    f.write(g)

apath = os.path.join(hypr_dir, "animations.lua")
if os.path.exists(apath):
    with open(apath) as f:
        a = f.read()
    anim_bool = "true" if anim_enabled == "1" else "false"
    a = re.sub(
        r"(hl\.animation\(\{[^}]*?enabled\s*=\s*)(?:true|false)",
        lambda m: m.group(1) + anim_bool,
        a,
    )
    with open(apath, "w") as f:
        f.write(a)

print("ok")
