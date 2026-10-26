#!/usr/bin/env bash
# One-click setup for a MacBook: OpenCode Desktop + Zen + photo-carousel skill.
# No API key. Run this one line in Terminal:
#   curl -fsSL https://raw.githubusercontent.com/dzianisv/opencode-one-click/main/install.sh | bash
#
# What it does, in order:
#   1. Installs the OpenCode CLI if missing.
#   2. Installs OpenCode Desktop on macOS (Homebrew cask, or the .dmg fallback).
#   3. Configures OpenCode to use Zen's free vision model by default.
#   4. Installs the photo-carousel skill to ~/.config/opencode/skills/
#   5. Creates ~/photo-content/photos/ and ~/photo-content/output/
#   6. Asks you to authenticate with Zen (opens the sign-in in your browser).
set -euo pipefail

echo "== One-click OpenCode + Zen setup =="

# 1. OpenCode CLI
if command -v opencode >/dev/null 2>&1; then
  echo "OpenCode CLI already installed."
else
  echo "Installing OpenCode CLI..."
  curl -fsSL https://opencode.ai/install | bash
fi

# 2. OpenCode Desktop (macOS)
install_desktop_dmg() {
  local arch asset dmg mount app
  if [ "$(uname -m)" = "arm64" ]; then
    for asset in opencode-desktop-mac-arm64.dmg opencode-desktop-darwin-aarch64.dmg; do
      echo "Trying Desktop .dmg: $asset"
      dmg="/tmp/opencode-desktop.dmg"
      if curl -fsSL -o "$dmg" "https://github.com/anomalyco/opencode/releases/latest/download/$asset" \
        && [ -s "$dmg" ]; then
        mount="$(hdiutil attach -nobrowse -quiet "$dmg" 2>/dev/null | tail -1 | awk '{$1=""; $2=""; print $0}' | sed 's/^  *//')"
        app="$(find "$mount" -maxdepth 1 -name '*.app' 2>/dev/null | head -1)"
        if [ -n "$app" ]; then
          cp -R "$app" /Applications/
          hdiutil detach "$mount" -quiet || true
          rm -f "$dmg"
          echo "Installed OpenCode Desktop from .dmg."
          return 0
        fi
        hdiutil detach "$mount" -quiet || true
        rm -f "$dmg"
      fi
    done
  else
    for asset in opencode-desktop-mac-x64.dmg opencode-desktop-darwin-x64.dmg; do
      echo "Trying Desktop .dmg: $asset"
      dmg="/tmp/opencode-desktop.dmg"
      if curl -fsSL -o "$dmg" "https://github.com/anomalyco/opencode/releases/latest/download/$asset" \
        && [ -s "$dmg" ]; then
        mount="$(hdiutil attach -nobrowse -quiet "$dmg" 2>/dev/null | tail -1 | awk '{$1=""; $2=""; print $0}' | sed 's/^  *//')"
        app="$(find "$mount" -maxdepth 1 -name '*.app' 2>/dev/null | head -1)"
        if [ -n "$app" ]; then
          cp -R "$app" /Applications/
          hdiutil detach "$mount" -quiet || true
          rm -f "$dmg"
          echo "Installed OpenCode Desktop from .dmg."
          return 0
        fi
        hdiutil detach "$mount" -quiet || true
        rm -f "$dmg"
      fi
    done
  fi
  return 1
}

if [ "$(uname -s)" = "Darwin" ]; then
  if [ -d "/Applications/OpenCode.app" ]; then
    echo "OpenCode Desktop already installed."
  elif command -v brew >/dev/null 2>&1; then
    echo "Installing OpenCode Desktop via Homebrew..."
    if ! brew install --cask opencode-desktop; then
      echo "Homebrew cask failed, trying .dmg fallback..."
      install_desktop_dmg || { echo "ERROR: could not install OpenCode Desktop. Download it from https://opencode.ai/download" >&2; exit 1; }
    fi
  else
    echo "No Homebrew found, installing OpenCode Desktop from .dmg..."
    install_desktop_dmg || { echo "ERROR: could not install OpenCode Desktop. Download it from https://opencode.ai/download" >&2; exit 1; }
  fi
else
  echo "Not macOS — skipping Desktop install (CLI + skill + Zen config still apply)."
fi

# 3. Configure OpenCode for Zen (merge, don't clobber an existing config)
CONFIG_DIR="$HOME/.config/opencode"
CONFIG_FILE="$CONFIG_DIR/opencode.json"
mkdir -p "$CONFIG_DIR"
if [ -f "$CONFIG_FILE" ]; then
  cp "$CONFIG_FILE" "$CONFIG_FILE.bak-$(date +%Y%m%d-%H%M%S)"
  echo "Backed up existing OpenCode config."
fi
CONFIG_FILE="$CONFIG_FILE" python3 - <<'PY'
import json, os
path = os.environ["CONFIG_FILE"]
try:
    with open(path) as f:
        cfg = json.load(f)
except Exception:
    cfg = {}
if not isinstance(cfg, dict):
    cfg = {}
cfg["$schema"] = "https://opencode.ai/config.json"
# Zen free vision model (photos) as default; Zen free flash model as small/fast model.
cfg["model"] = "opencode/nemotron-3.5-super-vl-free"
cfg["small_model"] = "opencode/glm-5.3-flash-free"
with open(path, "w") as f:
    json.dump(cfg, f, indent=2)
    f.write("\n")
