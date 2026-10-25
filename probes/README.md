# Probes

Tiny standalone `.qml` files that check one Quickshell or system behaviour —
the project's substitute for tests. Run one with `qs -p probes/<file>.qml` and
read its `console.log` output (or `bash probes/<file>.sh`). Not shipped:
PKGBUILD leaves this folder out of the package.

Keep a probe here when the answer could change with a Quickshell or system
update and is worth re-checking; throw the rest away.

| Probe | Checks |
|---|---|
| `battery.qml` | What UPower's display device reports once it is ready |
| `battery-icon-binding.qml` | Whether a binding that calls a function re-evaluates when the battery changes |
| `exec-detached.qml` | That `Quickshell.execDetached` runs a command (touches `/tmp/qs-test`) |
| `sysmon.sh` | Disk use and network speed computed from `df` and `/proc/net/dev` |
