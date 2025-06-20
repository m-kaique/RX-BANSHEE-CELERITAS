// Definições padrão para evitar erros do linter
// Estas serão sobrescritas pelos valores reais quando incluído no EA principal
#ifndef HAS_USE_SPIKE_AND_CHANNEL
   #define UseSpikeAndChannel false
#endif

#ifndef HAS_USE_RANGE_BREAKOUT
   #define UseRangeBreakout false
#endif

#ifndef HAS_USE_RANGE_FADE
   #define UseRangeFade false
#endif

#ifndef HAS_USE_WEDGE_REVERSAL
   #define UseWedgeReversal false
#endif

#ifndef HAS_USE_MEAN_REV_50200
   #define UseMeanReversion50200 false
#endif

#ifndef HAS_USE_VWAP_REVERSION
   #define UseVWAPReversion false
#endif

#ifndef HAS_USE_PULLBACK_MA
   #define UsePullbackMA false
#endif

#ifndef HAS_USE_FIBONACCI_RETRACE
   #define UseFibonacciRetrace false
#endif

#ifndef HAS_USE_BOLLINGER_STOCH
   #define UseBollingerStochastic false
#endif

#ifndef HAS_USE_TREND_RANGE_DAY
   #define UseTrendRangeDay false
#endif

#ifndef INTEGRATEDPA_SIGNALENGINE_MQH
#define INTEGRATEDPA_SIGNALENGINE_MQH
#include "Defs.mqh"
#include "Utils.mqh"
#include "strategies/StrategyBase.mqh"
#include "strategies/TrendRangeDay.mqh"
#include "strategies/WedgeReversal.mqh"
#include "strategies/SpikeAndChannel.mqh"
#include "strategies/PullbackToMA.mqh"
#include "strategies/RangeFade.mqh"
#include "strategies/RangeBreakout.mqh"
#include "strategies/MeanReversion50to200.mqh"
#include "strategies/VWAPReversion.mqh"
#include "strategies/BollingerStochastic.mqh"
#include "strategies/FibonacciRetrace.mqh"
 

class SignalEngine
{
private:
   IStrategy *m_trend[];
   IStrategy *m_range[];
   IStrategy *m_reversal[];

   void AddTrend(IStrategy *s)
   {
      int n=ArraySize(m_trend);
      ArrayResize(m_trend,n+1);
      m_trend[n]=s;
   }

   void AddRange(IStrategy *s)
   {
      int n=ArraySize(m_range);
      ArrayResize(m_range,n+1);
      m_range[n]=s;
   }

   void AddReversal(IStrategy *s)
   {
      int n=ArraySize(m_reversal);
      ArrayResize(m_reversal,n+1);
      m_reversal[n]=s;
   }

public:
   SignalEngine()
   {
      ArrayResize(m_trend,0);
      ArrayResize(m_range,0);
      ArrayResize(m_reversal,0);

      if(UseSpikeAndChannel)    AddTrend(new SpikeAndChannel());
      if(UsePullbackMA)         AddTrend(new PullbackToMA());
      if(UseFibonacciRetrace)   AddTrend(new FibonacciRetrace());
      if(UseBollingerStochastic)AddTrend(new BollingerStochastic());
      if(UseTrendRangeDay)      AddTrend(new TrendRangeDay());

      if(UseRangeBreakout)      AddRange(new RangeBreakout());
      if(UseRangeFade)          AddRange(new RangeFade());

      if(UseWedgeReversal)      AddReversal(new WedgeReversal());
      if(UseMeanReversion50200) AddReversal(new MeanReversion50to200());
      if(UseVWAPReversion)      AddReversal(new VWAPReversion());
   }

   ~SignalEngine()
   {
      for(int i=0;i<ArraySize(m_trend);i++)   delete m_trend[i];
      for(int i=0;i<ArraySize(m_range);i++)   delete m_range[i];
      for(int i=0;i<ArraySize(m_reversal);i++)delete m_reversal[i];
   }

   Signal Generate(const string symbol,MARKET_PHASE phase,ENUM_TIMEFRAMES tf)
   {
      IStrategy **list=NULL;
      int count=0;
      if(phase==PHASE_TREND){ list=m_trend; count=ArraySize(m_trend); }
      else if(phase==PHASE_RANGE){ list=m_range; count=ArraySize(m_range); }
      else if(phase==PHASE_REVERSAL){ list=m_reversal; count=ArraySize(m_reversal); }
      Signal s; s.valid=false;
      for(int i=0;i<count;i++)
      {
         if(list[i].Identify(symbol,tf))
            return list[i].GenerateSignal(symbol,tf);
      }
      return s;
   }
};

#endif // INTEGRATEDPA_SIGNALENGINE_MQH
