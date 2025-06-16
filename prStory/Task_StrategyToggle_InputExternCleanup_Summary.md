# Task: StrategyToggle InputExtern Cleanup
**Date:** 2025-06-13 21:15 UTC

## Problem
Compilation still failed because `SignalEngine.mqh` declared the strategy toggle variables as `extern` while the main file defined them as `input`. The compiler treats `input` as a distinct type, causing "already defined with different type" errors.

## Solution
Removed the `extern` declarations from `SignalEngine.mqh`. The module now directly accesses the global `input` variables defined in `IntegratedPA_EA.mq5`, which resolves the redefinition errors.

## Code (excerpt)
```mql5
// SignalEngine.mqh
-extern bool UseSpikeAndChannel;
-extern bool UsePullbackMA;
...
+// variables are defined as input in the main file
```

## Manual Testing Instructions
- [ ] Compile `IntegratedPA_EA.mq5` and ensure the previous redefinition errors no longer appear.
- [ ] Toggle strategies via the EA inputs and confirm signals respect the settings.

## Observations / Notes
- Sharing `input` variables across modules works without explicit `extern` declarations when all files are included in a single compilation unit.
