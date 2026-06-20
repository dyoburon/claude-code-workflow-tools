#!/bin/bash
# Workflow Tools - Quick Start
#
# This repo contains multiple independent tools.
# Each has its own installer - run the one you want:
#
#   ./claudetools/install.sh     - Claude Code hooks & statusline
#   ./codex/install.sh           - Codex workflow hooks
#   ./hammerspoon-install.sh     - macOS window tools (Hammerspoon)
#
# Or run this script for an interactive menu.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "Workflow Tools"
echo "=============="
echo ""
echo "Available installers:"
echo ""
echo "  1) Claude Code Tools    ./claudetools/install.sh"
echo "     Hooks, statusline, checkpoints for Claude Code CLI"
echo ""
echo "  2) Codex Tools          ./codex/install.sh"
echo "     Claude-style workflow hooks for Codex"
echo ""
echo "  3) Hammerspoon Tools    ./hammerspoon-install.sh"
echo "     Force alt-tab + window recorder (macOS only)"
echo ""
echo "  4) All"
echo ""
read -p "Select [1-4] or press Enter to exit: " choice

case $choice in
    1)
        "$SCRIPT_DIR/claudetools/install.sh"
        ;;
    2)
        "$SCRIPT_DIR/codex/install.sh"
        ;;
    3)
        "$SCRIPT_DIR/hammerspoon-install.sh"
        ;;
    4)
        "$SCRIPT_DIR/claudetools/install.sh"
        echo ""
        "$SCRIPT_DIR/codex/install.sh"
        echo ""
        "$SCRIPT_DIR/hammerspoon-install.sh"
        ;;
    *)
        echo ""
        echo "Run individual installers directly:"
        echo "  ./claudetools/install.sh"
        echo "  ./codex/install.sh"
        echo "  ./hammerspoon-install.sh"
        ;;
esac
