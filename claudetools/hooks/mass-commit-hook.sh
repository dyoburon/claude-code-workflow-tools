#!/bin/bash
# Hook for $mass-commit - split changes into logical atomic commits
# Usage: $mass-commit [optional hints about grouping]

input=$(cat)
prompt=$(echo "$input" | jq -r '.prompt')

if [[ "$prompt" =~ ^\$mass-commit ]]; then
    description=""
    if [[ "$prompt" =~ ^\$mass-commit[[:space:]](.+) ]]; then
        description="${BASH_REMATCH[1]}"
    fi

    context="# Mass Commit — Split Changes into Logical Atomic Commits

## Instructions

You have a working directory with many changes. Your job is to **analyze all changes**, **group them by logical theme**, and **create separate commits** for each group — in dependency order.

### Step 1: Analyze
1. Run \`git status\` to see all modified, staged, and untracked files
2. Run \`git diff\` to see unstaged changes (use \`--stat\` first for overview, then read specific files as needed)
3. Run \`git diff --staged\` to see already-staged changes
4. Read new/untracked files to understand their purpose

### Step 2: Plan the Commit Groups
Split changes into **logical, atomic commits** based on theme. Common groupings:
- New module/feature (new files + their integration points)
- Refactors to existing code (restructuring without new behavior)
- Bug fixes
- Dependency/config changes (Cargo.toml, package.json, lock files)
- UI/style changes
- Test files
- Documentation

**Rules for grouping:**
- Each commit should be a coherent, self-contained unit of work
- A commit should not break the build if checked out independently
- Related changes across multiple files belong together (e.g., a new module + its re-export + its IPC handler)
- Dependency changes (lock files, Cargo.toml) go with the feature that needs them, or in a separate chore commit if they serve multiple features
- Prefer 3-7 commits. Don't over-split (1 file per commit) or under-split (everything in 2 commits)
- Order commits so earlier ones don't depend on later ones

### Step 3: Present the Plan
Before committing anything, present a numbered plan like:

\`\`\`
Commit plan:
1. type(scope): summary — [list of files]
2. type(scope): summary — [list of files]
...
\`\`\`

Then ask the user to confirm before proceeding. If the user provided grouping hints, use those to inform (but not blindly follow) the plan.

### Step 4: Execute
For each commit group, in order:
1. Reset the staging area if needed (\`git reset HEAD\` — only if files are incorrectly staged from a prior step)
2. Stage ONLY the files for this commit (\`git add <file1> <file2> ...\` — never \`git add -A\` or \`git add .\`)
3. Create the commit with a conventional commit message

## Conventional Commit Format
\`\`\`
type(scope): short summary of changes

- Bullet point describing a specific change
- Another bullet point for another change
\`\`\`

## Commit Types
- **feat**: New feature or capability
- **fix**: Bug fix
- **refactor**: Code restructuring without behavior change
- **style**: Formatting, CSS changes
- **docs**: Documentation only
- **test**: Adding or updating tests
- **chore**: Build, config, tooling, dependencies
- **perf**: Performance improvement

## Message Rules
- Summary: imperative mood, lowercase, no period, under 72 chars
- Include 3-8 bullet points covering the key changes
- Bullets start with a capital letter, describe WHAT changed and optionally WHY
- Group related changes into single bullets
- Do NOT include \`Co-Authored-By\` in the message
- Pass commit messages via HEREDOC for proper formatting"

    if [ -n "$description" ]; then
        context+="\n\n## User Hints\nThe user provided these hints about how to group the changes: $description\nUse this to inform your grouping plan."
    fi

    escaped_context=$(echo -e "$context" | jq -Rs '.')
    echo "{\"hookSpecificOutput\":{\"hookEventName\":\"UserPromptSubmit\",\"additionalContext\":$escaped_context}}"
    exit 0
fi

exit 0
