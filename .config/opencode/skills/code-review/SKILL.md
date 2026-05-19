---
name: code-review
description: MUST invoke after any non-trivial implementation — whether done by @fixer or the orchestrator directly. Invoke @reviewer-minimax and @reviewer-qwen in parallel to catch anti-patterns, missing edge cases, and test gaps before marking work as done.
---

# Code Review Workflow

## Mandatory: invoke reviewers after implementation

After @fixer (or the orchestrator directly) completes a non-trivial code change, the orchestrator MUST invoke both reviewers in parallel:

1. `@reviewer-minimax` (opencode/minimax-m2.5-free)
2. `@reviewer-qwen` (opencode/qwen3.6-plus-free)

Both are read-only subagents that review the same code independently. Compare their findings:

- If **both** flag an issue as critical → block and fix before proceeding
- If **one** flags an issue → use judgment, but err on the side of fixing
- If **neither** finds anything → work is done

## When to skip

- Single-line typos or trivial one-liner fixes
- Config file changes (JSON, YAML, TOML) with no logic
- Reviewers have already been run on the same code in this session

## Integrate findings

After the reviewers complete, summarize their consensus in a brief `## Review Summary` block before continuing. If the user doesn't want a written summary, just confirm no blockers remain.
