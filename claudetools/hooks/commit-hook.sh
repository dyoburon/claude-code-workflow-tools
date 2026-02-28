#!/bin/bash
# Hook for $commit - conventional commit message generator
# Usage: $commit [optional description of what changed]

input=$(cat)
prompt=$(echo "$input" | jq -r '.prompt')

# Handle $commit with optional description
if [[ "$prompt" =~ ^\$commit ]]; then
    # Extract optional user description (everything after "$commit ")
    description=""
    if [[ "$prompt" =~ ^\$commit[[:space:]](.+) ]]; then
        description="${BASH_REMATCH[1]}"
    fi

    context="# Commit with Conventional Commit Format

## Instructions

Create a git commit using the **Conventional Commits** format. Follow these steps:

1. Run \`git status\` and \`git diff --staged\` (and \`git diff\` if nothing is staged) to understand all changes
2. If nothing is staged, stage the relevant changed files (use specific filenames, not \`git add -A\`)
3. Generate a commit message in this exact format:

\`\`\`
type(scope): short summary of changes

- Bullet point describing a specific change
- Another bullet point for another change
- Keep bullets concise but descriptive
\`\`\`

## Commit Types
- **feat**: New feature or capability
- **fix**: Bug fix
- **refactor**: Code restructuring without behavior change
- **style**: Formatting, whitespace, CSS changes
- **docs**: Documentation only
- **test**: Adding or updating tests
- **chore**: Build, config, tooling, dependencies
- **perf**: Performance improvement

## Rules
- **type** is required, **scope** is optional but preferred (use the main area of code changed)
- Summary line should be imperative mood, lowercase, no period, under 72 chars
- Include 3-8 bullet points covering the key changes
- Bullets should start with a capital letter
- Each bullet should describe WHAT changed and optionally WHY
- Group related changes into single bullets rather than listing every file
- Do NOT include \`Co-Authored-By\` in the message"

    if [ -n "$description" ]; then
        context+="\n\n## User Description\nThe user described these changes as: $description\nUse this to inform the commit message but still analyze the actual diff."
    fi

    escaped_context=$(echo -e "$context" | jq -Rs '.')
    echo "{\"hookSpecificOutput\":{\"hookEventName\":\"UserPromptSubmit\",\"additionalContext\":$escaped_context}}"
    exit 0
fi

exit 0
