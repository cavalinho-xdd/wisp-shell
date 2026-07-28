# Wisp Shell

A modern, floating pill-based desktop shell for Hyprland built on the Quickshell framework.

Wisp Shell abandons the traditional desktop bar paradigm in favor of an interactive, expanding peripheral widget. It is designed to be unobtrusive, highly functional, and visually cohesive, prioritizing clarity and rapid interaction over redundant on-screen information.

## Core Features

- **Floating Pill Architecture**: An interactive, multi-state widget that expands to reveal detailed system information and collapses to save screen real estate.
- **Native Multi-Monitor Support**: Independent shell instances track focused workspaces and states on a per-display basis.
- **Integrated Tooling**:
  - Polkit Authentication Agent
  - System Tray and Media Controls
  - Hardware Control Popups (Volume/Microphone OSD)
  - Interactive Performance Monitors
- **First-Run Configuration**: A built-in graphical setup wizard and comprehensive settings application to manage the shell without editing text files.

## Dependencies

The shell relies on modern Wayland technologies and standard Linux subsystems:

- **Core Requirements**: `quickshell`, `hyprland`, `jq`, `upower`, `wl-clipboard`, `cliphist`, `grim`, `slurp`, `bc`.
- **Recommended**: `matugen` (for dynamic wallpaper-based theming) and `swww` or `hyprpaper` (for wallpaper management).

## Installation

### The Automated Approach (Recommended)
The easiest way to install Wisp Shell, along with its integrated Hyprland configurations and dynamic theming engine, is to use the automated installer provided in the `wisp-dots` repository.

```bash
git clone https://github.com/cavalinho-xdd/wisp-dots.git
cd wisp-dots
chmod +x install.sh
./install.sh
```
This script will safely back up existing configurations, install dependencies, and set up both the shell and the system dotfiles.

### Manual Installation
If you prefer to install only the shell components without the associated dotfiles:

```bash
git clone https://github.com/cavalinho-xdd/wisp-shell.git
cd wisp-shell
./setup install
```
This script copies the core QML assets to your local data directory and sets up the `wisp` CLI wrapper.

## Command Line Interface

Wisp Shell includes a dedicated command-line interface for managing its lifecycle and configuration.

```bash
# Start the shell daemon in the background
wisp start

# Terminate the shell session
wisp stop

# Open the graphical settings application
wisp settings

# View current daemon status
wisp status
```

## Contributing

Wisp is developed and maintained by cavalinho-xdd. While the project is currently tailored for a specific workflow and not actively accepting feature pull requests, bug reports and architectural suggestions are highly appreciated.
