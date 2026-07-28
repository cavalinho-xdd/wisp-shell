#!/usr/bin/env bash
set -e

DEST_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/wisp-shell"
BIN_DIR="${HOME}/.local/bin"

echo "Installing Wisp Shell..."

mkdir -p "$DEST_DIR"
cp -a ./* "$DEST_DIR/"

mkdir -p "$BIN_DIR"
ln -sf "$DEST_DIR/wisp" "$BIN_DIR/wisp"

echo "Wisp Shell installed successfully to $DEST_DIR"
echo "Wrapper script created at $BIN_DIR/wisp"
echo ""
echo "Make sure $BIN_DIR is in your PATH."
echo "Run 'wisp doctor' to check dependencies, and 'wisp start' to launch the shell."
