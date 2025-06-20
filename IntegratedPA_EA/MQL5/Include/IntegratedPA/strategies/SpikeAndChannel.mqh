#ifndef INTEGRATEDPA_SPIKEANDCHANNEL_MQH
#define INTEGRATEDPA_SPIKEANDCHANNEL_MQH
#include "../Defs.mqh"
#include "../Utils.mqh"
#include "../MarketContext.mqh"

class SpikeAndChannel
{
public:
   SpikeAndChannel(){}
   ~SpikeAndChannel(){}

   // Identify a Spike and Channel pattern using a simplified rule set
   bool Identify(const string symbol,ENUM_TIMEFRAMES tf,const AssetConfig &asset)
   {
      MarketContextAnalyzer ctx;
      if(ctx.DetectPhaseMTF(symbol,tf,asset.ctxTf,asset.rangeThreshold)!=PHASE_TREND)
         return false;
      // skip if price is in mean reversion zone between EMA50 and EMA200
      if(CheckMeanReversion50to200(symbol,tf))
         return false;

      // According to the trading guide lines 3874-3884, a spike is 3-5 strong
      // bars with little overlap. We approximate this by checking that the
      // last three bars closed strongly in the same direction.

      const int spikeBars=3;
      const double bodyFactor=0.6; // body must be at least 60% of range

      bool upSpike=true;
      for(int i=spikeBars;i>=1;i--)
      {
         double o=iOpen(symbol,tf,i);
         double c=iClose(symbol,tf,i);
         double h=iHigh(symbol,tf,i);
         double l=iLow(symbol,tf,i);
         double range=h-l;
         if(c<=o) {upSpike=false; break;}
         if(range<=0.0 || (c-o)<range*bodyFactor) {upSpike=false; break;}
         if(i<spikeBars && c<=iClose(symbol,tf,i+1)) {upSpike=false; break;}
      }

      bool downSpike=true;
      for(int i=spikeBars;i>=1;i--)
      {
         double o=iOpen(symbol,tf,i);
         double c=iClose(symbol,tf,i);
         double h=iHigh(symbol,tf,i);
         double l=iLow(symbol,tf,i);
         double range=h-l;
         if(c>=o) {downSpike=false; break;}
         if(range<=0.0 || (o-c)<range*bodyFactor) {downSpike=false; break;}
         if(i<spikeBars && c>=iClose(symbol,tf,i+1)) {downSpike=false; break;}
      }

      bool validar =  (upSpike || downSpike);
      return validar;
   }

   // Generate a basic trade signal when a spike is detected
   Signal GenerateSignal(const string symbol,ENUM_TIMEFRAMES tf,const AssetConfig &asset)
   {
      Print("GenerateSignal VALIDANDO SPIKE AND CHANNEL..........");
      Signal s; s.valid=false;
      double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
      if(!Identify(symbol,tf,asset))
      {
         Print("GenerateSignal FALHOU DESGRAÇADAMENTE..........");
         return s;
      }

      
// ##################################################################################################
      double close0=iClose(symbol,tf,1);
      double low1=iLow(symbol,tf,1);
      double high1=iHigh(symbol,tf,1);
// ##################################################################################################

      // COMPRA
      if(iClose(symbol,tf,1)>iOpen(symbol,tf,1))
      {
         s.valid=true;
         s.direction=SIGNAL_BUY;
         s.phase=PHASE_TREND;
         s.entry=close0;
         double stopPts=GuideStopPoints(symbol);
         double stop  = low1-stopPts*point;
         double target= s.entry+(s.entry-stop)*2.0; // 2R
         s.stop=stop;
         s.target=target;
         s.timestamp=TimeCurrent();
         s.strategy="SpikeChannel";
      }
      // VENDA
      else if(iClose(symbol,tf,1)<iOpen(symbol,tf,1))
      {
         s.valid=true;
         s.direction=SIGNAL_SELL;
         s.phase=PHASE_TREND;
         s.entry=close0;
         double stopPts=GuideStopPoints(symbol);
         double stop  = high1+stopPts*point;
         double target= s.entry-(stop-s.entry)*2.0;
         s.stop=stop;
         s.target=target;
         s.timestamp=TimeCurrent();
         s.strategy="SpikeChannel";
      }

      s.quality=ClassifyQuality(symbol, tf);
      
      Print("ENCONTRADO E VALIDADO SINAL SPIKE AND CHANNEL..........");
      return s;
   }

   SETUP_QUALITY ClassifyQuality(const string symbol,ENUM_TIMEFRAMES tf)
   {  
      return SETUP_B;
   }
};

#endif // INTEGRATEDPA_SPIKEANDCHANNEL_MQH