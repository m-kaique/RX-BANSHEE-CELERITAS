#ifndef INTEGRATEDPA_FIBONACCIRETRACE_MQH
#define INTEGRATEDPA_FIBONACCIRETRACE_MQH
#include "../Defs.mqh"
#include "../Utils.mqh"
#include "../MarketContext.mqh"

// Estrat\u00e9gia de revers\u00e3o na zona de ouro (61,8% de Fibonacci)
// Inspirada nas orienta\u00e7\u00f5es do guia de trading em torno das linhas
// 640-665 que destacam compras e vendas quando o pre\u00e7o reage ao n\u00edvel
// de 61,8% ap\u00f3s um movimento tendencial.
class FibonacciRetrace
{
private:
   double m_high;
   double m_low;
   bool   m_buySignal;
   MarketContextAnalyzer m_ctx;
public:
   FibonacciRetrace():m_high(0),m_low(0),m_buySignal(false){}
   ~FibonacciRetrace(){}

   // Identifica a presen\u00e7a de retra\u00e7\u00e3o at\u00e9 61,8% e candle de revers\u00e3o
   bool Identify(const string symbol,ENUM_TIMEFRAMES tf,const AssetConfig &asset)
   {
      if(m_ctx.DetectPhaseMTF(symbol,tf,asset.ctxTf,asset.rangeThreshold)!=PHASE_TREND)
         return false;
      const int lookback=50;
      int idxHigh=iHighest(symbol,tf,MODE_HIGH,lookback,1);
      int idxLow =iLowest(symbol,tf,MODE_LOW ,lookback,1);
      if(idxHigh==-1 || idxLow==-1)
         return false;
      m_high=iHigh(symbol,tf,idxHigh);
      m_low =iLow(symbol,tf,idxLow);
      if(m_high<=m_low)
         return false;

      bool up   = (idxHigh>idxLow); // alto depois do fundo -> tend\u00eancia de alta
      bool down = (idxLow>idxHigh); // fundo depois do alto -> tend\u00eancia de baixa
      if(!up && !down)
         return false;

      double diff=m_high-m_low;
      double level = up ? m_high - diff*0.618 : m_low + diff*0.618;

      double close0=iClose(symbol,tf,0);
      double open0 =iOpen(symbol,tf,0);
      double low0  =iLow(symbol,tf,0);
      double high0 =iHigh(symbol,tf,0);

      if(up && low0<=level && close0>level && close0>open0)
      {
         m_buySignal=true;
         return true;
      }
      if(down && high0>=level && close0<level && close0<open0)
      {
         m_buySignal=false;
         return true;
      }
      return false;
   }

   // Gera sinal de compra ou venda com stop ap\u00f3s o n\u00edvel de 61,8%
   Signal GenerateSignal(const string symbol,ENUM_TIMEFRAMES tf,const AssetConfig &asset)
   {
      Signal s; s.valid=false;
      if(!Identify(symbol,tf,asset))
         return s;

      double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
      double entry=iClose(symbol,tf,0);
      double stop,target;
      double diff=MathAbs(m_high-m_low);
      double stopPts=GuideStopPoints(symbol);
      if(m_buySignal)
      {
         stop   = MathMin(iLow(symbol,tf,0),m_low) - stopPts*point;
         // alvo de extensao 161,8% conforme guia linhas 655-658
         target = m_high + diff*0.618;
         s.direction=SIGNAL_BUY;
         s.phase=PHASE_TREND;
      }
      else
      {
         stop   = MathMax(iHigh(symbol,tf,0),m_high) + stopPts*point;
         target = m_low  - diff*0.618;
         s.direction=SIGNAL_SELL;
         s.phase=PHASE_TREND;
      }
      s.valid=true;
      s.entry=entry;
      s.stop =stop;
      s.target=target;
      s.timestamp=TimeCurrent();
      s.strategy="FibRetrace";

      const int lookbackVol=20;
      double avgVol=0.0;
      for(int k=1;k<=lookbackVol;k++)
         avgVol+=(double)iVolume(symbol,tf,k);
      avgVol/=lookbackVol;
      double vol1=(double)iVolume(symbol,tf,1);
      double rr=(MathAbs(entry-stop)>0)?MathAbs(target-entry)/MathAbs(entry-stop):0.0;
      double vol_ratio=(avgVol>0.0)?vol1/avgVol:1.0;
      s.quality=EvaluateQuality(symbol,tf,rr,vol_ratio);
      return s;
   }
};

#endif // INTEGRATEDPA_FIBONACCIRETRACE_MQH
