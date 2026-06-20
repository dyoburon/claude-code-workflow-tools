#!/usr/bin/env bash
# Codex UserPromptSubmit dispatcher for Claude Code-style workflow commands.

set -euo pipefail

input=$(cat)

prompt=$(
  printf '%s' "$input" | jq -r '
    .prompt
    // .user_prompt
    // .message
    // .payload.prompt
    // .payload.message
    // .input
    // empty
  ' 2>/dev/null || true
)

if [ -z "$prompt" ]; then
  exit 0
fi

if [ -n "${CODEX_WORKFLOW_HOME:-}" ]; then
  workflow_home="$CODEX_WORKFLOW_HOME"
elif [ -n "${CODEX_HOME:-}" ]; then
  workflow_home="$CODEX_HOME/workflow-tools"
elif [ -d "$HOME/.codex-personal" ]; then
  workflow_home="$HOME/.codex-personal/workflow-tools"
else
  workflow_home="$HOME/.codex/workflow-tools"
fi

pending_dir="$workflow_home/pending-prompts"
queue_file="$workflow_home/queue-order.txt"

json_string() {
  jq -Rs '.'
}

block_prompt() {
  local reason="$1"
  local escaped
  escaped=$(printf '%s' "$reason" | json_string)
  printf '{"decision":"block","reason":%s}\n' "$escaped"
  exit 0
}

inject_context() {
  local context="$1"
  local escaped
  escaped=$(printf '%s' "$context" | json_string)
  printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":%s}}\n' "$escaped"
  exit 0
}

validate_name() {
  local name="$1"
  if [ -z "$name" ] || [[ ! "$name" =~ ^[A-Za-z0-9._-]+$ ]]; then
    block_prompt "Invalid name '$name'. Use only letters, numbers, dots, underscores, and hyphens."
  fi
}

ensure_storage() {
  mkdir -p "$pending_dir"
  touch "$queue_file"
}

write_prompt_file() {
  local name="$1"
  local content="$2"
  mkdir -p "$pending_dir"
  local file="$pending_dir/$name.txt"
  local tmp="$file.tmp.$$"
  printf '%s\n' "$content" > "$tmp"
  mv "$tmp" "$file"
}

