#ifndef INTEGRATEDPA_RANGEBREAKOUT_MQH
#define INTEGRATEDPA_RANGEBREAKOUT_MQH
#include "../Defs.mqh"
#include "../Utils.mqh"
#include "StrategyBase.mqh"

class RangeBreakout : public IStrategy
{
private:
   double m_high;
   double m_low;
   bool   m_buySignal;
public:
   RangeBreakout():m_high(0),m_low(0),m_buySignal(false){}
   ~RangeBreakout(){}
   string Name() const override { return "RangeBreak"; }

   // Identify breakout beyond range boundaries with volume/VWAP confirmation
   bool Identify(const string symbol,ENUM_TIMEFRAMES tf)
   {
      const int lookback=20;
      int idxHigh=iHighest(symbol,tf,MODE_HIGH,lookback,2);
      int idxLow =iLowest(symbol,tf,MODE_LOW, lookback,2);
      if(idxHigh==-1 || idxLow==-1)
         return false;
      m_high=iHigh(symbol,tf,idxHigh);
      m_low =iLow(symbol,tf,idxLow);
      double range=m_high-m_low;
      if(range<=0.0)
         return false;
      double close1=iClose(symbol,tf,1);
      double open1 =iOpen(symbol,tf,1);

      // volume médio para confirmação (Ferramentas Essenciais - Volume)
      double avgVol=0.0;
      for(int k=1;k<=lookback;k++)
         avgVol += (double)iVolume(symbol,tf,k); // cast avoids long->double warning
      avgVol/=lookback;
      double vol1 = (double)iVolume(symbol,tf,1); // explicit cast

      // VWAP do dia para filtrar direção (Ferramentas Essenciais - VWAP)
      double vwap=GetVWAP(symbol,tf);

      if(close1>m_high && close1>open1)
      {
         if(vol1>avgVol && close1>vwap)
         {
            m_buySignal=true;
            return true;
         }
      }
      if(close1<m_low && close1<open1)
      {
         if(vol1>avgVol && close1<vwap)
         {
            m_buySignal=false;
            return true;
         }
      }
      return false;
   }

   // Generate breakout signal using range projection
   Signal GenerateSignal(const string symbol,ENUM_TIMEFRAMES tf)
   {
      Signal s; s.valid=false;
      if(!Identify(symbol,tf))
         return s;

      double range=m_high-m_low;
      double entry=iClose(symbol,tf,1);
      double stop, target;
      if(m_buySignal)
      {
         s.valid=true;
         s.direction=SIGNAL_BUY;
         s.phase=PHASE_RANGE;
         s.entry=entry;
         stop   = m_high - range*0.2;   // stop below breakout level
         target = entry + range;        // projected range
         s.stop = stop;
         s.target = target;
         s.timestamp=TimeCurrent();
         s.strategy="RangeBreak";
      }
      else
      {
         s.valid=true;
         s.direction=SIGNAL_SELL;
         s.phase=PHASE_RANGE;
         s.entry=entry;
         stop   = m_low + range*0.2;
         target = entry - range;
         s.stop = stop;
         s.target = target;
         s.timestamp=TimeCurrent();
         s.strategy="RangeBreak";
      }

      // determine quality based on RR and volume (guia linhas 2399-2406 e 3406-3077)
      const int lookback=20;
      double avgVol=0.0;
      for(int k=1;k<=lookback;k++)
         avgVol+=(double)iVolume(symbol,tf,k);
      avgVol/=lookback;
      double vol1=(double)iVolume(symbol,tf,1);
      double rr=(MathAbs(entry-stop)>0)?MathAbs(target-entry)/MathAbs(entry-stop):0.0;
      double vol_ratio=(avgVol>0.0)?vol1/avgVol:1.0;
      s.quality=EvaluateQuality(symbol,tf,rr,vol_ratio);
      return s;
   }
};

#endif // INTEGRATEDPA_RANGEBREAKOUT_MQH
