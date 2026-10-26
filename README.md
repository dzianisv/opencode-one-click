# OpenCode one-click setup (MacBook)

One line in Terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/dzianisv/opencode-one-click/main/install.sh | bash
```

What it installs and configures:

1. OpenCode CLI (if missing).
2. OpenCode Desktop on macOS — via Homebrew cask, with a `.dmg` fallback.
3. OpenCode configured for Zen by default:
   - `opencode/nemotron-3.5-super-vl-free` (vision, for photos)
   - `opencode/glm-5.3-flash-free` (small/fast model)
4. The `photo-carousel` skill to `~/.config/opencode/skills/photo-carousel/`.
5. A `~/photo-content/` workspace with `photos/` and `output/`.
6. Zen authentication — the script asks, then runs `opencode auth login`
   (pick OpenCode Zen in the picker). No API key needed.

Afterwards, in OpenCode Desktop:

1. Drop photos into `~/photo-content/photos/`.
2. Paste: `Make a 5-slide Instagram carousel from my photos`

Zen free tier: 100 requests/day, no card. OpenCode cannot post to
Instagram for you — the carousel package it builds is ready to upload
in order in the Instagram app.

Review `install.sh` before piping it to bash, as with any installer.
