#!/usr/bin/env bash

set -euo pipefail

source_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
codex_home="${CODEX_HOME:-$HOME/.codex-personal}"
install_dir="$codex_home/workflow-tools"

mkdir -p "$install_dir/hooks" "$install_dir/pending-prompts" "$codex_home/skills"
touch "$install_dir/queue-order.txt"

cp "$source_dir/hooks/codex-workflow-dispatcher.sh" "$install_dir/hooks/"
chmod +x "$install_dir/hooks/codex-workflow-dispatcher.sh"

cp -R "$source_dir/skills/conventional-commit" "$codex_home/skills/"
cp -R "$source_dir/skills/mass-commit" "$codex_home/skills/"

hooks_json="$codex_home/hooks.json"
backup=""
if [ -f "$hooks_json" ]; then
  backup="$hooks_json.bak.$(date -u +%Y%m%d%H%M%S)"
  cp "$hooks_json" "$backup"
fi

command="$install_dir/hooks/codex-workflow-dispatcher.sh"
tmp="$hooks_json.tmp.$$"

if [ -f "$hooks_json" ] && jq -e . "$hooks_json" >/dev/null 2>&1; then
  jq --arg command "$command" '
    .hooks //= {} |
    .hooks.UserPromptSubmit //= [] |
    .hooks.UserPromptSubmit = (
      [.hooks.UserPromptSubmit[] | select(
        ((.hooks // []) | map(.command == $command) | any) | not
      )]
      + [{
        hooks: [{
          type: "command",
          command: $command,
          timeout: 30,
          statusMessage: "Checking workflow command"
        }]
      }]
    )
  ' "$hooks_json" > "$tmp"
else
  jq -n --arg command "$command" '{
    hooks: {
      UserPromptSubmit: [{
        hooks: [{
          type: "command",
          command: $command,
          timeout: 30,
          statusMessage: "Checking workflow command"
        }]
      }]
    }
  }' > "$tmp"
fi

mv "$tmp" "$hooks_json"

printf 'Installed Codex workflow tools to %s\n' "$install_dir"
printf 'Registered dispatcher in %s\n' "$hooks_json"
if [ -n "$backup" ]; then
  printf 'Backup: %s\n' "$backup"
fi
printf 'Ensure %s is included in sandbox_workspace_write.writable_roots if hooks run under workspace-write sandboxing.\n' "$install_dir"
printf 'Restart Codex and use /hooks to review/trust the hook if prompted.\n'
