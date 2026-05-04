# Profiling Intake

When code review is inconclusive, ask for:

- exact interaction
- exact symptom
- device + OS
- Debug vs Release
- simulator vs device
- SwiftUI timeline + Time Profiler capture

Prefer a short, single-interaction capture over a long noisy trace.

Warn about these traps:

- Debug timings can mislead
- Simulator can hide device-only issues
- mixed interactions in one trace make attribution weak
