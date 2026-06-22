# LazyGit Setup

This directory contains the LazyGit config from:

```sh
~/Library/Application Support/lazygit/config.yml
```

The setup configures LazyGit to use `delta` with the `Monokai Extended` syntax
theme for paging.

## Prerequisites

```sh
brew install lazygit git-delta
```

## Install

LazyGit reports the active config directory with:

```sh
lazygit --print-config-dir
```

On this machine that path is `~/Library/Application Support/lazygit`. Install
the checked-in config there:

```sh
mkdir -p "$HOME/Library/Application Support/lazygit"
cp /Users/dylan/Desktop/projects/workflow-tools/config/lazygit/config.yml "$HOME/Library/Application Support/lazygit/config.yml"
```

If LazyGit is configured to use the XDG path on another machine, install it at:

```sh
mkdir -p ~/.config/lazygit
cp /Users/dylan/Desktop/projects/workflow-tools/config/lazygit/config.yml ~/.config/lazygit/config.yml
```
