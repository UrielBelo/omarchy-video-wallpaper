#!/bin/bash
# Installs the scripts into ~/.local/bin and creates the videos folder.
# Does not touch your Hyprland config -- see examples/ for the autostart
# and keybinding snippets to add yourself.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"

mkdir -p "$BIN_DIR" "$HOME/.config/omarchy/videos"
install -m 755 "$SCRIPT_DIR"/bin/* "$BIN_DIR/"

echo "Installed to $BIN_DIR:"
ls "$SCRIPT_DIR"/bin/
echo
echo "Missing a dependency? Install what you don't have:"
echo "  yay -S mpvpaper              # AUR -- renders the video on the background layer"
echo "  sudo pacman -S inotify-tools socat ffmpeg"
echo
echo "Next steps (see README.md for details):"
echo "  1. Drop .mp4/.webm/.mkv files into ~/.config/omarchy/videos/"
echo "  2. Add the autostart lines from examples/autostart.lua.snippet to ~/.config/hypr/autostart.lua"
echo "  3. Add the keybinding from examples/bindings.lua.snippet to ~/.config/hypr/bindings.lua"
echo "  4. hyprctl reload, then press your bound key to open the picker"
