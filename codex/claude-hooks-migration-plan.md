# Claude Hook Migration Plan for Codex

## Goal

Bring the useful Claude Code workflow hooks from `claudetools` into a Codex-friendly toolset without assuming Claude's hook output contract works unchanged in Codex.

The source hooks are in:

- `../claudetools/hooks/`
- `../claudetools/commands/`
- `../claudetools/statusline/`
- `../claudetools/settings.example.json`

Local Codex facts checked during planning:

- Installed CLI: `codex-cli 0.136.0`
- User config: `~/.codex/config.toml`
- Session transcripts: `~/.codex/sessions/YYYY/MM/DD/*.jsonl`
- Codex hooks are documented in the current Codex manual under `Hooks` and `Advanced Configuration`.

## Source Inventory

| Source | Current Claude behavior | Migration value | Initial decision |
| --- | --- | --- | --- |
| `hooks/dispatcher-hook.sh` | Single `UserPromptSubmit` hook that runs enabled hooks in order. | High, because Codex runs multiple matching command hooks concurrently. | Port first as the Codex dispatcher pattern. |
| `hooks/pending-hook.sh` | `$pending <name> <prompt>` stores a prompt. | High. | Port after validating Codex prompt hook output. |
| `hooks/send-hook.sh` | `$send <name>` injects stored prompt and deletes it. | High. | Port with Codex-specific output contract. |
| `hooks/queue-hook.sh` | `$queue`, `$queue-list` manage ordered prompt queue. | High. | Port after pending/send. |
| `hooks/sendqueue-hook.sh` | `$sendqueue` pops and injects next queued prompt. | High. | Port after pending/send. |
| `hooks/cc-hook.sh` | `$cc`, `$cc-resume`, `$cc-list` checkpoint Claude session JSONL. | Medium. Codex already has `/resume` and `codex fork`, but named checkpoints can still help. | Spike after prompt injection is proven. |
| `commands/cc-fast.sh` | Finds latest Claude session file for current project and copies it. | Medium. Needs Codex transcript layout support. | Rebuild for `~/.codex/sessions`, not copy verbatim. |
| `hooks/commit-hook.sh` | `$commit` injects conventional commit instructions. | High, but does not require a hook. | Prefer a Codex skill or prompt; optionally wire `$commit` through dispatcher. |
| `hooks/mass-commit-hook.sh` | `$mass-commit` injects atomic commit planning instructions. | High, but does not require a hook. | Prefer a Codex skill or prompt; optionally wire `$mass-commit` through dispatcher. |
| `hooks/pending-handler.sh` | Older combined pending/send handler. | Low. | Do not port. Its JSON escaping is less robust than split hooks. |
| `statusline/statusline.sh` | Claude statusline with model/context/git/duration. | Low. Codex has native `/statusline`, `/status`, and `/usage`. | Do not port initially. Document native replacement. |
| `install.sh` and `settings.example.json` | Copies scripts to `~/.claude` and registers hooks. | Medium. | Replace with Codex installer and `hooks.example.json`. |

## Codex Constraints That Change the Design

1. Codex loads hooks from `~/.codex/hooks.json`, `~/.codex/config.toml`, project `.codex/hooks.json`, or inline project `.codex/config.toml`.
2. Project-local hooks require the project to be trusted.
3. Non-managed command hooks must be reviewed and trusted via `/hooks` before running.
4. Multiple matching command hooks for the same event are launched concurrently. That means separate `$pending`, `$send`, `$queue`, and `$commit` hooks can race or all run for one prompt.
5. `UserPromptSubmit` ignores `matcher`, so filtering must happen inside our script.
6. Command hooks run with the session `cwd`.
7. Codex documents `UserPromptSubmit`, but the manual section reviewed here does not establish that Claude's `{"decision":"block"}` and `{"hookSpecificOutput":...}` output shapes are accepted unchanged. Validate that before a direct port.
8. Custom prompts are deprecated in favor of skills for reusable instructions. Commit helpers should probably become Codex skills even if we keep `$commit` compatibility.

## Target Shape

Create a small Codex workflow tools package in this directory:

```text
codex/
  claude-hooks-migration-plan.md
  hooks/
    codex-workflow-dispatcher.sh
  skills/
    conventional-commit/SKILL.md
    mass-commit/SKILL.md
  examples/
    hooks.example.json
    config.example.toml
  install.sh
  tests/
    fixtures/
    run-hook-tests.sh
```

Use one `UserPromptSubmit` dispatcher in Codex. The dispatcher should parse the prompt once, run command handlers in a fixed order, and stop after the first match.

Suggested command priority:

1. `$sendqueue`
2. `$send`
3. `$pending`
4. `$queue-list`
5. `$queue`
6. `$cc-list`
7. `$cc-resume`
8. `$cc`
9. `$mass-commit`
10. `$commit`

Store Codex workflow data under `~/.codex/workflow-tools/`, not `~/.claude/`:

```text
~/.codex/workflow-tools/
  pending-prompts/
  queue-order.txt
  checkpoints/
```

## Phase 1: Prove the Codex Hook Contract

Build a disposable probe hook before porting real behavior.

What to verify:

- The exact JSON fields Codex sends to `UserPromptSubmit`.
- Whether a hook can block a prompt and show a reason.
- Whether a hook can add or replace prompt context.
- Whether stdout text is treated as context, ignored, or shown as diagnostics.
- What exit codes do for pass, block, and error cases.
- How trust review behaves for a project-local hook in this repo.

Probe plan:

1. Add a temporary `hooks/probe-user-prompt.sh` that writes stdin to `/tmp/codex-hook-probe.jsonl` and returns one test output at a time.
2. Register it with `examples/hooks.probe.json`.
3. Start Codex from a trusted test repo using `--dangerously-bypass-hook-trust` only for the probe run.
4. Test prompts: normal text, `$pending test hello`, `$send test`, `$commit`.
5. Record accepted input and output contracts in `docs/codex-hook-contract.md`.

