# Task: BollingerStochastic Implementation
**Date:** 2025-06-13 19:06 UTC

## Problem
The PDF guide (lines 3600-3625) describes an integrated setup using Bollinger Bands for context and Stochastic for timing, combined with EMAs and VWAP. The EA lacked a strategy implementing this approach.

## Solution
- Added cached indicator handles for Bollinger Bands and Stochastic in `Utils.mqh` with helper functions `GetBB` and `GetStochastic`.
- Created `BollingerStochastic` strategy checking trend via EMAs and VWAP, requiring Bollinger bands to be open and Stochastic exiting extremes.
- Integrated the strategy into `SignalEngine` trend generation and prepared/cleaned handles in `IntegratedPA_EA.mq5`.
- Corrected `iBands` call parameters to avoid compilation error.

## Code (excerpt)
```mql5
// strategies/BollingerStochastic.mqh
if(close0>ema9 && close0>ema50 && close0>vwap && kPrev<20 && kCur>kPrev && kCur>20)
    m_buy=true;
```

## Manual Testing Instructions
- [ ] Compile the EA in MetaEditor and ensure no errors.
- [ ] Run on a trending market with Bollinger bands open to observe `BollStoch` signals.
- [ ] Verify stops below EMA9/highs and targets near EMA50 or opposite band.

## Observations / Notes
- Bollinger width threshold uses 2 ATR; adjust per asset if needed.
