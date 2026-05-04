WWDC23's "Demystify SwiftUI Performance" is the right mental model anchor for audit work.

- Stable identity matters.
- Broad invalidation is often the hidden cause behind "SwiftUI feels slow".
- Layout and rendering cost compound when the view tree churns more than expected.
- Use it as a reasoning aid when explaining why a fix should reduce work, even before you have a full trace.
