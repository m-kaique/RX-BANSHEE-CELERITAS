# Task: DailyReport
**Date:** 2025-06-13 23:59 UTC

## Problem
The trading guide (lines 3433-3460) emphasizes a post-market analysis phase with detailed logs and performance metrics. The EA only wrote real-time logs and lacked any summary statistics for the trading day.

## Solution
Implemented an automatic daily report generator. On each day reset and on EA shutdown, `GenerateDailyReport()` gathers the day's trade history using `HistorySelect` and computes total trades, wins, losses, win percentage, net profit and profit factor. Results are appended to `IntegratedPA_EA_report.csv` alongside the EA's log files.

Key excerpt:
```mql5
if(g_dailyStart>0)
    GenerateDailyReport();
```

## Manual Testing Instructions
- [ ] Compile `IntegratedPA_EA.mq5` in MetaEditor.
- [ ] Run the EA for a day with some trades.
- [ ] At the end of the day or when closing the EA, verify `IntegratedPA_EA_report.csv` is created near the `.ex5` file with the day's statistics.

## Observations / Notes
- Only closed deals within the 24h window are counted. Overnight positions are ignored.
