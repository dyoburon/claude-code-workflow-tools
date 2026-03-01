# Image to Clipboard for Claude

Takes an interactive screenshot and copies the **file path** to your clipboard, ready to paste into Claude Code or any tool that accepts file paths.

Available for **macOS** (Hammerspoon) and **Windows** (AutoHotkey v2).

---

## macOS (Hammerspoon)

### Requirements

- [Hammerspoon](https://www.hammerspoon.org/) (`brew install --cask hammerspoon`)

### Install

Add to your Hammerspoon config:

```bash
# From the workflow-tools repo
cat image-to-clipboard-for-claude/init.lua >> ~/.hammerspoon/init.lua
```

Or if you use Spoons/require, copy `init.lua` into your Hammerspoon config and `require` it.

Then reload Hammerspoon (`Cmd+Option+R` or click Reload Config).

### Usage

| Hotkey | Action |
|--------|--------|
| `Cmd+Option+S` | Take interactive screenshot, copy file path to clipboard |

1. Press `Cmd+Option+S`
2. Select a region on screen (or press Space to capture a full window)
3. The screenshot is saved to `~/Documents/Screenshots/`
4. The file path is copied to your clipboard
5. Paste the path into Claude Code or any other tool

---

## Windows (AutoHotkey v2)

### Requirements

- [AutoHotkey v2](https://www.autohotkey.com/) — download and install the v2 release

### Install

1. Copy `screenshot-to-clipboard.ahk` somewhere convenient (e.g. `Documents\Scripts\`)
2. Double-click the `.ahk` file to run it
3. **Optional — run on startup:** press `Win+R`, type `shell:startup`, and place a shortcut to the `.ahk` file in that folder

### Usage

| Hotkey | Action |
|--------|--------|
| `Ctrl+Alt+S` | Take interactive screenshot, copy file path to clipboard |

1. Press `Ctrl+Alt+S`
2. The Snipping Tool overlay appears — select a region
3. The screenshot is saved to `Documents\Screenshots\screenshot_YYYY-MM-DD_HH-MM-SS.png`
4. The file path is copied to your clipboard
5. Paste the path into Claude Code or any other tool

If you press Escape or don't select a region within 30 seconds, the operation is cancelled gracefully.

---

## How it works

Both scripts follow the same pattern:

1. Trigger an interactive screen-capture tool (macOS `screencapture` / Windows Snipping Tool)
2. Save the captured image as a timestamped PNG in `Documents/Screenshots/`
3. Copy the **file path** (not the image) to the clipboard
