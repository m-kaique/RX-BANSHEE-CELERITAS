#ifndef INTEGRATEDPA_RISKMANAGER_MQH
#define INTEGRATEDPA_RISKMANAGER_MQH
#include <Trade/SymbolInfo.mqh>
#include "Defs.mqh"
#include "Utils.mqh"

class RiskManager
{
private:
   double m_risk_per_trade;   // percentual de risco por trade (ex: 1.0 = 1%)
   double m_max_total_risk;   // risco máximo permitido em posições abertas
   double m_equity;           // valor de conta atualizado

public:
   RiskManager(double risk_per_trade,double max_total_risk)
   {
      m_risk_per_trade=risk_per_trade;
      m_max_total_risk=max_total_risk;
      m_equity=AccountInfoDouble(ACCOUNT_EQUITY);
   }

   ~RiskManager(){}

   // calcula o risco financeiro de uma posição aberta
   double PositionRisk(const string symbol,double entry,double sl,double volume)
   {
      double tick_value=SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_VALUE);
      double tick_size =SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_SIZE);
      double stop_points=MathAbs(entry-sl)/tick_size;
      return(stop_points*tick_value*volume);
   }

   // verifica se já existe posição aberta para o símbolo
   bool HasOpenPosition(const string symbol)
   {
      for(int i=PositionsTotal()-1;i>=0;i--)
      {
         ulong ticket=PositionGetTicket(i);
         if(!PositionSelectByTicket(ticket))
            continue;
         if(PositionGetString(POSITION_SYMBOL)==symbol)
            return true;
      }
      return false;
   }

   // retorna o risco total atual considerando todas as posições
   double CurrentTotalRisk()
   {
      double total=0.0;
      for(int i=PositionsTotal()-1;i>=0;i--)
      {
         ulong ticket=PositionGetTicket(i);
         if(!PositionSelectByTicket(ticket))
            continue;
         string sym   =PositionGetString(POSITION_SYMBOL);
         double entry =PositionGetDouble(POSITION_PRICE_OPEN);
         double sl    =PositionGetDouble(POSITION_SL);
         double vol   =PositionGetDouble(POSITION_VOLUME);
         if(sl==0.0) // se nao houver stop definido, ignora
            continue;
         total+=PositionRisk(sym,entry,sl,vol);
      }
      return total;
   }

   // verifica se e possivel abrir a posicao sem exceder o risco maximo total
   bool CanOpen(const OrderRequest &req)
   {
      // evita sobrealocacao abrindo apenas uma posicao por simbolo
      if(HasOpenPosition(req.symbol))
         return false;

      double new_risk=PositionRisk(req.symbol,req.price,req.sl,req.volume);
      double allowed = m_equity*(m_max_total_risk/100.0);
      double total   = CurrentTotalRisk();
      return((total+new_risk)<=allowed);
   }

   // Constrói a requisição de ordem baseado no risco definido no guia
   // Build order request using per-trade risk. If asset_risk_percent is >0, it
   // overrides the default risk configured for the RiskManager. This allows
   // different assets to use custom risk sizing as recommended in the trading
   // guide when adapting position size to asset volatility (guide line ~1890).
  OrderRequest BuildRequest(const string symbol,const Signal &signal,MARKET_PHASE phase,double asset_risk_percent=0.0)
  {
      // atualiza equity para dimensionar o risco com base no valor mais recente
      UpdateAccountInfo();
      OrderRequest req;
      req.symbol=symbol;
      // use current market price to reduce slippage
      double current=(signal.direction==SIGNAL_BUY)?
                     SymbolInfoDouble(symbol,SYMBOL_ASK):
                     SymbolInfoDouble(symbol,SYMBOL_BID);
      req.price=NormalizePrice(symbol,current);
      req.sl=NormalizePrice(symbol,signal.stop);
      req.tp=NormalizePrice(symbol,signal.target);
      req.comment=signal.strategy;
      req.magic=0;

      // define direção de acordo com o sinal
      if(signal.direction==SIGNAL_SELL)
         req.type=ORDER_TYPE_SELL;
      else
         req.type=ORDER_TYPE_BUY;

      // cálculo de volume baseado em risco
      // Ajuste conforme a qualidade do setup (Guia linhas 5438-5448)
      // A+ = 100% do tamanho planejado; B = 70%; C = tamanho mínimo
      double quality_factor=1.0;
      if(signal.quality==SETUP_A_PLUS)
         quality_factor=1.0;
      else if(signal.quality==SETUP_A)
         quality_factor=0.9;   // interpretação intermediária
      else if(signal.quality==SETUP_B)
         quality_factor=0.7;
      else if(signal.quality==SETUP_C)
         quality_factor=0.25;
      double base_risk=(asset_risk_percent>0.0)?asset_risk_percent:m_risk_per_trade;

      // ajuste adicional conforme a fase do mercado
      // Guia_Completo_de_Trading_Versao_Final.pdf linhas 5428-5441
      double phase_factor=1.0;
      switch(phase)
      {
         case PHASE_TREND:      phase_factor=1.0;  break;      // tendência clara
         case PHASE_RANGE:      phase_factor=0.75; break;      // range definido
         case PHASE_REVERSAL:   phase_factor=0.5;  break;      // reversão potencial
         default:               phase_factor=0.5;  break;
      }

      double risk_percent=base_risk*quality_factor*phase_factor;
      double risk_amount=m_equity*(risk_percent/100.0);
      double tick_value=SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_VALUE);
      double tick_size =SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_SIZE);
      double stop_points=MathAbs(req.price-req.sl)/tick_size;

      if(stop_points<=0.0 || tick_value<=0.0)
      {
         req.volume=0.0;
         return req;
      }

      double volume=risk_amount/(stop_points*tick_value);
      double min_lot=SymbolInfoDouble(symbol,SYMBOL_VOLUME_MIN);
      double max_lot=SymbolInfoDouble(symbol,SYMBOL_VOLUME_MAX);
      double lot_step=SymbolInfoDouble(symbol,SYMBOL_VOLUME_STEP);

      // calcula o numero de digitos de volume a partir do step
      int vol_digits=0;
      double step_tmp=lot_step;
      while(vol_digits<8 && MathAbs(step_tmp-MathRound(step_tmp))>0.0000001)
      {
         step_tmp*=10.0;
         vol_digits++;
      }

      volume=MathMax(volume,min_lot);
      volume=MathMin(volume,max_lot);
      volume=MathFloor(volume/lot_step+0.0000001)*lot_step;
      req.volume=NormalizeDouble(volume,vol_digits);

      return req;
   }

   // Atualiza valores de conta (equity) para cálculo de risco
   void UpdateAccountInfo()
   {
      m_equity=AccountInfoDouble(ACCOUNT_EQUITY);
   }
};

#endif // INTEGRATEDPA_RISKMANAGER_MQH
