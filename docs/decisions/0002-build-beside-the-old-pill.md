# 0002 — Build the islands beside the old pill, behind a setting

- **Status:** Accepted
- **Date:** 2026-10-25

## Context
The redesign takes many milestones. The shell is the daily driver, so it has
to stay fully usable while the islands are half-built.

## Decision
New islands go into new files (`components/ember/`). A setting chooses which
UI the shell shows. Shared services in `core/` are reused, not forked. The
old pill and the setting are deleted in the last milestone (M9).

## Consequences
- The shell works at every commit; the redesign can pause at any milestone.
- Old and new can be compared side by side by flipping the setting.
- For a while there are two UIs to keep loading cleanly; a change in `core/`
  must be checked with both.
- Old-pill bugs are only fixed if they also affect `core/` or block daily use.
