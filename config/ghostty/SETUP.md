# Ghostty Setup

This directory is an installable Ghostty config. It includes:

- `config.ghostty`, the current Ghostty config filename
- `config`, the legacy Ghostty config filename
- `themes/prism-theme`, the same custom prism colors as a reusable theme file

Both config files inline the font and color settings. The color values are
duplicated intentionally: Ghostty does not resolve `theme = prism-theme` from an
arbitrary repo checkout, so inlining avoids a setup where the theme silently
fails to load.

## Install

Use the XDG config path, which Ghostty supports on macOS and Linux:

```sh
mkdir -p ~/.config
ln -sfn /Users/dylan/Desktop/projects/workflow-tools/config/ghostty ~/.config/ghostty
```

Or copy it instead of symlinking:

```sh
mkdir -p ~/.config
cp -R /Users/dylan/Desktop/projects/workflow-tools/config/ghostty ~/.config/ghostty
```

Ghostty 1.2.3 and newer use `config.ghostty`. Older Ghostty versions used
`config`. Both files are checked in here.

## macOS Override

On macOS, Ghostty also reads:

```sh
~/Library/Application Support/com.mitchellh.ghostty/config.ghostty
~/Library/Application Support/com.mitchellh.ghostty/config
```

Those macOS-specific files are loaded after the XDG config and can override it.
If the theme does not apply, replace the macOS-specific config with this setup:

```sh
mkdir -p "$HOME/Library/Application Support/com.mitchellh.ghostty/themes"
cp /Users/dylan/Desktop/projects/workflow-tools/config/ghostty/config.ghostty "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"
cp /Users/dylan/Desktop/projects/workflow-tools/config/ghostty/config "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
cp /Users/dylan/Desktop/projects/workflow-tools/config/ghostty/themes/prism-theme "$HOME/Library/Application Support/com.mitchellh.ghostty/themes/prism-theme"
```

Reload Ghostty with `cmd+shift+,` or restart Ghostty.

## Known Difference From iTerm2

iTerm2 stores the selection background with alpha `0.3`. Ghostty 1.3.1 rejects
8-digit hex alpha values for `selection-background`, so this config uses the
closest opaque color, `#3186d3`.
