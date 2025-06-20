#property copyright "Development"
#property link "https://example.com"
#property version "1.00"
#property strict

#include <Trade/Trade.mqh>
#include <Arrays/ArrayObj.mqh>
#include <IntegratedPA/MarketContext.mqh>
#include <IntegratedPA/RiskManager.mqh>
#include <IntegratedPA/TradeExecutor.mqh>
#include <IntegratedPA/Logger.mqh>
#include <IntegratedPA/Utils.mqh>
#include <IntegratedPA/Defs.mqh>

// Strategy engine depends on user inputs declared below

input bool EnableTrading = true;
input bool EnableBTC = false;
input bool EnableWDO = false;
input bool EnableWIN = true;
input ENUM_TIMEFRAMES MainTimeframe = PERIOD_M3;
input double RiskPerTrade = 1.0;
input double MaxTotalRisk = 5.0;
input string TradingSessions = "09:00-12:00,14:00-17:00"; // high-liquidity windows
input double DailyLossPercent = 3.0;                      // stop trading after X% daily loss
input double DailyProfitPercent = 5.0;                    // stop trading after X% daily profit
// delay trading after session open per guide lines 3158-3171
input int SessionDelayMinutes = 15; // minutes to wait before trading
// strategy toggles for customization (guide line 39 encourages adapting strategies)
input bool UseSpikeAndChannel = true;
#define HAS_USE_SPIKE_AND_CHANNEL
input bool UsePullbackMA = false;
#define HAS_USE_PULLBACK_MA
input bool UseBollingerStochastic = false;
#define HAS_USE_BOLLINGER_STOCH
input bool UseTrendRangeDay = false;
#define HAS_USE_TREND_RANGE_DAY
input bool UseRangeBreakout = false;
#define HAS_USE_RANGE_BREAKOUT
input bool UseRangeFade = false;
#define HAS_USE_RANGE_FADE
input bool UseMeanReversion50200 = false;
#define HAS_USE_MEAN_REV_50200
input bool UseVWAPReversion = false;
#define HAS_USE_VWAP_REVERSION
input bool UseWedgeReversal = false;
#define HAS_USE_WEDGE_REVERSAL
input bool UseFibonacciRetrace = false;
#define HAS_USE_RSI_FILTER
input bool UsePreMarketRoutine = true;
#define HAS_USE_PRE_MARKET

#include <IntegratedPA/SignalEngine.mqh>

MarketContext *g_market = NULL;
SignalEngine *g_engine = NULL;
RiskManager *g_risk = NULL;
TradeExecutor *g_exec = NULL;
Logger *g_log = NULL;

double g_dailyStartEquity = 0.0; // equity at start of trading day
datetime g_dailyStart = 0;       // timestamp at day start
bool g_dailyPaused = false;      // true when daily loss/profit limit hit
bool g_preMarketDone = false;    // rotina pré-mercado executada no dia

// Asset configuration structure moved to Defs.mqh
AssetConfig g_assets[];

SessionRange g_sessions[];
SessionRange g_news[]; // horários de notícias para evitar operações

// prepare indicator handles at initialization
bool SetupIndicators()
{
   for (int i = 0; i < ArraySize(g_assets); i++)
   {

      string symbol = g_assets[i].symbol;

      SymbolSelect(symbol, true);
      // GetEMAHandle(symbol, MainTimeframe, 9);
      // GetEMAHandle(symbol, MainTimeframe, 20);
      // GetEMAHandle(symbol, MainTimeframe, 50);
      // GetEMAHandle(symbol, MainTimeframe, 200);
      
      // médias do diário para definição de viés pré-mercado
      GetEMAHandle(symbol, PERIOD_D1, 20);
      GetEMAHandle(symbol, PERIOD_D1, 50);
      GetSMAHandle(symbol, PERIOD_D1, 200);
      GetATRHandle(symbol, g_assets[i].atrTf, g_assets[i].atrPeriod);

   }
   return true;
}

