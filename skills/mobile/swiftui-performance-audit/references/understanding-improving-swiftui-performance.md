SwiftUI performance work usually lands in a few buckets:

- invalidation too broad
- identity unstable
- work happening in `body`
- layout too complex
- image or animation cost too high

Use those buckets to structure the audit report and separate strong evidence from likely suspicion.
