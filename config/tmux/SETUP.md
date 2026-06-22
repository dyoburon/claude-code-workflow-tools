# tmux Setup

This directory contains the active tmux config from:

```sh
~/.tmux.conf
```

The config enables mouse support, increases scrollback history, and tunes mouse
wheel scrolling in normal and copy modes.

## Prerequisites

```sh
brew install tmux
```

This config was checked with `tmux 3.6a`.

## Install

Symlink the checked-in config:

```sh
ln -sfn /Users/dylan/Desktop/projects/workflow-tools/config/tmux/.tmux.conf ~/.tmux.conf
```

Or copy it:

```sh
cp /Users/dylan/Desktop/projects/workflow-tools/config/tmux/.tmux.conf ~/.tmux.conf
```

Reload inside tmux:

```sh
tmux source-file ~/.tmux.conf
```
