# Task: StrategyToggle Fix
**Date:** 2025-06-13 21:15 UTC

## Problem
Compilation failed due to strategy toggle inputs being declared before including `SignalEngine.mqh`. The header also declared `extern` variables, causing type conflicts.

## Solution
Moved the include of `SignalEngine.mqh` after the input variables so the header sees the definitions first. Adjusted `StringSplit` calls to use character delimiters to silence warnings.

## Code Snippet
```mql5
// IntegratedPA_EA.mq5
after input declarations
#include <IntegratedPA/SignalEngine.mqh>

int ParseMinutes(const string hhmm)
{
   string parts[];
   if(StringSplit(hhmm,':',parts)!=2)
      return -1;
   ...
}
```

## Manual Testing Instructions
- [ ] Compile `IntegratedPA_EA.mq5` in MetaEditor and ensure no variable redefinition errors.
- [ ] Run the EA to verify session parsing works without warnings.

## Observations / Notes
- Initially `SignalEngine.mqh` declared the strategy toggles as `extern` variables which conflicted with the `input` qualifiers. These extern declarations were removed so the header simply references the global inputs.
