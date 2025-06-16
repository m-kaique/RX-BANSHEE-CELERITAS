# Task: IndicatorOptimization
**Date:** 2025-06-13 13:39 UTC

## Problem
Some indicator calculations opened handles or recomputed values on every tick, increasing CPU usage.

## Solution
- Added a VWAP caching structure in `Utils.mqh` to store the daily VWAP per symbol and timeframe.
- Added `ReleaseVWAPCache()` for cleanup and called it in `OnDeinit`.
- Implemented `SetupIndicators()` in `IntegratedPA_EA.mq5` to pre-create EMA handles for common periods during `OnInit`.
- Updated `GetVWAP` to reuse cached values and avoid recalculation within the same day.

## Code (excerpt)
```mql5
struct VWAPCache
{
    string symbol;
    ENUM_TIMEFRAMES tf;
    datetime day;
    double value;
};
...
inline double GetVWAP(const string symbol,ENUM_TIMEFRAMES tf)
{
    datetime dayStart=iTime(symbol,PERIOD_D1,0);
    for(int i=0;i<ArraySize(g_vwapCache);i++)
        if(g_vwapCache[i].symbol==symbol && g_vwapCache[i].tf==tf && g_vwapCache[i].day==dayStart)
            return g_vwapCache[i].value;
    // compute VWAP and store in cache
}
```

## Manual Testing Instructions
- [ ] Compile `IntegratedPA_EA.mq5` in MetaEditor and ensure no errors.
- [ ] Run the EA and monitor logs to verify handles are created once at initialization and VWAP values update once per day.

## Observations / Notes
- VWAP is computed using historical price/volume data rather than a built-in indicator; caching reduces overhead.