// convert HH:MM string to minutes from midnight
int ParseMinutes(const string hhmm)
{
   string parts[];
   if (StringSplit(hhmm, ':', parts) != 2)
      return -1;
   int h = (int)StringToInteger(parts[0]);
   int m = (int)StringToInteger(parts[1]);
   return h * 60 + m;
}

// parse TradingSessions input into ranges
void ParseTradingSessions()
{
   string ranges[];
   int cnt = StringSplit(TradingSessions, ',', ranges);
   ArrayResize(g_sessions, cnt);
   for (int i = 0; i < cnt; i++)
   {
      string tokens[];
      if (StringSplit(ranges[i], '-', tokens) == 2)
      {
         g_sessions[i].start = ParseMinutes(tokens[0]);
         g_sessions[i].end = ParseMinutes(tokens[1]);
         if (g_log)
            g_log.Log(LOG_INFO, StringFormat("Session %d: %s-%s", i + 1, tokens[0], tokens[1]));
      }
      else
      {
         g_sessions[i].start = 0;
         g_sessions[i].end = 24 * 60;
         if (g_log)
            g_log.Log(LOG_INFO, StringFormat("Session %d: full day", i + 1));
      }
   }
}

// gera relatorio de desempenho diario conforme guia linhas 3433-3460
void GenerateDailyReport()
{
   string exePath = MQLInfoString(MQL_PROGRAM_PATH);
   string folder = exePath;
   for (int i = StringLen(folder) - 1; i >= 0; i--)
   {
      ushort c = StringGetCharacter(folder, i);
      if (c == '\\' || c == '/')
      {
         folder = StringSubstr(folder, 0, i + 1);
         break;
      }
   }
   string file = folder + "IntegratedPA_EA_report.csv";
   int handle = FileOpen(file, FILE_READ | FILE_WRITE | FILE_CSV);
   if (handle == INVALID_HANDLE)
      return;
   FileSeek(handle, 0, SEEK_END);
   if (FileSize(handle) == 0)
      FileWrite(handle, "date", "trades", "wins", "losses", "win_pct", "net", "profit_factor");

   datetime start = g_dailyStart;
   datetime end = start + 86400;
   if (!HistorySelect(start, end))
   {
      FileClose(handle);
      return;
   }
   int deals = HistoryDealsTotal();
   int wins = 0, losses = 0;
   double grossWin = 0.0, grossLoss = 0.0;
   for (int i = 0; i < deals; i++)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if (ticket == 0)
         continue;
      double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
      if (profit > 0)
      {
         wins++;
         grossWin += profit;
      }
      else if (profit < 0)
      {
         losses++;
         grossLoss -= profit; // profit is negative
      }
   }
   int total = wins + losses;
   double winPct = (total > 0) ? (100.0 * wins / total) : 0.0;
   double net = grossWin - grossLoss;
   double pf = (grossLoss > 0) ? grossWin / grossLoss : 0.0;
   FileWrite(handle, TimeToString(start, TIME_DATE), total, wins, losses, winPct, net, pf);
   FileClose(handle);
}

// reset daily counters at start of a new day
void ResetDailyLimits()
{
   if (g_dailyStart > 0)
      GenerateDailyReport();
   MqlDateTime tm;
   TimeToStruct(TimeCurrent(), tm);
   tm.hour = 0;
   tm.min = 0;
   tm.sec = 0;
   g_dailyStart = StructToTime(tm);
   g_dailyStartEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   g_dailyPaused = false;
   g_preMarketDone = false;
}

