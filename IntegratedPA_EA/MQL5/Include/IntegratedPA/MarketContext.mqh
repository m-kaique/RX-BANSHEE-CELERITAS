#ifndef INTEGRATEDPA_MARKETCONTEXT_MQH
#define INTEGRATEDPA_MARKETCONTEXT_MQH
#include "Utils.mqh"
#include "Logger.mqh"

/// Informacoes retornadas pela analise de contexto
struct PhaseInfo
{
   MARKET_PHASE phase; ///< fase detectada
   string desc;        ///< justificativa tecnica
};

// parametros padrao de indicadores
#define DEFAULT_RSI_PERIOD 14
#define DEFAULT_ATR_PERIOD 14

/// Classe responsavel por avaliar o contexto de mercado
class MarketContextAnalyzer
{
public:
   MarketContextAnalyzer():m_logger(NULL) {}
   ~MarketContextAnalyzer() {}
   void SetLogger(Logger *logger){m_logger=logger;}

private:
   Logger *m_logger;
   // suporte e resistencia em varios timeframes
   SRLevels sr_macro, sr_alto, sr_medio, sr_micro;
   // garante que ha historico suficiente
   bool EnsureHistory(const string symbol, ENUM_TIMEFRAMES tf, int bars)
   {
      MqlRates rates[];
      if (CopyRates(symbol, tf, 0, bars, rates) != bars)
         return false;
      return true;
   }

   // obtém valores do MACD (linha principal e sinal)
   bool GetMACD(const string symbol, ENUM_TIMEFRAMES tf, int fast, int slow, int signal,
                double &main, double &sig)
   {
      int handle = iMACD(symbol, tf, fast, slow, signal, PRICE_CLOSE);
      if (handle == INVALID_HANDLE)
         return false;
      double bufMain[1];
      double bufSig[1];
      bool ok = (CopyBuffer(handle, 0, 0, 1, bufMain) == 1 &&
                 CopyBuffer(handle, 1, 0, 1, bufSig) == 1);
      IndicatorRelease(handle);
      if (!ok)
         return false;
      main = bufMain[0];
      sig = bufSig[0];
      return true;
   }

   // detecta um pinbar simples
   bool IsPinbar(const string symbol, ENUM_TIMEFRAMES tf, int shift = 0)
   {
      double open = iOpen(symbol, tf, shift);
      double close = iClose(symbol, tf, shift);
      double high = iHigh(symbol, tf, shift);
      double low = iLow(symbol, tf, shift);
      double body = MathAbs(close - open);
      double range = high - low;
      if (range <= 0.0)
         return false;
      double upper = high - MathMax(open, close);
      double lower = MathMin(open, close) - low;
      return (body / range <= 0.3 &&
              ((upper >= 2 * body && upper >= 0.5 * range) ||
               (lower >= 2 * body && lower >= 0.5 * range)));
   }

   // detecta candle engulfing basico
   bool IsEngulfing(const string symbol, ENUM_TIMEFRAMES tf)
   {
      double o0 = iOpen(symbol, tf, 0);
      double c0 = iClose(symbol, tf, 0);
      double o1 = iOpen(symbol, tf, 1);
      double c1 = iClose(symbol, tf, 1);
      bool bull0 = c0 > o0;
      bool bull1 = c1 > o1;
      if (bull0 && !bull1 && c0 > o1 && o0 < c1)
         return true;
      if (!bull0 && bull1 && c0 < o1 && o0 > c1)
         return true;
      return false;
   }

