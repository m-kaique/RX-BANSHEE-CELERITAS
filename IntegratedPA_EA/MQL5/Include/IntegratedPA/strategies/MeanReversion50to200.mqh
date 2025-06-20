#ifndef INTEGRATEDPA_MEANREV50TO200_MQH
#define INTEGRATEDPA_MEANREV50TO200_MQH
#include "../Defs.mqh"
#include "../Utils.mqh"
#include "StrategyBase.mqh"

//+------------------------------------------------------------------+
//| Mean Reversion from EMA50 to EMA200                              |
//| Implements the idea that price tends to return to the 200-period |
//| moving average after a strong move away from it (guide lines     |
//| around 1316-1455). This strategy enters near the midpoint        |
//| between EMA50 and EMA200 once price shows exhaustion.            |
//+------------------------------------------------------------------+
class MeanReversion50to200 : public IStrategy
{
public:
   MeanReversion50to200(){}
   ~MeanReversion50to200(){}
   string Name() const override { return "MR50to200"; }
   bool Identify(const string symbol,ENUM_TIMEFRAMES tf) override
   {
      bool dummy=false;
      return Identify(symbol,tf,dummy);
   }

   // Identify mean reversion opportunity
   bool Identify(const string symbol,ENUM_TIMEFRAMES tf,bool &buySignal)
   {
      double ema50 = GetEMA(symbol,tf,50);
      double ema200= GetEMA(symbol,tf,200);
      double price0= iClose(symbol,tf,0);
      double price1= iClose(symbol,tf,1);
      double avg=(ema50+ema200)/2.0;
      double point=SymbolInfoDouble(symbol,SYMBOL_POINT);

      // price currently near the average between 50 and 200
      bool nearAvg = MathAbs(price0-avg)<=5*point;
      // was far from the average on previous bar
      bool wasFar = MathAbs(price1-avg)>=20*point;
      if(!nearAvg || !wasFar)
         return false;

      if(ema50>ema200 && price0>avg)
      {
         buySignal=true;
         return true;
      }
      if(ema50<ema200 && price0<avg)
      {
         buySignal=false;
         return true;
      }
      return false;
   }

   // Generate trade signal
   Signal GenerateSignal(const string symbol,ENUM_TIMEFRAMES tf)
   {
      Signal s; s.valid=false;
      bool buy=false;
      if(!Identify(symbol,tf,buy))
         return s;

      double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
      double close0=iClose(symbol,tf,0);
      double low1 =iLow(symbol,tf,1);
      double high1=iHigh(symbol,tf,1);

      s.valid=true;
      s.phase=PHASE_REVERSAL;
      s.entry=close0;
      if(buy)
      {
         s.direction=SIGNAL_BUY;
         double stopPts=GuideStopPoints(symbol);
         double stop  = low1-stopPts*point;
         double target=s.entry+(s.entry-stop)*2.0; // 2R target
         s.stop = stop;
         s.target= target;
      }
      else
      {
         s.direction=SIGNAL_SELL;
         double stopPts=GuideStopPoints(symbol);
         double stop  = high1+stopPts*point;
         double target=s.entry-(stop-s.entry)*2.0;
         s.stop = stop;
         s.target= target;
      }
      s.timestamp=TimeCurrent();
      s.strategy="MeanRev50to200";

      const int lookback=20;
      double avgVol=0.0;
      for(int k=1;k<=lookback;k++)
         avgVol+=(double)iVolume(symbol,tf,k);
      avgVol/=lookback;
      double vol1=(double)iVolume(symbol,tf,1);
      double rr=(MathAbs(s.entry-s.stop)>0)?MathAbs(s.target-s.entry)/MathAbs(s.entry-s.stop):0.0;
      double vol_ratio=(avgVol>0.0)?vol1/avgVol:1.0;
      s.quality=EvaluateQuality(symbol,tf,rr,vol_ratio);
      return s;
   }

   SETUP_QUALITY ClassifyQuality(const string symbol,ENUM_TIMEFRAMES tf)
   {
      return SETUP_B;
   }
};

#endif // INTEGRATEDPA_MEANREV50TO200_MQH
