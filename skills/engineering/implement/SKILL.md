---
name: implement
description: "Implement a piece of work based on a spec or set of tickets."
disable-model-invocation: true
---

Implement the work described by the user in the spec or tickets.

If the user passes a ticket reference, fetch it from the issue tracker and state its title before starting. If the reference is ambiguous, ask.

Before writing code: if the repo uses the wtree layout (a `.bare` directory at the repo root) and you are not already inside a feature worktree, use /feature-worktree to start one and continue there. Never commit feature work to main.

Use /tdd where possible, at pre-agreed seams.

Run typechecking regularly, single test files regularly, and the full test suite once at the end.

Once done, use /code-review to review the work, and address what it finds.

Commit your work to the current branch.

When the suite is green and the review findings are addressed, offer the user /feature-worktree finish to merge back into main — don't merge without their go-ahead.
