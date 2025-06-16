# Task: MarketContext Asset Parameter Improvement
**Date:**  2025-06-13 12:26 UTC

## Problem
Market phase detection used a fixed threshold and ignored asset-specific volatility differences, leading to unreliable classification of trend, range, and reversal phases.

## Solution
Added a `rangeThreshold` field to `AssetConfig` and enhanced `MarketContext::DetectPhase` to accept this value. The function now checks EMA alignment with a customizable overlap threshold, returning `PHASE_RANGE` when EMAs converge and price sits near the EMA50. `OnTick` supplies the per-asset threshold so detection adapts to each instrument.

## Code
```mql5
// IntegratedPA_EA.mq5 (excerpt)
struct AssetConfig {
    string symbol;
    bool   enabled;
    double minLot;
    double maxLot;
    double lotStep;
    double tickValue;
    int    digits;
    double rangeThreshold; // new field
};
...
MARKET_PHASE phase = g_market.DetectPhase(symbol, MainTimeframe, g_assets[i].rangeThreshold);
```
```mql5
// MarketContext.mqh
MARKET_PHASE DetectPhase(const string symbol, ENUM_TIMEFRAMES tf, double range_threshold=10.0)
{
    double diff20_50 = MathAbs(ema20-ema50)/point;
    if(price>ema20 && ema20>ema50 && ema50>ema200 && diff20_50>range_threshold)
        return PHASE_TREND;
    // ... other conditions ...
}
```

## Manual Testing Instructions
- [ ] Compile the EA in MetaEditor and ensure no errors.
- [ ] Run the EA on different assets (BTCUSD, WDO, WINM25) and verify that phase detection adapts to volatility.
- [ ] Observe log outputs to confirm correct classification of market phases.

## Observations / Notes
- Threshold values are heuristic and may require tuning per broker.
- Range detection now depends on EMA proximity and price relative to EMA50.
