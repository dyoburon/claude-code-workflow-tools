# Codex Workflow Tools

Codex ports of useful Claude Code `$` workflow hooks.

## Commands

| Command | Behavior |
| --- | --- |
| `$pending <name> <prompt>` | Save a prompt for later. |
| `$send <name>` | Inject a saved prompt and delete it. |
| `$queue <name> <prompt>` | Save a prompt and append it to the queue. |
| `$queue-list` | Show queued prompt names and previews. |
| `$sendqueue` | Inject and remove the next queued prompt. |
| `$commit [description]` | Inject conventional commit instructions. |
| `$mass-commit [hints]` | Inject atomic multi-commit instructions. |

Checkpoint commands (`$cc`, `$cc-list`, `$cc-resume`) are intentionally stubbed for now. Use Codex-native `/resume`, `codex resume`, or `codex fork` until checkpointing is rebuilt around Codex transcripts.

## Install

This package is installed under `CODEX_HOME`, which is `~/.codex-personal` in the current setup:

```text
~/.codex-personal/workflow-tools/
```

The hook registration lives at:

```text
~/.codex-personal/hooks.json
```

Restart Codex, then run `/hooks` to review and trust the new hook if Codex asks.

## Storage

Runtime data is stored under:

```text
$CODEX_HOME/workflow-tools/pending-prompts/
$CODEX_HOME/workflow-tools/queue-order.txt
```

If hooks run under `workspace-write` sandboxing, include the workflow directory as a writable root in `$CODEX_HOME/config.toml`:

```toml
[sandbox_workspace_write]
writable_roots = ["/Users/dylan/.codex-personal/workflow-tools"]
```

## Test

```bash
./tests/run-hook-tests.sh
```

The tests use a temporary `CODEX_WORKFLOW_HOME` and do not touch your real pending prompts or queue.
