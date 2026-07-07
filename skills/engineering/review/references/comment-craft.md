# Comment Craft: User Draft Loop & Proof

When the user drafts a review comment, or asks for comments to paste, evaluate the technical claim first, then the wording. Use the verified ledger as input — do not let comment style drive the analysis.

## Evaluate the Claim First

Do:

- say whether the comment makes technical sense
- point out the exact sentence that overclaims
- preserve the user's voice when refining
- keep one comment anchored to one concrete problem (file:line)
- fix typos

Do not:

- turn a style example into a template for all comments
- add a fix when the user's goal is to make the author read and reason — point at the symptom and refer to the reference instead
- say "crash" when the real effect is silent termination, stale state, lost cleanup, false log, or no-op
- keep a comment whose only evidence is "a reviewer said so" — human or automated; the claim must stand on local code evidence

## Voice and Shape

Match the author's language and register. First person, conversational (EN: "I'm not sure why this needs to be…"; or the author's own language and idiom). Favor the pattern **doubt + concrete proposal + open question** ("was there a reason to…?"). Do not pre-chew the full solution when the goal is for the author to read and reason.

Calibrate overclaim: match the word to the real effect. "Crash" only for an actual crash; otherwise name the precise effect (stuck state, no-op, lost data, false log, silent termination).

## Proof on the UI / Deterministic Repro

When asked to "see it happen", find the actual visible path. If no confirmed path exists, say so — do not invent one.

When a comment claims a visible defect, offer a deterministic demonstration diff: force the real trigger, keep the rest of the code real, and show the A/B (with-bug vs with-fix). If no UI path can be confirmed, say that instead of constructing one.
