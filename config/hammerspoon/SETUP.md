# Hammerspoon Setup

This directory mirrors the active Hammerspoon config currently linked from:

```sh
~/.hammerspoon -> /Users/dylan/Desktop/projects/hammerspoon
```

It includes the files needed by the current setup:

- `init.lua`, the active Hammerspoon config
- `window-positions.json`, saved window recorder slots
- `nvim-cheatsheet.html`, used by the cheatsheet popup
- `Spoons/`, kept as a placeholder for future Spoons

## Prerequisites

Install Hammerspoon:

```sh
brew install --cask hammerspoon
```

The config expects this repo at:

```sh
/Users/dylan/Desktop/projects/workflow-tools
```

It reads DOM extractor assets from `dom-for-llm-extractor/` in that checkout.

Optional integrations used by parts of `init.lua`:

- Ghostty at `/Applications/Ghostty.app`
- OBS with WebSocket on port `4455`
- VibeToText at `~/Desktop/projects/vibetotext`

## Install

Symlink this config as the Hammerspoon config directory:

```sh
ln -sfn /Users/dylan/Desktop/projects/workflow-tools/config/hammerspoon ~/.hammerspoon
```

Or copy it if you want an independent local config:

```sh
mv ~/.hammerspoon ~/.hammerspoon.backup
cp -R /Users/dylan/Desktop/projects/workflow-tools/config/hammerspoon ~/.hammerspoon
```

Then open Hammerspoon and reload the config from the menu bar icon.

## macOS Permissions

Grant Hammerspoon the permissions needed by the active config:

- Accessibility, for hotkeys and window movement
- Screen Recording, for pixel/color capture
- Automation, for browser AppleScript actions

## Notes

The root `hammerspoon-install.sh` in this repo is an older generated installer.
This directory is the current full config snapshot.
