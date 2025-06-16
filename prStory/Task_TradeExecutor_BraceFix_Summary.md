# Task: TradeExecutor Brace Fix
**Date:** 2025-06-13 19:25 UTC

## Problem
Compilation failed due to unmatched braces in `TradeExecutor.mqh` after adding the global variable cleanup logic.

## Solution
Balanced the closing braces inside `ManageOpenPositions` and ensured the cleanup call is outside the position loop. This resolves the `{` - unbalanced parentheses error during compilation.

## Code Snippet
```mql5
if(new_sl!=sl)
{
    m_trade.PositionModify(symbol,new_sl,0.0);
    if(m_logger!=NULL)
    {
        m_logger.Log(LOG_INFO,"Trailing stop moved");
        ENUM_ORDER_TYPE tmpType=(type==POSITION_TYPE_BUY?ORDER_TYPE_BUY:ORDER_TYPE_SELL);
        OrderRequest tmp; tmp.symbol=symbol; tmp.volume=volume; tmp.price=new_sl; tmp.sl=0; tmp.tp=0; tmp.type=tmpType; tmp.comment="Trail";
        m_logger.LogTrade("Trail",tmp,true);
    }
}
...
// remove stage variables for tickets no longer open
CleanupStageVariables();
```

## Manual Testing Instructions
- [ ] Compile the EA in MetaTrader 5 and confirm no syntax errors.
- [ ] Run the EA in strategy tester to verify trades are managed without errors.

## Observations
- Cleanup logic now executes after iterating all open positions, preventing stale global variables.
