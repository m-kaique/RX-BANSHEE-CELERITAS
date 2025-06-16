# Task: MarketContext MultiTF Confirmation
**Date:** 2025-06-13 19:59 UTC

## Problem
Phase detection relied on a single timeframe, leading to signals that ignored the higher context recommended in the trading guide.

## Solution
Added a `ctxTf` field to `AssetConfig` and initialized context timeframes per asset. `MarketContext` now offers `DetectPhaseMTF` which confirms the phase with a higher timeframe, preferring its direction when phases diverge (guide lines 5276-5299). The EA uses this method in `OnTick` and prepares EMA handles for both timeframes.

## Code (excerpt)
```mql5
// MarketContext.mqh
MARKET_PHASE DetectPhaseMTF(const string symbol,ENUM_TIMEFRAMES tf,
                            ENUM_TIMEFRAMES ctxTf,double range_threshold=10.0)
{
   MARKET_PHASE ctx=DetectPhase(symbol,ctxTf,range_threshold);
   MARKET_PHASE local=DetectPhase(symbol,tf,range_threshold);
   if(ctx==local)
      return local;
   if(ctx!=PHASE_UNDEFINED)
      return ctx; // prefer higher timeframe
   return local;
}
```

## Manual Testing Instructions
- [ ] Compile `IntegratedPA_EA.mq5` and ensure no errors.
- [ ] Run the EA and verify log messages reflect phases aligned with the higher timeframe.
- [ ] Observe that trades follow the context timeframe direction when there is divergence.

## Observations / Notes
- Context timeframes: BTC H4, WDO H1, WIN H1. Fine-tune as needed.
