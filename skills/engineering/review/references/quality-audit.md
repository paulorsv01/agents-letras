# Quality Audit Modality (Maintainability)

An unusually strict review focused on implementation quality, maintainability, abstraction quality, and codebase health. Run it alone (skip the ledger; go straight to the 13 questions + rubric) or layer it onto the full method as added severity criteria in Phase 4 and Phase 7.

Above all: **be ambitious about structure.** Do not merely identify local cleanup. Actively search for code-judo moves — restructurings that preserve behavior while making the implementation dramatically simpler, smaller, more direct, more elegant.

## Baseline Prompt

> Perform a deep code quality audit of the changes.
> Rethink how to structure / implement the changes to meaningfully improve code quality without impacting behavior.
> Improve abstractions and modularity, reduce spaghetti, improve succinctness and legibility.
> Be ambitious: if there is a clear path to improving the implementation that involves restructuring some of the codebase, go for it.
> Be thorough and rigorous. Measure twice, cut once.

## Non-Negotiable Rules

0. **Be ambitious about structural simplification.** Look for ways to reframe the change so whole branches, helpers, modes, conditionals, or layers disappear entirely. Prefer the solution that feels inevitable in hindsight. Assume a code-judo move is often available: a re-organization that uses the existing architecture more effectively and makes the change dramatically simpler. If you can delete complexity rather than rearrange it, push hard for that.

1. **1k-line rule.** Do not let a change push a file from under 1k lines to over 1k without a very strong reason. Treat it as a strong smell. Prefer extracting helpers/subcomponents/modules. If the diff crosses the threshold, explicitly ask whether the code should be decomposed first. Waive only with a compelling structural reason and a still clearly-organized result.

2. **Anti-spaghetti rule.** Be highly suspicious of new ad-hoc conditionals, scattered special cases, or one-off branches inserted into unrelated flows. "Weird if statements in random places" is a design problem, not a nit. Prefer pushing logic into a dedicated abstraction, helper, state machine, policy object, or separate module. Call out changes that make surrounding code harder to reason about even if they technically work.

3. **Clean the design, not just accept working code.** If behavior can stay the same while structure becomes meaningfully cleaner, push for the cleaner version. Do not rubber-stamp "it works" that leaves the codebase messier. Prefer simplifications that remove moving pieces over refactors that spread the same complexity around.

4. **Direct, boring, maintainable over hacky or magical.** Treat brittle, ad-hoc, or magic behavior as a quality problem. Be skeptical of generic mechanisms that hide simple data-shape assumptions. Flag wrappers that add no invariant, no capability restriction, and no semantic distinction — they just delegate without buying clarity. A wrapper that enforces an invariant, narrows capability, or marks a real semantic boundary is legitimate; one that only forwards is not.

5. **Type and boundary cleanliness.** Question unnecessary optionality, overly broad types (`any`, `unknown`, `Object`, `id`, `interface{}`, untyped maps/dicts), or cast-heavy code when a more specific type or clearer boundary could exist. Prefer explicit models or shared contracts over loosely-shaped ad-hoc objects. If a branch relies on silent fallback to paper over an unclear invariant, ask whether the boundary should be explicit instead.

6. **Canonical layer + reuse.** Call out feature logic leaking into shared paths, or implementation details leaking through APIs. Prefer existing canonical utilities over bespoke one-offs. Push code toward the right package/service/module instead of normalizing architectural drift.

7. **Atomicity and orchestration.** If independent work with no shared state or ordering constraint is serialized, ask whether it can run concurrently — but do not apply this to transactional, ordered, or mutually exclusive operations, where serialization is correct. If related updates can leave state half-applied, push for a more atomic structure. Don't over-index on micro-optimizations, but flag avoidable orchestration complexity that makes the implementation brittle.

## Primary Review Questions (self-check)

- Is there a code-judo move that would make this dramatically simpler?
- Can this be reframed so fewer concepts, branches, or helper layers are needed?
- Does this improve or worsen the local architecture?
- Did the diff add branching complexity where a better abstraction (model, discriminated union, state machine, dispatch) should exist?
- Did a previously cohesive module become more coupled, stateful, or harder to scan?
- Is this logic living in the right file and layer?
- Did this change enlarge a file or component past a healthy size boundary?
- Are there repeated conditionals that signal a missing abstraction — a model, discriminated union, state machine, or helper — that would eliminate the duplication?
- Is the implementation direct and legible, or does it rely on special cases and incidental control flow?
- Is this abstraction actually earning its keep, or is it just a pass-through?
- Did the diff introduce casts, broad types, optionality, or ad-hoc object shapes that obscure the real invariant?
- Is this logic in the canonical layer, or did the diff leak details across a boundary?
- Is this orchestration more sequential or less atomic than it needs to be?

