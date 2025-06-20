#ifndef INTEGRATEDPA_VWAPREVERSION_MQH
#define INTEGRATEDPA_VWAPREVERSION_MQH
#include "../Defs.mqh"
#include "../Utils.mqh"
#include "StrategyBase.mqh"

class VWAPReversion : public IStrategy
{
public:
   VWAPReversion(){}
   ~VWAPReversion(){}
   string Name() const override { return "VWAPRev"; }

   // Identify when price is stretched away from VWAP and showing exhaustion
   bool Identify(const string symbol,ENUM_TIMEFRAMES tf,bool &buySignal)
   {
      double vwap = GetVWAP(symbol,tf);
      double atr  = GetATR(symbol,tf,14);
      if(atr<=0.0) return false;

      double close1=iClose(symbol,tf,1);
      double close0=iClose(symbol,tf,0);
      double diff1=MathAbs(close1-vwap);
      buySignal=false;

      // price was far from VWAP (>2 ATR) and closes back toward it
      if(diff1>2*atr)
      {
         if(close1>vwap && close0<close1)
         {
            buySignal=false; // expecting drop back to VWAP
            return true;
         }
         if(close1<vwap && close0>close1)
         {
            buySignal=true; // expecting rise back to VWAP
            return true;
         }
      }
      return false;
   }

   // Generate trade signal targeting the VWAP
   Signal GenerateSignal(const string symbol,ENUM_TIMEFRAMES tf)
   {
      Signal s; s.valid=false;
      bool buy=false;
      if(!Identify(symbol,tf,buy))
         return s;

      double vwap = GetVWAP(symbol,tf);
      double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
      double high1=iHigh(symbol,tf,1);
      double low1 =iLow(symbol,tf,1);
      double entry=iClose(symbol,tf,0);

      s.valid=true;
      s.phase=PHASE_REVERSAL;
      s.entry=entry;
      s.timestamp=TimeCurrent();
      s.strategy="VWAPRev";
      double stopPts=GuideStopPoints(symbol);
      if(buy)
      {
         s.direction=SIGNAL_BUY;
         s.stop  = low1-stopPts*point;
         s.target= vwap;
      }
      else
      {
         s.direction=SIGNAL_SELL;
         s.stop  = high1+stopPts*point;
         s.target= vwap;
      }

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
};

#endif // INTEGRATEDPA_VWAPREVERSION_MQH
