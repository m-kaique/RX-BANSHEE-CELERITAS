# Task: PullbackToMA Implementation
**Date:** 2025-06-13 04:09 UTC

## Problem
No strategy in the EA was implemented, so no trading signals were generated. To follow the trading guide recommendation of using pullbacks to key moving averages during strong trends, we needed a basic strategy module.

## Solution
Added a new `PullbackToMA` strategy module based on the guideline *"Pullbacks para Médias Móveis Chave"* from the trading guide lines 5196‑5223. The strategy identifies pullbacks to the EMA21 when EMAs (9,21,50) are aligned, generating buy or sell signals with stops beyond the prior bar and a 2:1 reward ratio. The strategy is evaluated in `SignalEngine` after the Spike and Channel module so it is triggered when no spike pattern is present.

## Code
```mql5
#include "strategies/PullbackToMA.mqh"         // SignalEngine.mqh
...
Signal GenerateTrendSignals(const string symbol,ENUM_TIMEFRAMES tf)
{
   Signal s; s.valid=false;
   SpikeAndChannel sac;
   if(sac.Identify(symbol,tf))
      return sac.GenerateSignal(symbol,tf);
   PullbackToMA pb;
   if(pb.Identify(symbol,tf))
      return pb.GenerateSignal(symbol,tf);
   return s;
}
```
Main part of `PullbackToMA.mqh`:
```mql5
if(up && close0 > ema21)
{
    s.valid = true;
    s.direction = SIGNAL_BUY;
    s.stop  = low1 - 10*point;
    s.target = s.entry + (s.entry - s.stop)*2.0;
    s.strategy = "PullbackMA";
}
```

## Manual Testing Instructions
- [ ] Compile the EA in MetaEditor to ensure no errors.
- [ ] Attach the EA to a chart with `EnableTrading=false` and observe logs when pullbacks to EMA21 occur.
- [ ] After verifying signals, enable trading on a demo account to observe order placement.

## Observations / Notes
- Stop distance uses a fixed 10 points beyond the previous bar; adjust according to asset volatility for better adherence to guide recommendations.
- Additional strategies and risk management features remain to be implemented.
