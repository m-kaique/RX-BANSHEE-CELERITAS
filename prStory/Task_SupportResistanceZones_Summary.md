# Task: Support & Resistance Zone Detection
**Date:** 2025-06-19 20:56 UTC

## Problem
Strategies relied on raw highs and lows for range decisions and there was no shared method to locate support or resistance levels.

## Solution
- Added `FindSupportZones` and `FindResistanceZones` helpers in `MarketContext.mqh`.
- Zones are formed by grouping local extrema within 0.5 ATR using cached ATR handles.
- Convenience functions return the nearest zone to current price.
- Updated `RangeFade` and `RangeBreakout` strategies to query these helpers for range extremes.

## Code (excerpt)
```mql5
// MarketContext.mqh
int FindSupportZones(const string symbol,ENUM_TIMEFRAMES tf,int bars,double &zones[]);
int FindResistanceZones(const string symbol,ENUM_TIMEFRAMES tf,int bars,double &zones[]);
double FindNearestSupport(const string symbol,ENUM_TIMEFRAMES tf,int bars);
double FindNearestResistance(const string symbol,ENUM_TIMEFRAMES tf,int bars);
```

## Manual Testing Instructions
- [ ] Run `scripts/compile.sh` to compile the EA (requires Wine).
- [ ] In MetaTrader, confirm `RangeFade` and `RangeBreakout` continue to trigger around detected zones.

## Observations / Notes
- Compilation skipped in CI environments without Wine.
