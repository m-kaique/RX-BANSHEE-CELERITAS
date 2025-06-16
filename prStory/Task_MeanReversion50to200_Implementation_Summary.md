# Task: MeanReversion50to200 Implementation
**Date:** 2025-06-13 14:03 UTC

## Problem
The EA lacked a strategy for mean reversion between the EMA50 and EMA200 as described in the trading guide. Lines 1316-1412 highlight how price tends to seek these moving averages and suggest entries when price returns to this zone.

## Solution
Created `MeanReversion50to200.mqh` implementing a reversal strategy that triggers when price was far from the EMA50/EMA200 average and now trades back near it. The strategy enters in the direction of the prevailing EMA50 vs EMA200 trend with a 2R target and stop beyond the prior bar. `SignalEngine` now includes this module when generating reversal signals.

## Code (excerpt)
```mql5
// MeanReversion50to200.mqh
bool Identify(const string symbol,ENUM_TIMEFRAMES tf,bool &buySignal)
{
    double ema50=GetEMA(symbol,tf,50);
    double ema200=GetEMA(symbol,tf,200);
    double price0=iClose(symbol,tf,0);
    double price1=iClose(symbol,tf,1);
    double avg=(ema50+ema200)/2.0;
    double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
    bool nearAvg=MathAbs(price0-avg)<=5*point;
    bool wasFar=MathAbs(price1-avg)>=20*point;
    if(!nearAvg || !wasFar) return false;
    if(ema50>ema200 && price0>avg) { buySignal=true; return true; }
    if(ema50<ema200 && price0<avg) { buySignal=false; return true; }
    return false;
}
```

## Manual Testing Instructions
- [ ] Compile `IntegratedPA_EA.mq5` in MetaEditor.
- [ ] Run on historical charts with strong moves away from EMA200 and observe "MeanRev50to200" signals.
- [ ] Verify stops and targets follow a 2:1 reward ratio.

## Observations / Notes
- Parameters for distance from the average (5/20 points) are heuristic and may require tuning per asset.
