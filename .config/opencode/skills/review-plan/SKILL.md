---
name: review-plan
description: Iterative review loop with reviewer-1 and reviewer-2. Load this when a plan or unit of work is ready for validation before finalizing.
---

## Review Loop

1. Invoke `reviewer-1` via the `task` tool — pass the full plan or change summary along with relevant code context (changed files, current implementation state). Reviewer-1 checks correctness, bugs, edge cases, and logic.
2. Invoke `reviewer-2` via the `task` tool — pass the same context. Reviewer-2 checks security, performance, and maintainability.
3. Incorporate valid feedback. Discard nitpicks that conflict with explicit user requirements.
4. If feedback required significant changes, repeat from step 1.
5. Finalize once both reviewers have no critical or warning-level issues.