   //=======================================================================
   // IsTrendPhase() implementa o conceito de "trend transition" de Al Brooks
   // para entradas mais rápidas quando EMA9 cruza EMA21 e as EMAs de 21 e 50
   // apontam na mesma direção. A EMA200 é usada apenas como contexto.
   //=======================================================================
   bool IsTrendPhase(const string symbol, ENUM_TIMEFRAMES tf, double rangeThr, string &desc)
   {
      // Verificar se há dados suficientes
      if (!EnsureHistory(symbol, tf, 200))
      {
         desc = "historico insuficiente";
         return false;
      }

      // Obter valores das EMAs usando utils.mqh
      double ema9 = GetEMA(symbol, tf, 9);
      double ema21 = GetEMA(symbol, tf, 21);
      double ema50 = GetEMA(symbol, tf, 50);
      double ema200 = GetEMA(symbol, tf, 200);

      if (ema9 == 0.0 || ema21 == 0.0 || ema50 == 0.0 || ema200 == 0.0)
      {
         desc = "erro ao obter EMAs";
         return false;
      }

      // Verificar alinhamento das médias móveis considerando "trend transition"
      double slope21 = GetEMASlope(symbol, tf, 21, 3);
      double slope50 = GetEMASlope(symbol, tf, 50, 3);
      bool upTrendAlignment = (ema9 > ema21 && slope21 > 0 && slope50 > 0);
      bool downTrendAlignment = (ema9 < ema21 && slope21 < 0 && slope50 < 0);
      bool above200 = (ema50 > ema200);
      bool below200 = (ema50 < ema200);

      if (!upTrendAlignment && !downTrendAlignment)
      {
         return false;
      }

      // Verificar momentum com MACD
      double macdMain, macdSig;
      if (!GetMACD(symbol, tf, 12, 26, 9, macdMain, macdSig))
      {
         desc = "erro ao obter MACD";
         return false;
      }

      bool upMomentum = (macdMain > macdSig && macdMain > 0);
      bool downMomentum = (macdMain < macdSig && macdMain < 0);

      // Verificar RSI
      double rsi = GetRSI(symbol, tf, 14);
      if (rsi == 0.0)
      {
         desc = "erro ao obter RSI";
         return false;
      }

      // Verificar condições de tendência de alta
      if (upTrendAlignment && upMomentum && rsi > 55)
      {
         desc = "Alta transição: EMA9>EMA21, slopes +, MACD>signal, RSI=" +
                DoubleToString(rsi, 1);
         if (above200)
            desc += ", acima da EMA200";
         if(m_logger!=NULL)
            m_logger.Log(LOG_DEBUG,"[TrendPhase " + symbol + " " + EnumToString(tf) + "] " + desc);
         else
            Print("TrendPhase:"+symbol+" "+EnumToString(tf)+" - "+desc);
         return true;
      }

      // Verificar condições de tendência de baixa
      if (downTrendAlignment && downMomentum && rsi < 45)
      {
         desc = "Baixa transição: EMA9<EMA21, slopes -, MACD<signal, RSI=" +
                DoubleToString(rsi, 1);
         if (below200)
            desc += ", abaixo da EMA200";
         if(m_logger!=NULL)
            m_logger.Log(LOG_DEBUG,"[TrendPhase " + symbol + " " + EnumToString(tf) + "] " + desc);
         else
            Print("TrendPhase:"+symbol+" "+EnumToString(tf)+" - "+desc);
         return true;
      }

      desc = "Sem Tendência em: " +  EnumToString(tf);
         if(m_logger!=NULL)
            m_logger.Log(LOG_DEBUG,"[TrendPhase " + symbol + " " + EnumToString(tf) + "] " + desc);
         else
            Print("TrendPhase:"+symbol+" "+EnumToString(tf)+" - "+desc);

      return false;
   }
   
   bool IsRangePhase(const string symbol, ENUM_TIMEFRAMES tf, double rangeThr, string &desc)
   {
      double ema20 = GetEMA(symbol, tf, EMA_FAST_PERIOD);
      double ema50 = GetEMA(symbol, tf, EMA_MEDIUM_PERIOD);
      double sma200 = GetEMA(symbol, tf, EMA_SLOW_PERIOD);
      double rsi = GetRSI(symbol, tf, DEFAULT_RSI_PERIOD);
      double atr = GetATR(symbol, tf, DEFAULT_ATR_PERIOD);
      double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
      double diff20_50 = MathAbs(ema20 - ema50) / point;
      double diff50_200 = MathAbs(ema50 - sma200) / point;
      bool emaClose = (diff20_50 <= rangeThr && diff50_200 <= rangeThr);
      bool rsiMid = (rsi >= 40 && rsi <= 60);
      bool atrLow = (atr / point <= rangeThr);
      if (emaClose && rsiMid && atrLow)
      {
         desc = "EMAs proximas, RSI=" + DoubleToString(rsi, 1) + ", ATR baixo";
         return true;
      }
      return false;
   }

   bool IsReversalPhase(const string symbol, ENUM_TIMEFRAMES tf, string &desc)
   {
      double rsi0 = GetRSI(symbol, tf, DEFAULT_RSI_PERIOD, 0);
      double rsi1 = GetRSI(symbol, tf, DEFAULT_RSI_PERIOD, 1);
      double price0 = iClose(symbol, tf, 0);
      double price1 = iClose(symbol, tf, 1);
      bool bearishDiv = (price0 > price1 && rsi0 < rsi1 && rsi0 > 70);
      bool bullishDiv = (price0 < price1 && rsi0 > rsi1 && rsi0 < 30);
      bool overbought = (rsi0 > 75);
      bool oversold = (rsi0 < 25);
      bool candle = (IsPinbar(symbol, tf) || IsEngulfing(symbol, tf));
      if ((bearishDiv && overbought) || (bullishDiv && oversold) || ((overbought || oversold) && candle))
      {
         desc = "Divergencia RSI e candle de reversao";
         return true;
      }
      return false;
   }

public:
   /// Analisa apenas um timeframe
   PhaseInfo DetectPhaseSingle(const string symbol, ENUM_TIMEFRAMES tf, double rangeThr = 10.0)
   {
      PhaseInfo info;
      info.phase = PHASE_UNDEFINED;
      info.desc = "";
      if (!EnsureHistory(symbol, tf, 200))
      {
         info.desc = "historico insuficiente";
         return info;
      }
      string d;
      if (IsTrendPhase(symbol, tf, rangeThr, d))
      {
         info.phase = PHASE_TREND;
         info.desc = d;
      }
      // if (IsRangePhase(symbol, tf, rangeThr, d))
      // {
      //    info.phase = PHASE_RANGE;
      //    info.desc = d;
      // }
      // else if (IsReversalPhase(symbol, tf, d))
      // {
      //    info.phase = PHASE_REVERSAL;
      //    info.desc = d;
      // }
      else
      {
         info.desc = "condicoes neutras";
      }
      return info;
   }