Do not implement real ports until this is done.

## Phase 2: Port Pending and Queue

Port these first because they are self-contained and provide the highest day-to-day value:

- `$pending <name> <prompt>`
- `$send <name>`
- `$queue <name> <prompt>`
- `$queue-list`
- `$sendqueue`

Implementation notes:

- Use `jq` for JSON parsing and output escaping, as the Claude hooks already do.
- Sanitize names with a stricter allowlist, for example `^[A-Za-z0-9._-]+$`.
- Use atomic writes: write to a temp file, then `mv`.
- Keep queue operations serialized inside the single dispatcher.
- On missing prompts, return a clear list of available names.
- If Codex cannot inject prompt context from hooks, degrade to a block message that tells the user the stored prompt and command to paste or run through `codex exec`.

Tests:

- `$pending` saves exact multiline content.
- `$send` returns executable context and deletes the file.
- Missing `$send` lists available prompts.
- `$queue` appends in order.
- `$sendqueue` pops one item and preserves remaining order.
- Invalid names are rejected.

## Phase 3: Convert Commit Helpers to Skills

Port `commit-hook.sh` and `mass-commit-hook.sh` as Codex skills first:

- `skills/conventional-commit/SKILL.md`
- `skills/mass-commit/SKILL.md`

Why:

- The current hooks only inject instructions.
- Codex already has a skill surface for reusable workflows.
- Skills are easier to trust and inspect than prompt interception hooks.

Optional compatibility:

- Keep `$commit [description]` and `$mass-commit [hints]` in the dispatcher after hook prompt injection is proven.
- The dispatcher can inject the same skill-like instructions for users who prefer the old `$` commands.

Tests:

- Skill text includes the same conventional commit rules.
- `$commit` compatibility, if enabled, preserves optional user description.
- `$mass-commit` compatibility asks for confirmation before creating commits.

## Phase 4: Rebuild Checkpoints for Codex

Do not copy the Claude checkpoint implementation directly. Rebuild it around Codex's transcript layout and native session commands.

Codex-native alternatives to preserve:

- `/resume` resumes saved conversations.
- `codex resume` resumes previous sessions.
- `codex fork` branches prior sessions.

Named checkpoint behavior to consider porting:

- `$cc <name>` copies the latest Codex session JSONL for the current `cwd` into `~/.codex/workflow-tools/checkpoints/`.
- `$cc-list` lists named checkpoints with created date, size, source session id, and `cwd`.
- `$cc-resume <name>` either injects a checkpoint summary or points the user to `codex resume`/`codex fork` if direct context injection is not supported.

Implementation notes:

- Find candidates under `~/.codex/sessions/YYYY/MM/DD/*.jsonl`.
- Parse the first `session_meta` line and match `payload.cwd` to the current working directory.
- Pick the newest matching transcript by mtime.
- Save metadata as `<name>.meta.json`.
- Avoid copying sensitive auth or unrelated state.
- Limit raw injected context. Prefer summary generation if the transcript is large.

Tests:

- Correctly selects newest transcript for the current `cwd`.
- Ignores transcripts from other projects.
- Stores metadata with source session id and size.
- `$cc-list` handles no checkpoints.
- `$cc-resume` handles missing checkpoint.

## Phase 5: Installer and Packaging

Create an installer that supports two modes:

1. User-level install:
   - Copy hooks and commands to `~/.codex/workflow-tools/`.
   - Add or print a `~/.codex/hooks.json` snippet.
   - Ask the user to review/trust the hook with `/hooks`.

2. Repo-local install:
   - Copy hooks into `.codex/hooks/`.
   - Add `.codex/hooks.json`.
   - Require project trust.

Example `hooks.json` shape:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/.codex/workflow-tools/hooks/codex-workflow-dispatcher.sh",
            "timeout": 30,
            "statusMessage": "Checking workflow command"
          }
        ]
      }
    ]
  }
}
```

The final package can later become a Codex plugin if we want marketplace-style installation, but start with scripts and example config because this is personal workflow tooling.

## Phase 6: Documentation

Write `README.md` after the first working port with:

- What commands are supported.
- How to install user-level versus repo-local hooks.
- How to trust hooks with `/hooks`.
- Where data is stored.
- How to disable the hook.
- Which Claude features are intentionally not ported.
- Known Codex version tested, starting with `codex-cli 0.136.0`.

## Initial Port Order

1. Contract probe.
2. Dispatcher skeleton and test harness.
3. Pending/send.
4. Queue/sendqueue.
5. Commit and mass-commit skills.
6. Optional `$commit` and `$mass-commit` dispatcher compatibility.
7. Checkpoint spike.
8. Installer.

## Non-goals for the First Pass

- Do not port the Claude statusline. Use Codex's native `/statusline`, `/status`, and `/usage`.
- Do not copy `~/.claude` storage paths.
- Do not register several `UserPromptSubmit` hooks independently.
- Do not use Claude-specific output JSON until Codex accepts it in the probe.
- Do not make the checkpoint hook mutate Codex's native session database.

## Acceptance Criteria

The migration is ready for daily use when:

- A single Codex dispatcher is installed and trusted.
- `$pending`, `$send`, `$queue`, `$queue-list`, and `$sendqueue` pass fixture tests.
- Prompt content with quotes, backslashes, and newlines round-trips correctly.
- Commit helpers are available as Codex skills or equivalent compatibility commands.
- Checkpoint behavior is either implemented safely or explicitly replaced by documented Codex-native `/resume` and `codex fork` workflows.
- The README documents install, trust, disable, storage, and tested Codex version.
