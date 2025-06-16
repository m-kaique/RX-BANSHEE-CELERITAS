# Task: NewBarDetectionFix
**Date:** 2025-06-13 12:36 UTC

## Problem
Signals were generated only for the first enabled asset because the `IsNewBar` check used a single static variable shared across all symbols. This prevented correct bar detection when multiple instruments were traded simultaneously.

## Solution
Added a `lastBar` field to `AssetConfig` and initialized it in `SetupAssets`. `OnTick` now calls `IsNewBar` with this per-asset timestamp so each symbol tracks its own bar updates, aligning with the guide's emphasis on accurate context analysis.

## Code (excerpt)
```mql5
struct AssetConfig
{
    string symbol;
    bool   enabled;
    double minLot;
    double maxLot;
    double lotStep;
    double tickValue;
    int    digits;
    double rangeThreshold;
    datetime lastBar; // timestamp of last processed bar
};
...
if(!IsNewBar(symbol,MainTimeframe,g_assets[i].lastBar))
    continue;
```

## Manual Testing Instructions
- [ ] Compile `IntegratedPA_EA.mq5` in MetaEditor.
- [ ] Attach the EA to a chart with multiple assets enabled.
- [ ] Verify in the logs that signals are evaluated independently for each symbol every new bar.

## Observations / Notes
- Asset initialization sets `lastBar` to zero so the first bar triggers immediately.
