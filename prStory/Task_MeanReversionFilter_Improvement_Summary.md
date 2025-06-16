# Task: MeanReversionFilter Improvement
**Date:** 2025-06-13 14:34 UTC

## Problem
Trend strategies sometimes open trades when price is returning to the mean between EMA50 and EMA200, leading to low quality entries.

## Solution
Used `CheckMeanReversion50to200` as a pre-condition in `SpikeAndChannel`, `PullbackToMA` and `TrendRangeDay`. These strategies now skip signals if price is too close to the EMA50/EMA200 midpoint, following the guide's observation that the market often retraces to this zone (lines around 1536-1560).

## Code (excerpt)
```mql5
// inside Identify() of each strategy
if(CheckMeanReversion50to200(symbol, tf))
    return false;
```

## Manual Testing Instructions
- [ ] Compile `IntegratedPA_EA.mq5` in MetaEditor.
- [ ] Observe that trend signals do not trigger when price trades near the EMA50/EMA200 average.

## Observations / Notes
- Parameters of `CheckMeanReversion50to200` may need tuning per asset.
