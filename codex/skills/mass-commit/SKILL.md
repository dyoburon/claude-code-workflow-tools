---
name: mass-commit
description: Split a large working tree into logical atomic conventional commits.
---

Analyze the working tree, group changes into logical atomic commits, and commit them in dependency order.

1. Run `git status`.
2. Run `git diff --stat`, then inspect specific files with `git diff`.
3. Run `git diff --staged`.
4. Read untracked files that may belong in commits.

Plan commit groups before committing:

- Group by logical theme, not by individual file.
- Keep each commit coherent and self-contained.
- Preserve buildability where practical.
- Put dependency/config changes with the feature that needs them unless they support multiple groups.
- Prefer 3-7 commits unless the change set clearly calls for fewer or more.
- Order commits so earlier commits do not depend on later commits.

Before committing, present:

```text
Commit plan:
1. type(scope): summary - files
2. type(scope): summary - files
```

Ask the user to confirm before proceeding.

For each confirmed group, stage only the files for that commit using explicit paths. Do not use `git add -A` or `git add .`. Use conventional commit messages and do not include `Co-Authored-By`.
