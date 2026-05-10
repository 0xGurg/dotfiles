---
name: review-plan
description: Iterative review loop with inspector and auditor. Load this when a plan or unit of work is ready for validation before finalizing.
---

## Review Loop

1. Invoke `inspector` via the `task` tool — pass the full plan or change summary along with relevant code context (changed files, current implementation state). Inspector checks correctness, bugs, edge cases, and logic.
2. Invoke `auditor` via the `task` tool — pass the same context. Auditor checks security, performance, and maintainability.
3. Incorporate valid feedback. Discard nitpicks that conflict with explicit user requirements.
4. If feedback required significant changes, repeat from step 1.
5. Finalize once both inspector and auditor have no critical or warning-level issues.
