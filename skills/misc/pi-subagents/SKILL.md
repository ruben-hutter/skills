---
name: pi-subagents
description: Rebuild the pi coding agent subagent kit on a machine: scout, planner, reviewer, and worker agent definitions plus the /implement, /scout-and-plan, and /implement-and-review workflow prompts, wired to the bundled example extension. Use when configuring pi's subagent extension, restoring it after a reinstall, or upgrading the pi release.
---

# pi Subagents Kit

## What This Sets Up

- The `subagent` extension, symlinked to the example extension bundled with the installed pi release, so it tracks upstream fixes instead of drifting on a stale copy
- Four agent definitions in `~/.pi/agent/agents/`:
  - **scout**: fast codebase recon, read-mostly tools, compresses context for handoff to other agents
  - **planner**: produces implementation plans, read-only tools
  - **reviewer**: code review, bash restricted in spirit to read-only git commands
  - **worker**: general-purpose execution with full tools
- Three workflow prompt templates in `~/.pi/agent/prompts/`:
  - `/implement`: scout, then planner, then worker
  - `/scout-and-plan`: scout, then planner
  - `/implement-and-review`: worker, then reviewer, then worker

## How It Works

The main session is the coordinator. It delegates through the `subagent` tool, and each call spawns an isolated child process (`pi --mode json -p --no-session`) so delegated tool traffic never pollutes the main conversation. There are no built-in agent personas: the extension discovers them only from `~/.pi/agent/agents/*.md` (user scope) and `.pi/agents/*.md` (project scope, opt-in via `agentScope`). An empty agents directory therefore means every delegation fails with `Unknown agent ... Available agents: none`, which is why this kit matters.

Agent definitions are markdown with YAML frontmatter:

```yaml
---
name: worker
description: What the agent does
tools: read, grep, bash   # optional tool allowlist, omit for all tools
model: zai/auto           # optional, pin a model; omit to inherit the session's model
---
```

All four shipped definitions pin `model: zai/auto`, the owner's virtual model router, so delegation always routes through it even when a session is pinned to a specific model.

## Installing

From this skill directory, run the installer:

```bash
./setup.sh
```

The script is idempotent: it finds the newest installed pi release, symlinks the extension sources, copies the templates into `~/.pi/agent/agents/` (keeping any local edits via prompt), and symlinks the prompt templates. Re-run it after a pi release upgrade to re-point the symlinks.

Manual install, if preferred:

```bash
EX="$(dirname "$(find ~/.pi/agent/install -path '*examples/extensions/subagent/index.ts' 2>/dev/null | sort -V | tail -1)")"
mkdir -p ~/.pi/agent/extensions/subagent ~/.pi/agent/agents ~/.pi/agent/prompts
ln -sf "$EX/index.ts"  ~/.pi/agent/extensions/subagent/index.ts
ln -sf "$EX/agents.ts" ~/.pi/agent/extensions/subagent/agents.ts
for f in scout planner reviewer worker; do
  cp -i templates/$f.md ~/.pi/agent/agents/$f.md
done
for p in implement.md scout-and-plan.md implement-and-review.md; do
  ln -sf "$EX/prompts/$p" ~/.pi/agent/prompts/$p
done
```

Customize by editing the copied files in `~/.pi/agent/agents/`, not the templates here; the kit intentionally treats this repo as source and the home directory as deployed state.

## Verification

Start a new pi session and confirm the `subagent` tool describes the expected agents. A cheap end-to-end check that exercises model routing and the appended system prompt:

```bash
pi --mode json -p --no-session --model zai/auto \
  --append-system-prompt <(printf 'Reply ONLY: KIT-OK') \
  "Task: respond with the single word KIT-OK and nothing else"
```
