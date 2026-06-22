# iTerm2 Setup

This directory contains the pieces needed to recreate the current iTerm2 visual
profile more completely than a color preset alone.

Files:

- `prism-theme.itermcolors`: standalone color preset
- `default-profile.plist`: full exported active `Default` profile from iTerm2
- `DynamicProfiles/prism-default.json`: importable iTerm2 Dynamic Profile with
  the full profile settings

## Install Full Profile

The most complete setup is the Dynamic Profile. It includes the color settings,
font, dark/light profile colors, cursor/selection settings, working directory,
terminal type, and other profile-level visual settings.

```sh
mkdir -p "$HOME/Library/Application Support/iTerm2/DynamicProfiles"
cp /Users/dylan/Desktop/projects/workflow-tools/config/iterm2/DynamicProfiles/prism-default.json "$HOME/Library/Application Support/iTerm2/DynamicProfiles/prism-default.json"
```

Restart iTerm2 or open Settings > Profiles and select the imported `Default`
profile.

## Install Color Preset Only

Use this when you only want the colors:

1. Open iTerm2 Settings.
2. Go to Profiles > Colors.
3. Open Color Presets.
4. Import `prism-theme.itermcolors`.
5. Select `prism-theme` for the profile.

The color preset alone does not carry font, working directory, window behavior,
dark/light color variants, or other profile settings.

## What Is Not Stored Here

This directory intentionally does not include the full iTerm2 preferences plist.
That plist contains account/runtime/cache/global application settings that are
not needed for recreating the terminal visual profile.