// check if daily loss or profit limit has been reached
// conforme guia, linhas 3158-3220 e 3380-3440, deve-se
// interromper as operações ao atingir limite diário de perda
// ou meta de ganho
void CheckDailyLimits()
{
   if (TimeCurrent() >= g_dailyStart + 86400)
      ResetDailyLimits();

   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double loss = g_dailyStartEquity - equity;
   double profit = equity - g_dailyStartEquity;
   double lossLimit = g_dailyStartEquity * (DailyLossPercent / 100.0);
   double profitLimit = g_dailyStartEquity * (DailyProfitPercent / 100.0);
   if (!g_dailyPaused && loss >= lossLimit)
   {
      g_dailyPaused = true;
      if (g_log)
         g_log.Log(LOG_WARNING, "Daily loss limit reached, trading paused");
   }
   if (!g_dailyPaused && profit >= profitLimit)
   {
      g_dailyPaused = true;
      if (g_log)
         g_log.Log(LOG_INFO, "Daily profit target reached, trading paused");
   }
}

// verify if current time is within any configured session
bool IsTradingSession()
{
   static int lastState = -1; // 0=off,1=delay,2=active
   datetime now = TimeCurrent();
   MqlDateTime tm;
   TimeToStruct(now, tm);
   int cur = tm.hour * 60 + tm.min;
   int state = 0;
   int remain = 0;
   for (int i = 0; i < ArraySize(g_sessions); i++)
   {
      if (cur >= g_sessions[i].start && cur <= g_sessions[i].end)
      {
         int diff = cur - g_sessions[i].start;
         if (diff >= SessionDelayMinutes)
            state = 2; // trading allowed
         else
         {
            state = 1; // waiting delay
            remain = SessionDelayMinutes - diff;
         }
         break;
      }
   }
   if (state != lastState && g_log != NULL)
   {
      if (state == 0)
         g_log.Log(LOG_INFO, "Outside trading session");
      else if (state == 1)
         g_log.Log(LOG_INFO, StringFormat("Waiting %d min after session start", remain));
      else if (state == 2)
         g_log.Log(LOG_INFO, "Trading session active");
      lastState = state;
   }
   return (state == 2);
}

// executa rotina de preparacao pre-mercado conforme guia linhas 3357-3383
void PreMarketRoutine()
{
   for (int i = 0; i < ArraySize(g_assets); i++)
   {
      string symbol = g_assets[i].symbol;
      g_assets[i].prevHigh = iHigh(symbol, PERIOD_D1, 1);
      g_assets[i].prevLow = iLow(symbol, PERIOD_D1, 1);

      double ema20 = GetEMA(symbol, PERIOD_D1, 20);
      double ema50 = GetEMA(symbol, PERIOD_D1, 50);
      double close1 = iClose(symbol, PERIOD_D1, 1);

      if ((close1 > ema20) && (ema20 > ema50)) // && ema50 > ema200
         g_assets[i].dailyBias = BIAS_BULLISH;
      else if ((close1 < ema20) && (ema20 < ema50)) // && ema50 < ema200
         g_assets[i].dailyBias = BIAS_BEARISH;
      else
         g_assets[i].dailyBias = BIAS_NEUTRAL;

      if (g_log)
      {
         string bias = (g_assets[i].dailyBias == BIAS_BULLISH) ? "Bullish" : (g_assets[i].dailyBias == BIAS_BEARISH) ? "Bearish"
                                                                                                                     : "Neutral";
         g_log.Log(LOG_INFO, StringFormat("Pre-market %s high %.2f low %.2f eMA20 %.2f eMA50 %.2f bias %s",
                                          symbol, g_assets[i].prevHigh, g_assets[i].prevLow, ema20, ema50, bias));
      }
   }
}

// executa rotina pre mercado uma unica vez por dia
void MaybeRunPreMarketRoutine()
{
   if (!UsePreMarketRoutine || g_preMarketDone)
      return;

   MqlDateTime tm;
   TimeToStruct(TimeCurrent(), tm);
   int start = g_sessions[0].start; // assume primeira sessao
   int startHour = start / 60;
   int startMin = start % 60;
   MqlDateTime prep = tm;
   prep.hour = startHour;
   prep.min = startMin;
   prep.sec = 0;
   datetime runTime = StructToTime(prep) - 30 * 60; // 30 minutos antes
   if (TimeCurrent() >= runTime)
   {
      PreMarketRoutine();
      g_preMarketDone = true;
   }
}

