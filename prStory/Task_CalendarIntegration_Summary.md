# Task: CalendarIntegration
**Date:** 2025-06-14 17:42 UTC

## Problem
The EA lacked integration with the economic calendar. News windows were manually configured only via `NewsTimes`, ignoring relevant events for the actively traded symbols.

## Solution
Implemented `NewsCalendar` wrapper around the `Calendar.mqh` module. The class supports setting active symbols and currencies, loading events and filling `g_news` for automatic blocking. `IntegratedPA_EA.mq5` now initializes this calendar using assets loaded from `assets.csv`, refreshes it daily and checks `IsNewsNow()` on every tick before generating signals. After review, event filtering now uses the `Currency` field and the calendar loader relies on `m_cal.Set()` to fetch events. Compile issues were fixed.

## Code
```mql5
// NewsCalendar.mqh
class NewsCalendar
{
   CALENDAR m_cal;
   string   m_currencies;
   string   m_symbols[];
   void SetActiveSymbols(string &symbols[]) { ArrayCopy(m_symbols,symbols); }
   void LoadRange(datetime from,datetime to) { /* loads events and populates g_news */ }
};
```

```mql5
// IntegratedPA_EA.mq5 (excerpt)
#include <IntegratedPA/NewsCalendar.mqh>
NewsCalendar g_calendar;
...
   g_calendar.SetCurrencies(NewsCurrencies);
   g_calendar.SetActiveSymbols(activeSymbols);
   g_calendar.Clear();
   g_calendar.LoadToday();
...
   if(g_calendar.IsNewsNow())
      return;
```

## Manual Testing Instructions
- [ ] Compile `IntegratedPA_EA.mq5` in MetaEditor.
- [ ] Ensure the terminal has calendar access enabled.
- [ ] Run the EA and observe log entries skipping trading during scheduled news.

## Observations / Notes
- Events are filtered by symbols read from `assets.csv` to avoid duplicate configuration.
- Calendar reloads at the start of each trading day via `ResetDailyLimits`.
- Compile issues were corrected by declaring `extern SessionRange g_news[]` and
  converting `STRING4` to `string` using `Currency[]`.
