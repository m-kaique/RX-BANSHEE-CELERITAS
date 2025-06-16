# Task: StrategyParameterReview
**Date:** 2025-06-14 00:49 UTC

## Problem
Several strategies used generic 10-point stops. The trading guide specifies different
stop sizes for each asset (lines 4165-4376), so thresholds were misaligned.

## Solution
- Added `GuideStopPoints()` helper returning default stop distances per asset.
- Updated Pullback to MA, Spike and Channel, VWAP Reversion, Fibonacci Retrace and
  Mean Reversion 50-200 strategies to use the helper instead of fixed 10-point stops.
- Adjusted `SetupAssets` minimum stop values to 7 points for WDO, 200 for WIN and
  1000 for BTC.

## Code (snippet)
```mql5
// Utils.mqh
inline double GuideStopPoints(const string symbol)
{
    if(StringFind(symbol,"WDO")==0) return 7.0;
    if(StringFind(symbol,"WIN")==0) return 200.0;
    if(StringFind(symbol,"BTC")==0) return 1000.0;
    return 10.0;
}
```

## Manual Testing Instructions
- [ ] Compile the EA to ensure no errors.
- [ ] Attach to charts and verify generated stops roughly match the configured
      distances for each asset.

## Observations / Notes
- Values are approximations from the guide; adjust if real market conditions
demand.