// fecha posições abertas se o horário atual ultrapassou o final da última sessão
void MaybeCloseEODPositions()
{
   int lastEnd = 0;
   for (int i = 0; i < ArraySize(g_sessions); i++)
   {
      if (g_sessions[i].end > lastEnd)
         lastEnd = g_sessions[i].end;
   }
   MqlDateTime tm;
   TimeToStruct(TimeCurrent(), tm);
   int cur = tm.hour * 60 + tm.min;
   if (cur >= lastEnd && g_exec != NULL)
      g_exec.CloseAllPositions();
}

//+------------------------------------------------------------------+
int OnInit()
{
   g_log = new Logger("IntegratedPA_EA");
   if (g_log == NULL)
      return (INIT_FAILED);
   g_log.Log(LOG_INFO, "Inicializando EA");

   if (!SetupAssets())
      return (INIT_FAILED);

   SetupIndicators();
   ParseTradingSessions();

   string activeSymbols[];
   for (int i = 0; i < ArraySize(g_assets); i++)
   {
      if (g_assets[i].enabled)
      {
         int n = ArraySize(activeSymbols);
         ArrayResize(activeSymbols, n + 1);
         activeSymbols[n] = g_assets[i].symbol;
      }
   }

   ResetDailyLimits();

   g_market = new MarketContext();
   g_engine = new SignalEngine();
   g_risk = new RiskManager(RiskPerTrade, MaxTotalRisk);
   g_exec = new TradeExecutor();
   g_exec.SetLogger(g_log);
   g_exec.SetTradeAllowed(EnableTrading);

   EventSetTimer(60);
   return (INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();
   if (g_market)
   {
      delete g_market;
      g_market = NULL;
   }
   if (g_engine)
   {
      delete g_engine;
      g_engine = NULL;
   }
   if (g_risk)
   {
      delete g_risk;
      g_risk = NULL;
   }
   if (g_exec)
   {
      g_exec.CleanupStageVariables();
      delete g_exec;
      g_exec = NULL;
   }

   ReleaseEMAHandles();
   ReleaseVWAPCache();
   ReleaseATRHandles();
   ReleaseBBHandles();
   ReleaseStochasticHandles();
   ReleaseRSIHandles();
   ReleaseMFIHandles();
   ReleaseOBVHandles();
   // g_calendar.Clear();
   GenerateDailyReport();
   if (g_log)
   {
      g_log.Log(LOG_INFO, "Encerrando EA");
      delete g_log;
      g_log = NULL;
   }
}

//+------------------------------------------------------------------+
void OnTick()
{
   CheckDailyLimits();
   MaybeRunPreMarketRoutine();
   // manage existing positions first
   if (g_exec)
      g_exec.ManageOpenPositions(g_market, g_assets, ArraySize(g_assets), MainTimeframe);
   MaybeCloseEODPositions();

   if (g_dailyPaused)
      return;

   if (!IsTradingSession())
      return;

   for (int i = 0; i < ArraySize(g_assets); i++)
   {
      if (!g_assets[i].enabled)
         continue;

      string symbol = g_assets[i].symbol;

      if (!IsNewBar(symbol, MainTimeframe, g_assets[i].lastBar))
         continue;

      
      g_market.set_sr(symbol);

      MARKET_PHASE phase = g_market.DetectPhaseMTF(symbol, MainTimeframe, g_assets[i].ctxTf,
                                                   g_assets[i].rangeThreshold);

      Signal sig = g_engine.Generate(symbol, phase, MainTimeframe);

      if (!sig.valid)
         continue;

      // respeita vies diario calculado na rotina pre-mercado
      if (UsePreMarketRoutine && g_assets[i].dailyBias != BIAS_NEUTRAL)
      {
         if (sig.direction == SIGNAL_BUY && g_assets[i].dailyBias == BIAS_BEARISH)
            continue;
         if (sig.direction == SIGNAL_SELL && g_assets[i].dailyBias == BIAS_BULLISH)
            continue;
      }

      if (g_log)
         g_log.LogSignal(symbol, sig);

      // Atenção
      // ensure minimum stop distance as recommended in the trading guide
      double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
      double atr = GetATR(symbol, g_assets[i].atrTf, g_assets[i].atrPeriod);
      double dist = MathAbs(sig.entry - sig.stop) / point;
      if (dist < g_assets[i].minStop)
      {
         double adjust = g_assets[i].minStop * point;
         if (sig.direction == SIGNAL_BUY)
            sig.stop = sig.entry - adjust;
         else if (sig.direction == SIGNAL_SELL)
            sig.stop = sig.entry + adjust;
      }

      // stop baseado em ATR para adaptar à volatilidade
      if (atr > 0.0)
      {
         double atrPts = atr / point;
         double curDist = MathAbs(sig.entry - sig.stop) / point;
         if (curDist < atrPts)
         {
            if (sig.direction == SIGNAL_BUY)
               sig.stop = sig.entry - atr;
            else if (sig.direction == SIGNAL_SELL)
               sig.stop = sig.entry + atr;
         }
      }

      OrderRequest req = g_risk.BuildRequest(symbol, sig, phase, g_assets[i].riskPercent);
      if (g_risk.CanOpen(req))
         g_exec.Execute(req);
      else if (g_log)
         g_log.Log(LOG_WARNING, "Total risk limit exceeded, order skipped");
   }
}

//+------------------------------------------------------------------+
void OnTimer()
{
   g_risk.UpdateAccountInfo();
   CheckDailyLimits();
   if (g_log)
      g_log.ExportToCSV();
}

//+------------------------------------------------------------------+
bool SetupAssets()
{
   // attempt to load configuration from CSV file located next to the EA
   string exePath = MQLInfoString(MQL_PROGRAM_PATH);
   string folder = exePath;
   for (int i = StringLen(folder) - 1; i >= 0; i--)
   {
      ushort c = StringGetCharacter(folder, i);
      if (c == '\\' || c == '/')
      {
         folder = StringSubstr(folder, 0, i + 1);
         break;
      }
   }
   string cfgFile = folder + "assets.csv";
   AssetConfig loaded[];
   if (LoadAssetCsv(cfgFile, MainTimeframe, loaded))
   {
      int idx = 0;
      for (int i = 0; i < ArraySize(loaded); i++)
      {
         bool ok = true;
         if (StringFind(loaded[i].symbol, "BTC") == 0 && !EnableBTC)
            ok = false;
         if (StringFind(loaded[i].symbol, "WDO") == 0 && !EnableWDO)
            ok = false;
         if (StringFind(loaded[i].symbol, "WIN") == 0 && !EnableWIN)
            ok = false;
         if (!loaded[i].enabled)
            ok = false;
         if (!ok)
            continue;
         ArrayResize(g_assets, idx + 1);
         g_assets[idx] = loaded[i];
         idx++;
      }
      if (ArraySize(g_assets) > 0)
         return true;
   }

   int count = 0;
   if (EnableBTC)
      count++;
   if (EnableWDO)
      count++;
   if (EnableWIN)
      count++;
   if (count == 0)
   {
      if (g_log)
         g_log.Log(LOG_ERROR, "Nenhum ativo habilitado");
      return false;
   }
   ArrayResize(g_assets, count);
   int idx = 0;
   if (EnableBTC)
   {
      g_assets[idx].symbol = "BITM25";
      g_assets[idx].enabled = true;
      g_assets[idx].minLot = 0.01;
      g_assets[idx].maxLot = 10.0;
      g_assets[idx].lotStep = 0.01;
      g_assets[idx].tickValue = SymbolInfoDouble("BITM25", SYMBOL_TRADE_TICK_VALUE);
      g_assets[idx].digits = (int)SymbolInfoInteger("BITM25", SYMBOL_DIGITS);
      g_assets[idx].rangeThreshold = 50.0; // BTC more volatile
      g_assets[idx].lastBar = 0;
      g_assets[idx].minStop = 1000.0;    // guide: BTC typical stop 800-1200
      g_assets[idx].riskPercent = 0.4;   // risco reduzido conforme desempenho
      g_assets[idx].trailStart = 4000.0; // inicia trailing apos 4000 USD
      g_assets[idx].trailDist = 900.0;   // distancia ~900 USD
      g_assets[idx].ctxTf = PERIOD_H4;   // MTF context per trading guide
      g_assets[idx].atrTf = MainTimeframe;
      g_assets[idx].atrPeriod = 21; // periodo maior para volatilidade do BTC
      g_assets[idx].prevHigh = 0.0;
      g_assets[idx].prevLow = 0.0;
      g_assets[idx].dailyBias = BIAS_NEUTRAL;
      idx++;
   }
   if (EnableWDO)
   {
      g_assets[idx].symbol = "WDON25";
      g_assets[idx].enabled = true;
      g_assets[idx].minLot = 1.0;
      g_assets[idx].maxLot = 100.0;
      g_assets[idx].lotStep = 1.0;
      g_assets[idx].tickValue = SymbolInfoDouble("WDON25", SYMBOL_TRADE_TICK_VALUE);
      g_assets[idx].digits = (int)SymbolInfoInteger("WDON25", SYMBOL_DIGITS);
      g_assets[idx].rangeThreshold = 2.0;
      g_assets[idx].lastBar = 0;
      g_assets[idx].minStop = 7.0;     // guide: Dollar stop 5-7 points
      g_assets[idx].riskPercent = 0.8; // risco ajustado
      g_assets[idx].trailStart = 50.0; // pontos de lucro para iniciar trailing
      g_assets[idx].trailDist = 12.0;  // trailing de ~12 pontos
      g_assets[idx].ctxTf = PERIOD_H1; // context timeframe per guide
      g_assets[idx].atrTf = MainTimeframe;
      g_assets[idx].atrPeriod = 14; // periodo padrao para o dolar
      g_assets[idx].prevHigh = 0.0;
      g_assets[idx].prevLow = 0.0;
      g_assets[idx].dailyBias = BIAS_NEUTRAL;
      idx++;
   }
   if (EnableWIN)
   {
      g_assets[idx].symbol = "WIN$N"; // updated symbol name
      g_assets[idx].enabled = true;
      g_assets[idx].minLot = 1.0;
      g_assets[idx].maxLot = 100.0;
      g_assets[idx].lotStep = 1.0;
      g_assets[idx].tickValue = SymbolInfoDouble("WIN$N", SYMBOL_TRADE_TICK_VALUE);
      g_assets[idx].digits = (int)SymbolInfoInteger("WIN$N", SYMBOL_DIGITS);
      g_assets[idx].rangeThreshold = 80.0;
      g_assets[idx].lastBar = 0;
      g_assets[idx].minStop = 200.0;     // guide: Index stop 150-200 points
      g_assets[idx].riskPercent = 1.2;   // maior risco permitido
      g_assets[idx].trailStart = 1500.0; // trailing apos 1500 pontos de lucro
      g_assets[idx].trailDist = 350.0;   // distancia de 300-400 pontos
      g_assets[idx].ctxTf = PERIOD_H4;   // context timeframe per guide
      g_assets[idx].atrTf = PERIOD_D1;   // volatilidade medida no diário conforme guia
      g_assets[idx].atrPeriod = 14;      // periodo do ATR diario
      g_assets[idx].prevHigh = 0.0;
      g_assets[idx].prevLow = 0.0;
      g_assets[idx].dailyBias = BIAS_NEUTRAL;
   }
   return true;
}
