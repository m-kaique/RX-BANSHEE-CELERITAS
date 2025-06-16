# Task: AssetSpecificStops
**Date:** 2025-06-13 12:45 UTC

## Problem
Strategies used generic stop distances, ignoring volatility differences between instruments. The trading guide (lines 2260-2270) recommends ~1500-point stops for Bitcoin and 80–150 points for the index, with tighter stops for the dollar. Without these adjustments, risk calculations could understate potential loss.

## Solution
Added a `minStop` field to `AssetConfig` and defined values for each asset in `SetupAssets` (BTC 1500, WDO 20, WIN 120). `OnTick` now enforces a minimum stop distance before order sizing, adjusting the signal's stop if the strategy proposes a smaller one.

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
    datetime lastBar;
    double minStop; // minimum stop distance in points
};
...
if(dist<g_assets[i].minStop)
{
    double adjust=g_assets[i].minStop*point;
    if(sig.direction==SIGNAL_BUY)
        sig.stop = sig.entry - adjust;
    else if(sig.direction==SIGNAL_SELL)
        sig.stop = sig.entry + adjust;
}
```

## Manual Testing Instructions
- [ ] Compile `IntegratedPA_EA.mq5` in MetaEditor to ensure no errors.
- [ ] Attach the EA to BTCUSD, WDO, and WIN charts.
- [ ] Verify that generated orders use stops at least equal to the configured minimums.

## Observations / Notes
- Default values are based on the guide's volatility recommendations and can be tweaked per broker.
