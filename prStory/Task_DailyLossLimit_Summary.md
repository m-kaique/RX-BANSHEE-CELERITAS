# Task: DailyLossLimit
**Date:** 2025-06-13 19:53 UTC

## Problem
The trading guide advises setting a daily loss limit and stopping trading once reached. The EA had no mechanism to respect this risk control, allowing trades even after significant drawdown.

## Solution
Added a `DailyLossPercent` input and implemented logic to track equity from the start of each day. When losses exceed the configured percentage, new trades are blocked for the remainder of the day. Counters reset at midnight. Logging notifies when the limit is hit.

## Code
```mql5
input double DailyLossPercent = 3.0; // stop trading after X% daily loss

void ResetDailyLoss(){
    MqlDateTime tm; TimeToStruct(TimeCurrent(),tm);
    tm.hour=0; tm.min=0; tm.sec=0;
    g_dailyStart=StructToTime(tm);
    g_dailyStartEquity=AccountInfoDouble(ACCOUNT_EQUITY);
    g_dailyPaused=false;
}

void CheckDailyLoss(){
    if(TimeCurrent()>=g_dailyStart+86400)
        ResetDailyLoss();
    double loss=g_dailyStartEquity-AccountInfoDouble(ACCOUNT_EQUITY);
    double limit=g_dailyStartEquity*(DailyLossPercent/100.0);
    if(!g_dailyPaused && loss>=limit){
        g_dailyPaused=true;
        if(g_log) g_log.Log(LOG_WARNING,"Daily loss limit reached, trading paused");
    }
}
```

## Manual Testing Instructions
- [ ] Compile `IntegratedPA_EA.mq5` in MetaEditor.
- [ ] Run the EA on a demo account and intentionally cause losses to exceed the configured percentage.
- [ ] Confirm that no new orders are placed after the limit triggers and that a warning appears in the logs.
- [ ] Verify trading resumes automatically the next day.

## Observations / Notes
- Uses equity to approximate realized losses; floating P&L may trigger the limit sooner if large positions are open.