print(f"Configured Zen in {path}")
print("  model:       opencode/nemotron-3.5-super-vl-free")
print("  small_model: opencode/glm-5.3-flash-free")
PY

# 4. Photo-carousel skill (embedded, so this works even via curl | bash)
SKILL_DIR="$HOME/.config/opencode/skills/photo-carousel"
mkdir -p "$SKILL_DIR"
cat > "$SKILL_DIR/SKILL.md" <<'SKILL_EOF'
---
name: photo-carousel
description: Make an Instagram carousel from the user's photos. Use when the user asks for a carousel, an Instagram post from photos, or to pick the best photos for a post.
---

# Photo carousel

Make a ready-to-post Instagram carousel from photos. Keep text minimal.

## Steps

1. Find the photos. Use the folder the user points to, or `~/photo-content/photos/`.
   Do not scan an entire multi-year library blindly — if the user has not
   given a theme, date range, or album, ask for one first, then look only
   at matching photos.
2. Pick 5 by default (or the number the user asked for):
   sharp, not duplicated, diverse moments and angles, no blurry or dark
   shots unless the user wants them. Order them as a story:
   hook (strongest slide) → context → detail → peak → closer.
3. Copy, never move or edit, the originals in order to
   `output/carousel-<date>-<theme>/01.jpg`, `02.jpg`, and so on.
   Keep the original filenames in a `manifest.txt` in the same folder.
4. Write `caption.txt` in the same folder: a short hook, 2–3 sentences,
   and a call to action. Add hashtags only if the user asks for them.
5. Text on slides is minimal by default. Only add slide text if the user
   asks, and then keep it to a few words per slide in `slides.md`.
6. Show the user the 5 picks and the caption, and confirm before finishing.

## Instagram notes

- All slides must share one ratio; the first slide sets the crop for all.
- Portrait 1080×1350 is the recommended default, up to 20 slides.
- OpenCode cannot post to Instagram for the user. This package is
  ready to upload in order in the Instagram app.

## Language

Answer and write captions in the language the user writes in.
SKILL_EOF
echo "Installed skill: $SKILL_DIR/SKILL.md"

# 5. Workspace
mkdir -p "$HOME/photo-content/photos" "$HOME/photo-content/output"
printf 'Make a 5-slide Instagram carousel from my photos\n' > "$HOME/photo-content/PROMPT.txt"
echo "Created: ~/photo-content/photos/ (drop photos here)"

# 6. Ask to authenticate with Zen
echo
echo "== Authenticate with Zen =="
echo "Zen is the free model account OpenCode will use (100 requests/day, no card)."
AUTH_ANSWER=""
TTY_MODE="none"
if [ -t 0 ]; then
  TTY_MODE="stdin"
else
  # `tty` reports the controlling terminal, if any, without the shell
  # itself having to open /dev/tty (which errors loudly when there is none).
  TTY_NAME="$(tty 2>/dev/null || true)"
  if [ -n "$TTY_NAME" ] && [ "$TTY_NAME" != "not a tty" ]; then
    exec 3<"$TTY_NAME"
    TTY_MODE="fd3"
  fi
fi
if [ "$TTY_MODE" = "stdin" ]; then
  printf "Authenticate with Zen now? This opens the sign-in in your browser. [Y/n] "
  IFS= read -r AUTH_ANSWER || true
elif [ "$TTY_MODE" = "fd3" ]; then
  printf "Authenticate with Zen now? This opens the sign-in in your browser. [Y/n] " >&2
  IFS= read -r AUTH_ANSWER <&3 || true
else
  echo "No interactive terminal detected — skipping the interactive sign-in."
  echo "Run this yourself afterwards: opencode auth login"
  echo "Then pick OpenCode Zen in the picker (or in Desktop: /connect -> OpenCode Zen)."
  AUTH_ANSWER="n"
fi
case "$AUTH_ANSWER" in
  ""|y|Y|yes|Yes|YES)
    echo "Opening Zen sign-in via: opencode auth login"
    echo "(In the picker, choose OpenCode Zen. If it asks for a key instead, sign up at https://opencode.ai/auth first.)"
    if [ "$TTY_MODE" = "fd3" ]; then
      opencode auth login <&3 || echo "Auth login did not complete — run 'opencode auth login' yourself and pick OpenCode Zen."
    elif [ "$TTY_MODE" = "stdin" ]; then
      opencode auth login || echo "Auth login did not complete — run 'opencode auth login' yourself and pick OpenCode Zen."
    else
      echo "No interactive terminal — run 'opencode auth login' yourself and pick OpenCode Zen."
    fi
    ;;
  *)
    echo "Skipped. Run this yourself afterwards: opencode auth login"
    echo "Then pick OpenCode Zen in the picker (or in Desktop: /connect -> OpenCode Zen)."
    ;;
esac

echo
echo "== Done =="
echo "1. Open OpenCode Desktop, drop photos into ~/photo-content/photos/"
echo "2. Paste this: Make a 5-slide Instagram carousel from my photos"
echo "3. Verify any time with: opencode auth list && opencode models"
echo "Zen free tier: 100 requests/day, no card. No API key needed."
