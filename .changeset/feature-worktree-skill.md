---
"mattpocock-skills": minor
---

New `feature-worktree` skill: isolated git worktrees for feature work in wtree-layout repos. Starts a worktree via `wtree feature` before any implementation, and merges back via `wtree finish` only after the suite is green, review findings are addressed, and the worktree is clean.
