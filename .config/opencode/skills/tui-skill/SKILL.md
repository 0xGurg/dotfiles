---
name: tui-skill
description: Use when implementing, reviewing, or fixing Bubble Tea TUI phases in Go projects. Triggers on mentions of import picker, rollback browser, status dashboard, apply review, TUI_PLAN.md, findings.md, or phase-gated TUI work under app/internal/tui/ or similar paths.
---

# Bubble Tea TUI Implementation Workflow

## Mandatory review after implementation

After @fixer completes any TUI implementation work, the orchestrator MUST invoke both reviewers in parallel before marking the phase done:

1. `@reviewer-minimax` (opencode/minimax-m2.5-free)
2. `@reviewer-qwen` (opencode/qwen3.6-plus-free)

Both are read-only subagents that check the same criteria independently. Compare their findings. If either flags a critical issue, fix it before proceeding.

## Implementation rules

These rules are derived from past findings. Apply them during implementation, not just review:

- **Never discard errors.** Store scan/read errors in the model and display them in `View()`. An empty tab with no explanation is a bug.
- **New CLI flag → update all shell completion blocks** (bash, zsh, fish).
- **No silent fallbacks.** If a switch defaults to something, surface it clearly — don't hide the fallback.
- **Extract shared logic.** If TUI and non-TUI paths both open a file or invoke a scan, extract it — don't copy-paste.
- **No wrapper structs without value.** If a struct wraps another type and adds no behavior, collapse it.
- **Use `, ok` two-value form** for all type assertions in TUI code. Panicking on `.()` is critical.
- **Test every state.** Empty state, error state, resize, filter, keyboard nav, cancel path, non-TTY fallback — all must have test coverage before a phase is done.

## Phase workflow

1. Write a short phase spec (existing behavior, new behavior, error states, empty states, flags impacted, tests required)
2. Have @oracle review the spec if the phase is risky
3. Implement with @fixer
4. Invoke @reviewer-minimax AND @reviewer-qwen in parallel
5. Fix any critical or medium findings
6. Update `findings.md` with review results
7. Only then move to the next phase
