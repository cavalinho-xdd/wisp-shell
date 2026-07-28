# Wisp Shell

A modern floating pill-based shell for Hyprland built on [Quickshell](https://outfoxxed.me/quickshell/).

## Features

- **Floating Pill Architecture**: Interactive expanding widget replacing a traditional bar.
- **Multimonitor Support**: Seamless multi-display integration.
- **Widgets**: Performance monitor, calendar, media controls, weather, and a system tray.
- **First-Run Wizard**: Setup configuration intuitively on your first launch.
- **OSD Popups**: On-screen display for volume and mic adjustments.
- **Built-in Configuration**: Comprehensive settings app designed directly into the shell.

## Dependencies

- **Required**:
  - `quickshell`
  - `hyprland`
  - `jq`
  - `upower` (for battery widget)
  - `cliphist` & `wl-clipboard` (for clipboard manager)
  - `grim` & `slurp` (for screenshot support)
  - `bc` (for system usage calculations)
- **Optional**:
  - `matugen` (for wallpaper-derived colors)
  - `swww` or `hyprpaper` (for wallpaper management)
  - `qalc` (for launcher calculator)
  - `nvidia-utils` (for GPU monitoring in the Performance widget)

## Installation

### Arch Linux (AUR)
Use the included `PKGBUILD` or your favorite AUR helper once published:
```bash
makepkg -si
```

### Manual Installation
You can use the provided setup script which handles dependencies and installs Wisp Shell into your local data directory, setting up the `wisp` CLI wrapper in `~/.local/bin`.
```bash
git clone https://github.com/cavalinho-xdd/wisp-shell.git
cd wisp-shell
./setup install
```

The `setup` script supports several subcommands:
- `install`: Install dependencies, Wisp core, and dotfiles.
- `update`: Update Wisp core and dotfiles from the repository.
- `uninstall`: Remove Wisp core and CLI.
- `deps`: Only install missing dependencies.
- `dots`: Only install/update dotfiles.

## Usage

Wisp includes a convenient CLI (`wisp`) for managing the shell.

```bash
# Check dependencies and fonts
wisp doctor

# Start the shell in the background
wisp start

# Open the settings app
wisp settings

# View shell status
wisp status

# Stop the shell
wisp stop
```

## Contributing
Wisp is a personal project by cavalinho-xdd and is currently not accepting external pull requests for new features, but bug reports and suggestions are welcome!
