#ifndef INTEGRATEDPA_DEFS_MQH
#define INTEGRATEDPA_DEFS_MQH

//+------------------------------------------------------------------+
//| Enumerations                                                     |
//+------------------------------------------------------------------+

/// Fases de mercado suportadas pelo EA
enum MARKET_PHASE
{
   PHASE_TREND = 0,
   PHASE_RANGE,
   PHASE_REVERSAL,
   PHASE_UNDEFINED
};

/// Qualidade dos setups identificados
enum SETUP_QUALITY
{
   SETUP_A_PLUS = 0,
   SETUP_A,
   SETUP_B,
   SETUP_C
};

/// Direção de sinal de trade
enum SIGNAL_DIRECTION
{
   SIGNAL_NONE = 0,
   SIGNAL_BUY,
   SIGNAL_SELL
};

/// Viés diário calculado na preparação pré-mercado
enum DAILY_BIAS
{
   BIAS_NEUTRAL = 0,
   BIAS_BULLISH,
   BIAS_BEARISH
};

//+------------------------------------------------------------------+
//| Estruturas de dados fundamentais                                  |
//+------------------------------------------------------------------+

/// Parâmetros de configuração por ativo
struct AssetParams
{
   string          symbol;          ///< Símbolo do ativo
   ENUM_TIMEFRAMES main_tf;         ///< Timeframe principal para análise
   ENUM_TIMEFRAMES ctx_tf1;         ///< Timeframe adicional 1
   ENUM_TIMEFRAMES ctx_tf2;         ///< Timeframe adicional 2
   double          tick_value;      ///< Valor do tick
   double          lot_step;        ///< Passo mínimo de lote
   double          min_lot;         ///< Lote mínimo
   double          max_lot;         ///< Lote máximo
   double          max_risk;        ///< Risco máximo permitido
};

/// Runtime configuration for an asset used by the expert
struct AssetConfig
{
   string   symbol;
   bool     enabled;
   double   minLot;
   double   maxLot;
   double   lotStep;
   double   tickValue;
   int      digits;
   double   rangeThreshold;
   datetime lastBar;
   double   minStop;
   double   riskPercent;   ///< Risk percent per trade for this asset
   double   trailStart;    ///< Ponto de lucro para iniciar trailing
   double   trailDist;     ///< Distância do trailing
   ENUM_TIMEFRAMES ctxTf; ///< Timeframe de contexto para confirmacao
   ENUM_TIMEFRAMES atrTf; ///< Timeframe do ATR para stops
   int      atrPeriod;    ///< Periodo do ATR por ativo
   double   prevHigh;     ///< Máxima do dia anterior
   double   prevLow;      ///< Mínima do dia anterior
   DAILY_BIAS dailyBias;  ///< Viés diário calculado na preparação
};

/// Informações de um sinal gerado
struct Signal
{
   bool            valid;           ///< Indica se o sinal é válido
   SIGNAL_DIRECTION direction;      ///< Direção do trade
   MARKET_PHASE    phase;           ///< Fase de mercado correspondente
   SETUP_QUALITY   quality;         ///< Qualidade do setup
   double          entry;           ///< Preço de entrada
   double          stop;            ///< Nível de stop loss
   double          target;          ///< Nível de take profit
   datetime        timestamp;       ///< Momento da geração
   string          strategy;        ///< Estratégia geradora do sinal
};

/// Requisição de ordem construída pelo RiskManager
struct OrderRequest
{
   ENUM_ORDER_TYPE type;            ///< Tipo de ordem
   string          symbol;          ///< Símbolo
   double          volume;          ///< Volume em lotes
   double          price;           ///< Preço
   double          sl;              ///< Stop loss
   double          tp;              ///< Take profit
   string          comment;         ///< Comentário
   ulong           magic;           ///< Identificador único
};

/// Faixa de horário para sessões ou notícias
struct SessionRange
{
   int start; ///< minutos desde 00:00
   int end;   ///< minutos desde 00:00
};

#endif // INTEGRATEDPA_DEFS_MQH
