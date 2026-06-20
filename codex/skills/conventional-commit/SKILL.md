---
name: conventional-commit
description: Create a git commit using a conventional commit message after inspecting the working tree.
---

Create a git commit using the Conventional Commits format.

1. Run `git status` and inspect staged changes with `git diff --staged`.
2. If nothing is staged, inspect unstaged changes with `git diff`.
3. Stage only the relevant files using explicit filenames. Do not use `git add -A` or `git add .`.
4. Commit with this format:

```text
type(scope): short summary of changes

- Bullet point describing a specific change
- Another bullet point for another change
```

Use these commit types: `feat`, `fix`, `refactor`, `style`, `docs`, `test`, `chore`, `perf`.

Rules:

- `type` is required; `scope` is optional but preferred.
- Keep the summary imperative, lowercase, under 72 characters, and without a period.
- Include 3-8 concise bullets.
- Start bullets with a capital letter.
- Describe what changed and optionally why.
- Group related changes instead of listing every file.
- Do not include `Co-Authored-By`.
