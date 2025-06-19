# Task: Market Metrics
**Date:** 2025-06-13 22:30 UTC

## Problem
Strategies lacked quantitative measures of volatility and trend strength for adaptive risk management.

## Solution
- Added `GetVolatilityRatio` and `GetTrendStrength` methods to `MarketContext.mqh`.
- Provided wrappers in `RiskManager.mqh` so risk logic can query these metrics.
- `GetVolatilityRatio` compares the current ATR to the average of prior periods.
- `GetTrendStrength` returns the average EMA spacing normalized by ATR.

## Code (excerpt)
```mql5
// MarketContext.mqh
double GetVolatilityRatio(const string symbol,ENUM_TIMEFRAMES tf,int atrPeriod,int lookback)
{
    int handle=GetATRHandle(symbol,tf,atrPeriod);
    // ... compute ratio ...
}

double GetTrendStrength(const string symbol,ENUM_TIMEFRAMES tf,int atrPeriod)
{
    int h9=GetEMAHandle(symbol,tf,9);
    // ... compute normalized spacing ...
}
```

## Manual Testing Instructions
- [ ] Compile the EA using `scripts/compile.sh`.
- [ ] In MetaTrader, call the new methods from a script to verify values.