   /// Analise multi-timeframe ate 4 periodos
   /// Usa IsTrendPhase com a lógica de "trend transition" para confirmar
   /// o contexto do timeframe maior antes de atuar no menor.
   PhaseInfo DetectPhaseMTF(const string symbol, const ENUM_TIMEFRAMES &tfs[], int count,
                            double rangeThr = 10.0)
   {
      string tfList="";
      for(int i=0;i<count && i<4;i++)
         tfList+=((i>0)?", ":"")+EnumToString(tfs[i]);
      if(m_logger!=NULL)
         m_logger.Log(LOG_DEBUG,"[DetectPhaseMTF " + symbol + "] tfs=" + tfList);
      else
         Print("DetectPhaseMTF " + symbol + " tfs=" + tfList);

      PhaseInfo localInfos[4];
      string details = "";
      int use = (count > 4) ? 4 : count;
      for (int i = 0; i < use; i++)
      {
         localInfos[i] = DetectPhaseSingle(symbol, tfs[i], rangeThr);
         details += EnumToString(tfs[i]) + ":" + localInfos[i].desc + " ";
      }
      MARKET_PHASE phase = localInfos[use - 1].phase; // comeca pelo timeframe mais alto fornecido
      for (int j = use - 2; j >= 0; j--)
      {
         MARKET_PHASE ctx = phase;
         MARKET_PHASE local = localInfos[j].phase;
         if (ctx == local)
            phase = local;
         else if (ctx != PHASE_UNDEFINED)
            phase = ctx;
         else
            phase = local;
      }
      PhaseInfo res;
      res.phase = phase;
      res.desc = details;
      return res;
   }

   // versoes compativeis com a implementacao antiga
   MARKET_PHASE DetectPhase(const string symbol, ENUM_TIMEFRAMES tf, double rangeThr = 10.0)
   {
      return DetectPhaseSingle(symbol, tf, rangeThr).phase;
   }

   MARKET_PHASE DetectPhaseMTF(const string symbol, ENUM_TIMEFRAMES tf, ENUM_TIMEFRAMES ctxTf, double rangeThr = 10.0)
   {
      ENUM_TIMEFRAMES arr[2];
      arr[0] = tf;
      arr[1] = ctxTf;
      return DetectPhaseMTF(symbol, arr, 2, rangeThr).phase;
   }

   /// Encontra o suporte mais próximo ao preco informado
   double FindNearestSupport(const string symbol, ENUM_TIMEFRAMES tf, double price,
                             int lookbackBars = 50)
   {
      if (!EnsureHistory(symbol, tf, lookbackBars))
         return 0.0;

      double lows[];
      ArraySetAsSeries(lows, true);
      if (CopyLow(symbol, tf, 0, lookbackBars, lows) != lookbackBars)
         return 0.0;

      double support = 0.0;
      double minDist = DBL_MAX;
      for (int i = 2; i < lookbackBars - 2; i++)
      {
         if (lows[i] < lows[i - 1] && lows[i] < lows[i - 2] &&
             lows[i] < lows[i + 1] && lows[i] < lows[i + 2])
         {
            if (lows[i] < price && price - lows[i] < minDist)
            {
               minDist = price - lows[i];
               support = lows[i];
            }
         }
      }
      return support;
   }

   /// Encontra a resistência mais próxima ao preco informado
   double FindNearestResistance(const string symbol, ENUM_TIMEFRAMES tf, double price,
                                int lookbackBars = 50)
   {
      if (!EnsureHistory(symbol, tf, lookbackBars))
         return 0.0;

      double highs[];
      ArraySetAsSeries(highs, true);
      if (CopyHigh(symbol, tf, 0, lookbackBars, highs) != lookbackBars)
         return 0.0;

      double resistance = 0.0;
      double minDist = DBL_MAX;
      for (int i = 2; i < lookbackBars - 2; i++)
      {
         if (highs[i] > highs[i - 1] && highs[i] > highs[i - 2] &&
             highs[i] > highs[i + 1] && highs[i] > highs[i + 2])
         {
            if (highs[i] > price && highs[i] - price < minDist)
            {
               minDist = highs[i] - price;
               resistance = highs[i];
            }
         }
      }
      return resistance;
   }

   void set_sr(string symbol)
   {
      sr_macro = ComputeAndDrawSR(symbol, PERIOD_H4, "ctx_macro");
      sr_alto = ComputeAndDrawSR(symbol, PERIOD_H1, "ctx_alto");
      sr_medio = ComputeAndDrawSR(symbol, PERIOD_M30, "ctx_médio");
      sr_micro = ComputeAndDrawSR(symbol, PERIOD_M15, "ctx_micro");
   }
};

// compatibilidade com nome antigo
#define MarketContext MarketContextAnalyzer

#endif // INTEGRATEDPA_MARKETCONTEXT_MQH
