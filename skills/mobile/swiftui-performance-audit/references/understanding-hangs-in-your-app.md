Hangs are different from general slowness.

- Look for main-thread blocking work, synchronous I/O, image decode, layout explosions, or lock contention.
- Treat unresponsive interaction as a high-severity issue even if average frame time looks acceptable.
- Reproduce with the smallest deterministic interaction before collecting traces.
