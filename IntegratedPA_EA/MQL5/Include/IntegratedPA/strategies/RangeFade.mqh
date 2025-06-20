#ifndef INTEGRATEDPA_RANGEFADE_MQH
#define INTEGRATEDPA_RANGEFADE_MQH
#include "../Defs.mqh"
#include "../MarketContext.mqh"

class RangeFade
{
private:
   double m_high;
   double m_low;
   bool   m_buySignal;
   MarketContextAnalyzer m_ctx;
public:
   RangeFade():m_high(0),m_low(0),m_buySignal(false){}
   ~RangeFade(){}

   // Identify rejection at range extremes
   bool Identify(const string symbol,ENUM_TIMEFRAMES tf,const AssetConfig &asset)
   {
      if(m_ctx.DetectPhaseMTF(symbol,tf,asset.ctxTf,asset.rangeThreshold)!=PHASE_RANGE)
         return false;
      const int lookback=20;
      int idxHigh=iHighest(symbol,tf,MODE_HIGH,lookback,1);
      int idxLow =iLowest(symbol,tf,MODE_LOW, lookback,1);
      if(idxHigh==-1 || idxLow==-1)
         return false;
      m_high=iHigh(symbol,tf,idxHigh);
      m_low =iLow(symbol,tf,idxLow);
      double range=m_high-m_low;
      if(range<=0.0)
         return false;
      double close1=iClose(symbol,tf,1);
      double open1 =iOpen(symbol,tf,1);
      double threshold=range*0.1; // 10% of range

      if((close1-m_low)<=threshold && close1>open1)
      {
         m_buySignal=true;
         return true;
      }
      if((m_high-close1)<=threshold && close1<open1)
      {
         m_buySignal=false;
         return true;
      }
      return false;
   }

   // Generate trade signal fading the range extreme
   Signal GenerateSignal(const string symbol,ENUM_TIMEFRAMES tf,const AssetConfig &asset)
   {
      Signal s; s.valid=false;
      if(!Identify(symbol,tf,asset))
         return s;

      double range=m_high-m_low;
      double entry=iClose(symbol,tf,1);
      if(m_buySignal)
      {
         s.valid=true;
         s.direction=SIGNAL_BUY;
         s.phase=PHASE_RANGE;
         s.entry=entry;
         double stop  = m_low - range*0.2;     // stop beyond range
         double target= m_high;               // aim for opposite extreme
         s.stop = stop;
         s.target = target;
         s.timestamp=TimeCurrent();
         s.strategy="RangeFade";
      }
      else
      {
         s.valid=true;
         s.direction=SIGNAL_SELL;
         s.phase=PHASE_RANGE;
         s.entry=entry;
         double stop  = m_high + range*0.2;
         double target= m_low;
         s.stop = stop;
         s.target = target;
         s.timestamp=TimeCurrent();
         s.strategy="RangeFade";
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

#endif // INTEGRATEDPA_RANGEFADE_MQH
