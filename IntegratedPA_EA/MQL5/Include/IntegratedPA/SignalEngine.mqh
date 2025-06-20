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
public:
   SignalEngine(){}
   ~SignalEngine(){}

   // Gera sinal principal
   Signal Generate(const string symbol,ENUM_TIMEFRAMES tf,const AssetConfig &asset)
   {
      Signal s; s.valid=false;

      if(UseSpikeAndChannel)
      {
         if(m_spikeAndChannel.Identify(symbol,tf,asset))
            return m_spikeAndChannel.GenerateSignal(symbol,tf,asset);
      }

      if(UsePullbackMA)
      {
         if(m_pullbackMA.Identify(symbol,tf,asset))
            return m_pullbackMA.GenerateSignal(symbol,tf,asset);
      }

      if(UseFibonacciRetrace)
      {
         if(m_fibRetrace.Identify(symbol,tf,asset))
            return m_fibRetrace.GenerateSignal(symbol,tf,asset);
      }

      if(UseBollingerStochastic)
      {
         if(m_bollStoch.Identify(symbol,tf,asset))
            return m_bollStoch.GenerateSignal(symbol,tf,asset);
      }

      if(UseTrendRangeDay)
      {
         if(m_trendRangeDay.Identify(symbol,tf,asset))
            return m_trendRangeDay.GenerateSignal(symbol,tf,asset);
      }

      if(UseRangeBreakout)
      {
         if(m_rangeBreakout.Identify(symbol,tf,asset))
            return m_rangeBreakout.GenerateSignal(symbol,tf,asset);
      }

      if(UseRangeFade)
      {
         if(m_rangeFade.Identify(symbol,tf,asset))
            return m_rangeFade.GenerateSignal(symbol,tf,asset);
      }

      if(UseWedgeReversal)
      {
         bool rising=false;
         if(m_wedgeRev.Identify(symbol,tf,rising,asset))
            return m_wedgeRev.GenerateSignal(symbol,tf,asset);
      }

      if(UseMeanReversion50200)
      {
         bool buy=false;
         if(m_meanRev.Identify(symbol,tf,buy,asset))
            return m_meanRev.GenerateSignal(symbol,tf,asset);
      }

      if(UseVWAPReversion)
      {
         bool buy2=false;
         if(m_vwapRev.Identify(symbol,tf,buy2,asset))
            return m_vwapRev.GenerateSignal(symbol,tf,asset);
      }

      return s;
   }

private:
   SpikeAndChannel      m_spikeAndChannel;
   PullbackToMA         m_pullbackMA;
   FibonacciRetrace     m_fibRetrace;
   BollingerStochastic  m_bollStoch;
   TrendRangeDay        m_trendRangeDay;
   RangeBreakout        m_rangeBreakout;
   RangeFade            m_rangeFade;
   WedgeReversal        m_wedgeRev;
   MeanReversion50to200 m_meanRev;
   VWAPReversion        m_vwapRev;
};

#endif // INTEGRATEDPA_SIGNALENGINE_MQH