available_prompts() {
  if [ ! -d "$pending_dir" ]; then
    printf 'none'
    return
  fi

  local files=()
  local file
  shopt -s nullglob
  files=("$pending_dir"/*.txt)
  shopt -u nullglob

  if [ "${#files[@]}" -eq 0 ]; then
    printf 'none'
    return
  fi

  local out=""
  for file in "${files[@]}"; do
    if [ -n "$out" ]; then
      out+=", "
    fi
    out+="$(basename "$file" .txt)"
  done
  printf '%s' "$out"
}

queue_count() {
  if [ ! -s "$queue_file" ]; then
    printf '0'
    return
  fi
  wc -l < "$queue_file" | tr -d ' '
}

pop_queue_name() {
  local name
  name=$(head -n 1 "$queue_file")
  local tmp="$queue_file.tmp.$$"
  tail -n +2 "$queue_file" > "$tmp" 2>/dev/null || true
  mv "$tmp" "$queue_file"
  printf '%s' "$name"
}

commit_context() {
  local description="$1"
  local context
  context=$(cat <<'EOF'
# Commit with Conventional Commit Format

## Instructions

Create a git commit using the Conventional Commits format. Follow these steps:

1. Run `git status` and `git diff --staged` (and `git diff` if nothing is staged) to understand all changes
2. If nothing is staged, stage the relevant changed files using specific filenames, not `git add -A`
3. Generate a commit message in this exact format:

```text
type(scope): short summary of changes

- Bullet point describing a specific change
- Another bullet point for another change
- Keep bullets concise but descriptive
```

## Commit Types

- feat: New feature or capability
- fix: Bug fix
- refactor: Code restructuring without behavior change
- style: Formatting, whitespace, CSS changes
- docs: Documentation only
- test: Adding or updating tests
- chore: Build, config, tooling, dependencies
- perf: Performance improvement

## Rules

- type is required, scope is optional but preferred
- Summary line should be imperative mood, lowercase, no period, under 72 chars
- Include 3-8 bullet points covering the key changes
- Bullets should start with a capital letter
- Each bullet should describe what changed and optionally why
- Group related changes into single bullets rather than listing every file
- Do not include Co-Authored-By
EOF
)
  if [ -n "$description" ]; then
    context+="

## User Description

The user described these changes as: $description

Use this to inform the commit message, but still analyze the actual diff."
  fi
  printf '%s' "$context"
}

mass_commit_context() {
  local hints="$1"
  local context
  context=$(cat <<'EOF'
# Mass Commit: Split Changes into Logical Atomic Commits

## Instructions

You have a working directory with many changes. Analyze all changes, group them by logical theme, and create separate commits for each group in dependency order.

## Step 1: Analyze

1. Run `git status` to see all modified, staged, and untracked files
2. Run `git diff --stat`, then inspect specific unstaged changes with `git diff`
3. Run `git diff --staged` to inspect staged changes
4. Read new or untracked files to understand their purpose

## Step 2: Plan Commit Groups

Split changes into logical, atomic commits based on theme:

- New module or feature
- Refactor without behavior change
- Bug fix
- Dependency or config changes
- UI or style changes
- Tests
- Documentation

Rules:

- Each commit should be coherent and self-contained
- A commit should not break the build if checked out independently
- Related changes across multiple files belong together
- Prefer 3-7 commits unless the change set clearly calls for fewer or more
- Order commits so earlier commits do not depend on later ones

## Step 3: Present the Plan

Before committing anything, present a numbered plan:

```text
Commit plan:
1. type(scope): summary - files
2. type(scope): summary - files
```

Ask the user to confirm before proceeding.

## Step 4: Execute

For each confirmed commit group:

1. Reset the staging area only if files are incorrectly staged from a prior step
2. Stage only the files for that commit using specific paths
3. Create the commit with a conventional commit message

Do not use `git add -A` or `git add .`.
Do not include Co-Authored-By.
EOF
)
  if [ -n "$hints" ]; then
    context+="

## User Hints

The user provided these hints about grouping: $hints

Use this to inform your grouping plan, but still analyze the actual diff."
  fi
  printf '%s' "$context"
}

# 1. $sendqueue
if [[ "$prompt" =~ ^\$sendqueue([[:space:]]|$) ]]; then
  ensure_storage
  if [ ! -s "$queue_file" ]; then
    block_prompt "Queue is empty."
  fi

  name=$(pop_queue_name)
  validate_name "$name"
  file="$pending_dir/$name.txt"
  if [ ! -f "$file" ]; then
    remaining=$(queue_count)
    block_prompt "Queue item '$name' not found (file missing). Removed from queue.

Remaining in queue: $remaining"
  fi

  content=$(cat "$file")
  rm "$file"
  remaining=$(queue_count)
  next=$(head -n 1 "$queue_file" 2>/dev/null || true)
  if [ -n "$next" ]; then
    queue_info="Next in queue: $next ($remaining remaining)"
  else
    queue_info="Queue is now empty."
  fi

  inject_context "Executing queued prompt '$name':

$content

---
$queue_info"
fi

# 2. $send <name>
if [[ "$prompt" =~ ^\$send[[:space:]] ]]; then
  name="${prompt#\$send }"
  name="${name%% *}"
  validate_name "$name"
  file="$pending_dir/$name.txt"

  if [ ! -f "$file" ]; then
    block_prompt "Pending prompt '$name' not found.

Available: $(available_prompts)"
  fi

  content=$(cat "$file")
  rm "$file"
  inject_context "The user wants you to execute this saved prompt:

$content"
fi

# 3. $pending <name> <prompt>
if [[ "$prompt" =~ ^\$pending[[:space:]] ]]; then
  args="${prompt#\$pending }"
  name="${args%% *}"
  content="${args#* }"

  validate_name "$name"
  if [ "$name" = "$content" ] || [ -z "$content" ]; then
    block_prompt 'Usage: $pending <name> <prompt>'
  fi

  write_prompt_file "$name" "$content"
  block_prompt "Saved pending prompt: $name

Execute with: \$send $name"
fi

# 4. $queue-list
if [[ "$prompt" == "\$queue-list" ]]; then
  ensure_storage
  if [ ! -s "$queue_file" ]; then
    block_prompt 'Queue is empty.

Add items with: $queue <name> <prompt>'
  fi

  output="Queue Contents:
-------------------------------------------------
"
  position=1
  while IFS= read -r name; do
    file="$pending_dir/$name.txt"
    if [ -f "$file" ]; then
      preview=$(head -c 50 "$file" | tr '\n' ' ')
      if [ "${#preview}" -eq 50 ]; then
        preview="${preview}..."
      fi
      output+="  $position. $name: $preview
"
    else
      output+="  $position. $name: (file missing)
"
    fi
    position=$((position + 1))
  done < "$queue_file"

  output+="
Run next with: \$sendqueue"
  block_prompt "$output"
fi

# 5. $queue <name> <prompt>
if [[ "$prompt" =~ ^\$queue[[:space:]] ]]; then
  args="${prompt#\$queue }"
  name="${args%% *}"
  content="${args#* }"

  validate_name "$name"
  if [ "$name" = "$content" ] || [ -z "$content" ]; then
    block_prompt 'Usage: $queue <name> <prompt>'
  fi

  ensure_storage
  write_prompt_file "$name" "$content"
  printf '%s\n' "$name" >> "$queue_file"
  position=$(queue_count)
  block_prompt "Queued: $name (position $position)

Run next with: \$sendqueue"
fi

# 6. $cc family placeholders
if [[ "$prompt" == "\$cc-list" ]]; then
  block_prompt 'Codex checkpoint commands are not enabled yet.

Use Codex-native /resume, codex resume, or codex fork for now.'
fi

if [[ "$prompt" =~ ^\$cc-resume([[:space:]]|$) || "$prompt" =~ ^\$cc([[:space:]]|$) || "$prompt" == "\$cc" ]]; then
  block_prompt 'Codex checkpoint commands are not enabled yet.

Use Codex-native /resume, codex resume, or codex fork for now.'
fi

# 7. $mass-commit [hints]
if [[ "$prompt" =~ ^\$mass-commit([[:space:]]|$) ]]; then
  hints=""
  if [[ "$prompt" =~ ^\$mass-commit[[:space:]](.+) ]]; then
    hints="${BASH_REMATCH[1]}"
  fi
  inject_context "$(mass_commit_context "$hints")"
fi

# 8. $commit [description]
if [[ "$prompt" =~ ^\$commit([[:space:]]|$) ]]; then
  description=""
  if [[ "$prompt" =~ ^\$commit[[:space:]](.+) ]]; then
    description="${BASH_REMATCH[1]}"
  fi
  inject_context "$(commit_context "$description")"
fi

exit 0
