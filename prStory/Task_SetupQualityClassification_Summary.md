# Task: SetupQualityClassification
**Date:** 2025-06-13 18:41 UTC

## Problem
Signal quality was hardcoded as `SETUP_B` in all strategies, limiting the ability to adjust risk based on trade potential. The trading guide (lines 2399-2406 and 5445-5447) recommends weighting position size according to setup quality and risk/reward.

## Solution
Implemented a helper `EvaluateQuality` in `Utils.mqh` that grades setups using risk/reward ratio and volume confirmation. Updated each strategy's `GenerateSignal` to compute volume averages and apply this function, dynamically setting `s.quality`. Higher reward-to-risk and strong volume lead to `SETUP_A_PLUS` or `SETUP_A`, while weaker setups become `SETUP_C`.

## Code (excerpt)
```mql5
// Utils.mqh
inline SETUP_QUALITY EvaluateQuality(double rr,double vol_ratio)
{
   if(rr>=3.0 && vol_ratio>=1.5) return SETUP_A_PLUS;
   if(rr>=2.0 && vol_ratio>=1.0) return SETUP_A;
   if(rr>=1.5) return SETUP_B;
   return SETUP_C;
}
```
Each strategy now computes `rr` and `vol_ratio` before assigning `s.quality` via `EvaluateQuality`.

## Manual Testing Instructions
- [ ] Compile all files in MetaEditor (`IntegratedPA_EA.mq5`).
- [ ] Enable logging to confirm quality grades appear in generated signals.
- [ ] Verify different market conditions produce varying quality levels and that `RiskManager` adjusts volume accordingly.

## Observations / Notes
- Thresholds for volume and risk/reward are heuristic and may require tuning based on historical performance.
