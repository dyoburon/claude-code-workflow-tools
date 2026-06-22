#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: startup.sh [--dry-run] [DIR]

Open a Ghostty workspace for DIR, defaulting to the current directory.

The workspace opens Ghostty with:
- tab 1: tmux shell grid, 2 rows by 2 columns
- tab 2: lazygit
- tab 3: nvim
EOF
}

dry_run=0
target_dir=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      dry_run=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "startup.sh: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      if [[ -n "$target_dir" ]]; then
        echo "startup.sh: only one directory argument is supported" >&2
        exit 2
      fi
      target_dir="$1"
      shift
      ;;
  esac
done

workdir="${target_dir:-$PWD}"
if [[ ! -d "$workdir" ]]; then
  echo "startup.sh: directory does not exist: $workdir" >&2
  exit 1
fi
workdir="$(cd "$workdir" && pwd -L)"

tmux_bin="$(command -v tmux || true)"
lazygit_bin="$(command -v lazygit || true)"
nvim_bin="$(command -v nvim || true)"
ghostty_app="${GHOSTTY_APP:-/Applications/Ghostty.app}"

if [[ -z "$tmux_bin" ]]; then
  echo "startup.sh: tmux is not on PATH" >&2
  exit 1
fi
if [[ -z "$lazygit_bin" ]]; then
  echo "startup.sh: lazygit is not on PATH" >&2
  exit 1
fi
if [[ -z "$nvim_bin" ]]; then
  echo "startup.sh: nvim is not on PATH" >&2
  exit 1
fi
if [[ ! -d "$ghostty_app" ]]; then
  echo "startup.sh: Ghostty app not found at $ghostty_app" >&2
  echo "Set GHOSTTY_APP=/path/to/Ghostty.app if it is installed elsewhere." >&2
  exit 1
fi

base="$(basename "$workdir" | tr -c '[:alnum:]_-' '-' | sed 's/^-*//; s/-*$//')"
base="${base:-workspace}"
checksum="$(printf '%s' "$workdir" | cksum | awk '{print $1}')"
session="ws-shell-${base}-${checksum}"

if [[ "$dry_run" -eq 1 ]]; then
  cat <<EOF
workdir: $workdir
session: $session
tmux: $tmux_bin
lazygit: $lazygit_bin
nvim: $nvim_bin
ghostty: $ghostty_app
EOF
  exit 0
fi

if ! "$tmux_bin" has-session -t "$session" 2>/dev/null; then
  "$tmux_bin" new-session -d -s "$session" -c "$workdir" -n shell
  "$tmux_bin" split-window -h -t "$session:shell.0" -c "$workdir"
  "$tmux_bin" split-window -v -t "$session:shell.0" -c "$workdir"
  "$tmux_bin" split-window -v -t "$session:shell.1" -c "$workdir"
  "$tmux_bin" select-layout -t "$session:shell" tiled
  "$tmux_bin" select-pane -t "$session:shell.0"
fi

printf -v tmux_cmd 'cd %q && exec %q attach-session -t %q' "$workdir" "$tmux_bin" "$session"
printf -v lazygit_cmd 'cd %q && exec %q' "$workdir" "$lazygit_bin"
printf -v nvim_cmd 'cd %q && exec %q' "$workdir" "$nvim_bin"

open "$ghostty_app"

ghostty_pid=""
for _ in {1..40}; do
  ghostty_pid="$(osascript <<'APPLESCRIPT' 2>/dev/null || true
tell application "Ghostty" to activate
delay 0.1
tell application "System Events"
  repeat with ghosttyProcess in (processes whose name is "Ghostty")
    if frontmost of ghosttyProcess is true then
      return unix id of ghosttyProcess
    end if
  end repeat
end tell
APPLESCRIPT
)"
  if [[ -n "$ghostty_pid" ]]; then
    break
  fi
  sleep 0.1
done

if [[ -z "$ghostty_pid" ]]; then
  echo "startup.sh: could not find the Ghostty process after launch" >&2
  exit 1
fi

run_in_front_ghostty_tab() {
  local command_text="$1"

  printf '%s' "$command_text" | pbcopy

  osascript <<APPLESCRIPT
tell application "System Events"
  set ghosttyProcess to first process whose unix id is $ghostty_pid
  set frontmost of ghosttyProcess to true
  tell ghosttyProcess
    keystroke "v" using command down
    key code 36
  end tell
end tell
APPLESCRIPT
}

new_ghostty_tab() {
  local command_text="$1"

  osascript <<APPLESCRIPT
tell application "System Events"
  set ghosttyProcess to first process whose unix id is $ghostty_pid
  set frontmost of ghosttyProcess to true
  tell ghosttyProcess to keystroke "t" using command down
end tell
APPLESCRIPT

  sleep 0.3
  run_in_front_ghostty_tab "$command_text"
}

previous_clipboard="$(pbpaste 2>/dev/null || true)"
restore_clipboard() {
  printf '%s' "$previous_clipboard" | pbcopy 2>/dev/null || true
}
trap restore_clipboard EXIT

sleep 1.4
run_in_front_ghostty_tab "$tmux_cmd"
sleep 0.3
new_ghostty_tab "$lazygit_cmd"
new_ghostty_tab "$nvim_cmd"
restore_clipboard
trap - EXIT
