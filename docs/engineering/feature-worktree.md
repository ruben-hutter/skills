## What it does

Carves feature work out into its own git worktree so the default branch's checkout is never touched while a feature is being built: `wtree feature <name>` creates `<repo>/<name>` on `feat/<name>` and installs a task brief as `TASK.md`; `wtree finish <name>` rebases the branch, fast-forward merges it, and removes the worktree again. The defining constraint is that the session which finishes a worktree is never the session that lived in it: the checkout deletion and window teardown that finishing implies would leave a session in the worktree homeless, so the merge is deliberately pushed into another session.

It relies on a specific repository layout: the repo was created by `wtree`, meaning a `.bare` directory plus a `.git` file at the root, and every checkout is a subdirectory of the repo root (`main/`, `<feature-name>/`, one directory per feature in flight).

## When to reach for it

Type `/feature-worktree start <feature-name>` (or `/feature-worktree finish <feature-name>` to wrap one up), or the agent reaches for it automatically: before implementing any feature, task, or bugfix in a repo whose root has `.bare`, unless the session is already inside a feature worktree. The rule is absolute for these repos: no work happens directly in `main`.

| Situation | What happens |
|---|---|
| Starting a feature, inside tmux | The skill writes a task brief, runs `wtree feature`, and hands the work to a fresh pi in a new window; the coordinating session stops and gets renamed after the feature |
| Starting a feature, outside tmux | No window exists to hand off to, so the same session cds into the worktree and does the work there |
| Finishing, from the feature session | Gates on readiness (tests, review, clean tree), announces, and stops; it never runs `wtree finish` on its own worktree |
| Finishing, from the main session | Runs `wtree finish`, rebasing and merging, and only this session may delete the worktree and close its window |

For executing a whole multi-ticket spec across several worktrees at once, use [implement-spec](https://aihero.dev/skills-implement-spec) instead; feature-worktree isolates one feature's checkout, implement-spec runs the frontier of many.

## Prerequisites

- **The `wtree` layout.** A repo without `.bare` at its root was never initialised with `wtree`; the skill asks before falling back to a plain `git worktree add`.
- **tmux, for the handoff flow.** Without it there is no second window, so the same session does the work inside the worktree (still isolated at the git level).
- **Shared-resource conventions, when parallel features serve ports or databases.** Worktrees isolate git only; a `docs/agents/worktrees.md` in the repo declaring port and database offsets avoids collisions between parallel feature sessions.

## The handoff

Starting a feature splits who does what, and the brief file is the only channel between the halves. The coordinating session distils the task into a brief (goal, decided questions, pointers; if the essential plan files are uncommitted in the main worktree, their content goes into the brief, because a separate working directory cannot read them), and the freshly launched window pi receives it as `TASK.md`, reads it, and owns the task end to end. After launching, the coordinating session's job is over: it tells the user where the work is running and stops. If a bare window was opened without a brief, that window still owns the task, so the session writes `TASK.md` into the worktree for it rather than taking the work back.

Finishing is the same split reversed, and it exists because a session cannot safely destroy its own surroundings: deleting its own cwd strands it, and killing its own window dies mid-turn. The feature session gates on readiness (suite green, review findings addressed, `git status --porcelain` clean, scratch `TASK.md` removed) and then stops. The merge, the worktree removal, and the window closing belong to the main session, which runs `wtree finish` directly from the default-branch worktree without cd-ing in first, so the script's in-pane guard can see that the calling pane lives outside the worktree.

Naming closes the loop: after a successful handoff the coordinating session is automatically renamed after the feature (via the `wtree-handoff-name` extension), because it is the session the user returns to for `finish`. Sessions whose window titles survive a day of parallel work tend to become indistinguishable; the rename makes the finish target identifiable at a glance. Where that extension is absent, run `/name <feature-name>` to set it by hand.

## Running features in parallel

Worktrees shine when several features move at once, and the blocking edges from [to-tickets](https://aihero.dev/skills-to-tickets) are the map of what can safely run concurrently: only tickets without dependency edges between them. Git is isolated per worktree; everything else is shared, so read the repo's port and database offset conventions before starting servers in more than one worktree. When several features finish against the same default branch in sequence, a later finish may rebase onto a moved tip and hit real conflicts; that is the expected cost of the parallelism, and it is resolved with eyes open, never forced.

## Common questions

**Why can't the feature session merge its own work?**
Because the merge is not the only thing finishing does: `wtree finish` also deletes the worktree directory and closes the tmux panes that lived in it. A session sitting in that directory and living in that pane would be destroying its own cwd and killing itself mid-turn. Splitting finish by role is what keeps both sessions alive; the feature session's gates exist so the main session receives a clean, reviewed, committable branch.

**Do I need tmux for any of this to work?**
No. tmux buys the two-session handoff: one coordinator, one worker, each with its own context window. Outside tmux the same session cds into the worktree and does the work itself, and the git isolation is identical. What you lose is the separation of concerns (the coordinating conversation stops accumulating tool traffic) and automatic window lifecycle on finish.

**How do I get back to a feature I handed off yesterday?**
The session that received the handoff is the one that finishes, and it renames itself after the feature the moment it hands off, so among a pile of long-lived windows the finish target is identifiable at a glance. If the naming extension is not loaded, run `/name <feature-name>` to mark it manually before context moves on.

**My repo has no `.bare` directory. What then?**
It was never created with `wtree`, so the skill asks before doing anything, and a plain `git worktree add ../<repo>-wt-<name> -b feat/<name>` is a fine fallback: the discipline of never working in `main` survives even where the layout does not exist.

## It's working if

- The `main/` checkout is still pristine while a feature is mid-flight: everything happened in `<repo>/<feature-name>`.
- Handoffs are unambiguous at a glance: window titles carry feature names instead of generic shell markers.
- Finishing a quiet feature is a fast-forward: rebase onto the tip, ff merge, worktree gone, window closed, no ceremony.
- Parallel features advance without colliding, and the only rebase pain arrives exactly where the ticket graph predicted it.

## Where it fits

A reach-for-it-anytime standalone, gated only by repo layout: it is the first move of nearly every task in a `wtree` repo, before any implementation begins. Neighbours: [to-tickets](https://aihero.dev/skills-to-tickets), whose blocking edges decide which worktrees can run in parallel, and [code-review](https://aihero.dev/skills-code-review), one of the readiness gates a feature must pass before its session declares readiness. For building a whole spec's tickets across a fleet of worktrees at once, see [implement-spec](https://aihero.dev/skills-implement-spec). The map of the whole set lives at [ask-matt](https://aihero.dev/skills-ask-matt).
