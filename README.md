<div align="center">
  <h1>Wisp Shell</h1>
  <p>A modern, floating pill-based desktop shell for Hyprland built on the Quickshell framework.</p>
  <a href="#installation">Installation</a> •
  <a href="#features">Features</a> •
  <a href="#configuration">Configuration</a>
</div>

<br>

Wisp Shell replaces the traditional desktop bar paradigm with an interactive, expanding peripheral widget. It is designed to be unobtrusive, highly functional, and visually cohesive, prioritizing clarity and rapid interaction over redundant on-screen information.

## Table of Contents
- [Features](#features)
- [Dependencies](#dependencies)
- [Installation](#installation)
  - [Automated Installation (Recommended)](#automated-installation-recommended)
  - [Manual Installation](#manual-installation)
- [Usage](#usage)
- [Architecture](#architecture)
- [License](#license)

## Features
- **Floating Pill Architecture**: An interactive, multi-state widget that expands to reveal detailed system information and collapses to save screen real estate.
- **Native Multi-Monitor Support**: Independent shell instances track focused workspaces and states on a per-display basis.
- **Integrated Tooling**:
  - Polkit Authentication Agent
  - System Tray and Media Controls
  - Hardware Control Popups (Volume/Microphone OSD)
  - Interactive Performance Monitors
- **First-Run Configuration**: A built-in graphical setup wizard and comprehensive settings application to manage the shell without editing text files.

## Dependencies
The shell relies on modern Wayland technologies and standard Linux subsystems.

| Dependency | Type | Description |
|---|---|---|
| `quickshell` | Core | The underlying QML framework |
| `hyprland` | Core | The compositor |
| `jq`, `bc` | Core | Data parsing and calculation |
| `upower` | Core | Battery widget data |
| `wl-clipboard`, `cliphist` | Core | Clipboard manager backend |
| `grim`, `slurp` | Core | Screenshot capabilities |
| `matugen` | Recommended | Dynamic wallpaper-based theming |
| `swww` or `hyprpaper` | Recommended | Wallpaper management |

## Installation

### Automated Installation (Recommended)
The easiest way to install Wisp Shell, along with its integrated Hyprland configurations and dynamic theming engine, is to use the automated installer provided in the `wisp-dots` repository.

```bash
git clone https://github.com/cavalinho-xdd/wisp-dots.git ~/.config/wisp-dots
cd ~/.config/wisp-dots
chmod +x install.sh
./install.sh
```

### Manual Installation
If you prefer to install only the shell components without the associated dotfiles, you can compile and install it directly from this repository.

```bash
git clone https://github.com/cavalinho-xdd/wisp-shell.git ~/.local/src/wisp-shell
cd ~/.local/src/wisp-shell
chmod +x setup
./setup install
```
This script copies the core QML assets to your local data directory and establishes the `wisp` CLI wrapper in your `$PATH`.

## Usage
Wisp Shell includes a dedicated command-line interface for managing its lifecycle and configuration.

```bash
wisp start     # Start the shell daemon in the background
wisp stop      # Terminate the shell session
wisp settings  # Open the graphical settings application
wisp status    # View current daemon status
```

## Architecture
The source code is structured as follows:
- `core/`: Core singleton services (Battery, Audio, Theme, Network).
- `components/`: Reusable UI elements and widgets.
- `generated/`: Dynamically generated assets and color palettes.
- `scripts/`: Helper bash scripts used for data polling and system interactions.

## License
This project is licensed under the MIT License.
