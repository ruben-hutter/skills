---
name: feature-worktree
description: "Isolated git worktrees for feature work in wtree-layout repos (repo root contains a .bare directory). Use this automatically BEFORE implementing any feature, task, or bugfix when the repo root has .bare and you are not already inside a feature worktree: creates <repo>/<name> on branch feat/<name> via `wtree feature`, merges back via `wtree finish`. Never work directly in the main/master worktree of such repos. Also available as /feature-worktree start|finish."
argument-hint: "start <feature-name> | finish <feature-name>"
---

# Feature worktrees

Feature work happens in its own worktree; `main` is never worked on directly.

Assumes the `wtree` layout: `<repo>/.bare` plus a `.git` file at the repo root, with each worktree checked out as a subdirectory (`<repo>/main`, `<repo>/<feature>`). Feature branches are named `feat/<feature-name>`.

## start <feature-name>

1. If no name was given, derive a short kebab-case slug from the spec or ticket title.
2. Write the task brief to a temp file (e.g. `/tmp/task-<feature-name>.md`): goal, decisions already made, pointers to tickets/plans/research, done-when. If the repo already documents the task (plan or ticket files), a brief that just points at them is enough; if those files are uncommitted in the main worktree, copy the essentials into the brief — separate working dirs can't see them.
3. Run `wtree feature <feature-name> <brief-file>` from anywhere inside the repo. Inside tmux, don't launch it without the brief file: TASK.md is the only channel the window's pi receives the task through. The script creates the worktree at `<repo>/<feature-name>` on branch `feat/<feature-name>`, installs the brief as `<worktree>/TASK.md`, opens a window if you're inside tmux, and prints what happened. Follow its report:

   - **A tmux window opened.** The pi in that window owns the task: it reads TASK.md, sets itself up (dependencies per the repo, per-worktree offsets from `docs/agents/worktrees.md` if present) and does the work. Your session's part ends there: tell the user the task is running in the new window, then stop. Don't cd into the worktree, explore it, or implement anything in it yourself. When a window opened, the work happens in that window and nowhere else. Don't open a second window, don't switch focus.
   - **No window opened** (outside tmux, or the window failed to open). There is nothing to hand off to: cd into the worktree yourself and do the work in this session, starting from TASK.md if a brief was installed.

If a window already opened without a brief, it still owns the task (its pi asks the user for it); don't take the work back into your session. Write `<worktree>/TASK.md` and tell the user to point the window's pi at it.

If the repo has no `.bare` directory at its root, it wasn't created with `wtree`: tell the user and ask how to proceed (a plain `git worktree add ../<repo>-wt-<name> -b feat/<name>` is a fine fallback).

## finish <feature-name>

`wtree finish` deletes the worktree directory and the window close ends the pi inside it — so a session living in the worktree must do neither: deleting its own cwd leaves it on a dangling directory and killing its own window dies mid-turn, taking the tmux session down with it. The finish is therefore split by role.

**In the feature worktree session (the briefed pi)** — the user says the task is done:

1. Gate on readiness; if any gate fails, say which and stop (the window stays open): full test suite passes inside the worktree; `/code-review` ran and its findings are addressed; `git status --porcelain` is clean (commit first, per repo convention); `<worktree>/TASK.md` deleted if present (untracked scratch would block the clean check).
2. If the repo has a remote and the user wants the feature branch pushed, push it now.
3. Announce readiness and stop: merging, pushing the default branch, and closing the window belong to a session outside this worktree. Ask the user to run `/feature-worktree finish <feature-name>` in the main session — or hand them the commands if no main session pi is running. Never run `wtree finish` on your own worktree; never kill your own window.

**In the main session (or any session outside the worktree)**:

1. Run `wtree finish <feature-name>` directly from the default-branch worktree, without `cd`-ing first — the script moves itself there, and a prior `cd` would defeat its in-pane guard (it refuses when the calling tmux pane still lives in the worktree). It rebases `feat/<feature-name>` onto the default branch, fast-forward merges, removes the worktree, deletes the branch, and closes the tmux panes that lived in the removed worktree.
2. If the script fails, report its output and stop — keep the window open. Never force a merge and never resolve rebase conflicts silently — hand the conflict back to the user, or ask before resolving it.
3. If the repo has a remote, ask whether to push the default branch, then push from the default-branch worktree.
4. Give the final summary. If the script reported panes it could not close, tell the user which to close manually.

## Parallel agents

Run worktrees in parallel only for tickets that don't block each other (the blocking edges from `/to-tickets` are the map). Worktrees isolate git only: ports, databases, and containers are still shared — check `docs/agents/worktrees.md` for offset conventions before starting servers. When several features finish against the same default branch, later ones may need a rebase with real conflicts; that's expected, don't force it.
