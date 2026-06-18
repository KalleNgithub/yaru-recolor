#!/usr/bin/env bash
# Install yaru-recolor. Run locally from the repo or pipe from curl:
#   curl -sL https://raw.githubusercontent.com/KalleNgithub/yaru-recolor/master/install.sh | bash

set -euo pipefail

INSTALL_BIN="$HOME/.local/bin"
INSTALL_DATA="$HOME/.local/share/yaru-recolor"

# If running from the repo (install.sh is next to yaru-recolor), use local files.
# Otherwise, clone from GitHub into a temp dir.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/yaru-recolor" && -d "$SCRIPT_DIR/yaru-sources" ]]; then
  SOURCE="$SCRIPT_DIR"
  CLEANUP=""
else
  SOURCE="$(mktemp -d)"
  CLEANUP="$SOURCE"
  echo "Cloning yaru-recolor..."
  git clone --depth 1 https://github.com/KalleNgithub/yaru-recolor.git "$SOURCE"
fi

# Install script and sources
mkdir -p "$INSTALL_BIN" "$INSTALL_DATA"
install -m 0755 "$SOURCE/yaru-recolor" "$INSTALL_BIN/"
cp -r "$SOURCE/yaru-sources" "$INSTALL_DATA/"

# Install dependencies
echo "Installing dependencies (imagemagick, x11-apps)..."
sudo apt install -y imagemagick x11-apps

# Ensure ~/.local/bin is on PATH
if ! echo "$PATH" | grep -q "$INSTALL_BIN"; then
  echo "export PATH=\"$INSTALL_BIN:\$PATH\"" >> "$HOME/.bashrc"
  echo "Added $INSTALL_BIN to PATH in ~/.bashrc — restart your shell or run: source ~/.bashrc"
fi

# Cleanup temp clone if used
[[ -n "$CLEANUP" ]] && rm -rf "$CLEANUP"

echo
echo "✓ yaru-recolor installed. Run:"
echo "  yaru-recolor fill='#FF1493' border='#2CFF05'"
