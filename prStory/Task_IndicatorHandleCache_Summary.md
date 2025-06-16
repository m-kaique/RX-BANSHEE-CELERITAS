# Task: IndicatorHandleCache
**Date:** 2025-06-13 13:23 UTC

## Problem
Indicator functions such as `GetEMA` opened and released an indicator handle on every tick, causing unnecessary overhead.

## Solution
Implemented a simple caching mechanism in `Utils.mqh` storing EMA indicator handles per symbol, timeframe and period. `GetEMA` now reuses these handles and `ReleaseEMAHandles` cleans them up on deinitialization. `OnDeinit` in `IntegratedPA_EA.mq5` calls this release function.

## Code (excerpt)
```mql5
struct EMAHandle
{
    string symbol;
    ENUM_TIMEFRAMES tf;
    int period;
    int handle;
};
static EMAHandle g_emaHandles[];

inline int GetEMAHandle(const string symbol,ENUM_TIMEFRAMES tf,int period)
{
    for(int i=0;i<ArraySize(g_emaHandles);i++)
        if(g_emaHandles[i].symbol==symbol && g_emaHandles[i].tf==tf && g_emaHandles[i].period==period)
            return g_emaHandles[i].handle;
    int handle=iMA(symbol,tf,period,0,MODE_EMA,PRICE_CLOSE);
    if(handle!=INVALID_HANDLE)
    {
        int idx=ArraySize(g_emaHandles);
        ArrayResize(g_emaHandles,idx+1);
        g_emaHandles[idx].symbol=symbol;
        g_emaHandles[idx].tf=tf;
        g_emaHandles[idx].period=period;
        g_emaHandles[idx].handle=handle;
    }
    return handle;
}
```

## Manual Testing Instructions
- [ ] Compile `IntegratedPA_EA.mq5` ensuring no errors.
- [ ] Run the EA and check that no indicator handles are repeatedly created in logs.
- [ ] Confirm that indicator values still update correctly on each tick.

## Observations / Notes
- Handles are created lazily on first use; additional indicators can be cached similarly.
