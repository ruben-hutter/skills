---
"mattpocock-skills": minor
---

`triage`: repos can optionally define priority labels (canonical `P0`/`P1`/`P2`, most to least urgent) in the tracker config. Where they are defined, the \"show what needs attention\" listing sorts each bucket by priority (oldest first within equal priority) and surfaces each item's priority, and `ready-for-agent`/`ready-for-human` landings stamp the agreed priority label. Repos without a priority config keep the oldest-first listing and stamp nothing.
