# Heuristics, Failure Modes, Lessons

## Review Heuristics

- Prefer root cause over attribution. An automated reviewer often flags a real symptom while prescribing the wrong fix; the useful conclusion names the root cause and the ownership-correct remedy, not who was right. Credit the symptom without adopting the cure.
- Tool silence is not clearance. Automated reviewers miss whole bug classes; run your own pass over the diff regardless of what they flagged.
- Treat design findings as real when the API shape invites future boundary violations or makes the forbidden path easy.
- A finding needs a failure mode, not just an aesthetic objection.
- A low-level repeated edit can be evidence of a mechanical change, but still verify each category — the same prescription can be right in one class and wrong in another.
- Separate concerns along two axes. By behavior category: business logic, cleanup/teardown, persistence/transaction, background / async work. By layer: UI state, public contract, internal state. Same syntax can require a different fix per category.
- Prefer the smallest change that resolves the full class (root-fix) over N local patches (site-fix). Before recommending the root-fix, verify its preconditions hold across all sites; if not, say which sites need individual treatment and why.
- When the user challenges your conclusion, re-open the code path. If the challenge breaks the fix, say so plainly and update the ledger.
- If the user asks "where does it happen in the UI?", find the actual visible path. If no confirmed UI path exists, say that instead of inventing one — and offer a deterministic demonstration diff that forces the real trigger and shows A/B.
- An external concept (article, doc, pattern) is only actionable once you find its concrete instance in the project code; then the argument belongs to the repo, not the article.
- Do not assert library/platform behavior from memory. Fetch the primary official doc. Distinguish "official doc recommends X (baseline)" from "an article recommends Y (ideal)"; cite sources.

## Common Failure Modes

| Failure | Correction |
| --- | --- |
| Repeating an automated reviewer's claim verbatim as a finding | Convert the claim into a ledger row and verify it locally |
| Treating comments as final output | Return flows, contracts, or comments only in the requested output mode |
| Universalizing the last bug | Classify the underlying category and verify the next case independently |
| Trusting subagent totals | Use totals as coverage metadata; parent verifies promoted candidates |
| Keeping a high severity without observer | Downgrade or remove unless state, persistence, user, CI, or runtime can observe it |
| Fixing the symptom in the wrong layer | Trace ownership boundaries before recommending a fix |
| Overfitting to pasted wording | Preserve useful intent, remove unsupported claims |
| Asserting platform behavior from memory | Fetch the primary official doc; cite it; label article-sourced claims as opinion until validated against the spec |
| Reporting an external concept as a finding | Find its local instantiation first; the argument then belongs to the repo, not the article |
| Stopping at the first file touched | Follow the real code path through callers/callees before deciding |

## Session-Derived Lessons

- The strongest workflow started with suspicious review comments, then proved one blocker with a focused test.
- False positives were valuable: rejecting them sharpened the real invariant.
- Subagents were useful for breadth, but the parent had to dedupe and verify.
- The best synthesis separated "reviewer found a real smell" from "reviewer prescribed the wrong cure".
- The broad workflow answered a higher-level question: whether the change approach was case-by-case or mechanical.
- Partial workflow output was acceptable only because the completed triage and verified candidates already answered the higher-level question.
