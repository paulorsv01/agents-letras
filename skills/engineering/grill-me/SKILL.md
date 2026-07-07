---
name: grill-me
description: Stress-test a plan against the repo's domain model, sharpen terminology, and update CONTEXT.md/ADRs as decisions crystallize. Use when the user wants to get grilled, challenge a design, or align project language.
---

# Grill Me

Interview the user about every important branch of a plan until there is a shared understanding. Keep the useful parts of the session in the repo's domain docs when they become settled decisions.

Ask one question at a time. Include your recommended answer with each question.

If a question can be answered by exploring the codebase, inspect the code instead of asking.

## Context First

Before asking, look for existing docs:

- `CONTEXT-MAP.md` (root index of per-area `CONTEXT.md` files; update it when a new `CONTEXT.md` is created)
- `CONTEXT.md`
- `docs/adr/`
- local architecture or domain docs

If no domain docs exist, still run the grilling session. Create docs lazily only when the session produces reusable domain knowledge. Default target: create `CONTEXT.md` at the repo root (or next to the closest existing docs) with minimal sections such as `## Terminology` and `## Decisions`, appending only resolved terms and rules.

## Session Rules

- Call out terminology conflicts immediately.
- Replace fuzzy terms with precise canonical terms.
- Use concrete scenarios to test edge cases and boundaries.
- Cross-check claims against code when cheap and relevant.
- Walk the decision tree one branch at a time.
- Resolve dependencies between decisions before moving deeper.
- Update `CONTEXT.md` inline only after a term or rule is actually resolved. When a new `CONTEXT.md` is created, add it to `CONTEXT-MAP.md`.
- Offer an ADR only when the decision is hard to reverse, surprising without context, and the result of a real tradeoff. When accepted, write to `docs/adr/NNNN-kebab-title.md` (next sequential number) with sections Status, Context, Decision, Consequences; follow the repo's existing ADR format if one already exists.
- Stop grilling a branch when further answers would not change the implementation.
- End the session with a compact recap listing resolved decisions, open questions, and which docs (`CONTEXT.md`/ADRs) were touched.

Do not create docs just to create docs. Create or edit them only when the session produced reusable domain knowledge.