## What to Flag Aggressively

A complicated implementation where a cleaner reframing deletes whole categories of complexity; refactors that move code around without reducing concepts; a file crossing 1000 lines due to the change; new conditionals bolted onto unrelated paths; one-off booleans/nullable modes/flags complicating control flow; feature-specific logic leaking into general-purpose modules; generic magic handling that hides simple structure; pass-through wrappers / identity abstractions that add no invariant or capability; unnecessary casts/broad types/optional params muddying the contract; copy-pasted logic instead of extracted helpers; narrow edge-case handling buried in a busy function; refactors that pass tests but reduce modularity/readability; "temporary" branching likely to become permanent; bespoke helpers where a canonical utility exists; logic in the wrong layer; independent async operations chained sequentially when they could be concurrent, without ordering or shared-state justification; partial-update logic leaving state less atomic than necessary.

## Preferred Remedies (ordered)

1. Delete a whole layer of indirection rather than polishing it.
2. Reframe the state model so conditionals disappear instead of getting centralized.
3. Change the ownership boundary so the feature becomes a natural extension of an existing abstraction.
4. Turn special-case logic into a simpler default flow with fewer exceptions.
5. Extract a helper or pure function.
6. Split a large file into smaller focused modules.
7. Move feature-specific logic behind a dedicated abstraction.
8. Replace condition chains with an explicit, named dispatcher or data model (typed model, discriminated union, or strategy dispatch appropriate to the language).
9. Separate orchestration from business logic.
10. Collapse duplicate branches into a single clearer flow.
11. Delete wrappers that do not meaningfully clarify the API.
12. Reuse the existing canonical helper instead of a near-duplicate.
13. Make boundaries explicit so control flow simplifies.
14. Move logic to the package/module/layer that already owns the concept.
15. Parallelize independent work when that also simplifies orchestration (only when no ordering or shared-state constraint exists).
16. Restructure related updates into a more atomic flow.

Do not settle for "maybe rename this" when the issue is structural. Do not settle for a cleaner version of the same messy idea if a much simpler idea is plausible.

## Output Priority

1. Structural code-quality regressions
2. Missed opportunities for dramatic simplification / code-judo
3. Spaghetti / branching complexity increases
4. Boundary / abstraction / type-contract problems
5. File-size and decomposition concerns
6. Modularity and abstraction issues
7. Legibility and maintainability concerns

Do not flood with low-value nits when larger structural issues exist. Prefer a small number of high-conviction comments over a long list of cosmetic notes.

## Approval Bar

Do not approve merely because behavior seems correct. Treat these as presumptive blockers unless the author clearly justifies them:

- structural regression
- a missed code-judo move where a plausible path would delete complexity
- a file pushed from below 1000 to above 1000 lines
- ad-hoc branching that makes an existing flow more tangled
- feature checks scattered across shared code
- an unnecessary abstraction/wrapper/cast-heavy contract that makes the design more indirect
- duplicated existing helper, or logic in the wrong layer when a canonical home exists

## Tone

Direct, serious, demanding about quality. Not rude, but do not soften major maintainability issues into mild suggestions. If the code makes the codebase messier, say so. If the implementation missed a dramatic simplification, say so.

Good phrases:

- `this pushes the file past 1k lines. can we decompose this first?`
- `this adds another special-case branch into an already busy flow. can we move this behind its own abstraction?`
- `this works, but it makes the surrounding code more spaghetti. let's keep the behavior and restructure the implementation.`
- `this feels like feature logic leaking into a shared path. can we isolate it?`
- `this abstraction seems unnecessary. can we just keep the direct flow?`
- `why does this need a cast / broad type here? can we make the boundary more explicit instead?`
- `this looks like a bespoke helper for something we already have. can we reuse the canonical one?`
- `i think there's a code-judo move here that makes this much simpler. can we reframe so these branches disappear?`
- `this refactor moves complexity around, but doesn't really delete it. is there a way to make the model itself simpler?`
