#ifndef INTEGRATEDPA_TRADEEXECUTOR_MQH
#define INTEGRATEDPA_TRADEEXECUTOR_MQH
#include <Trade/Trade.mqh>
#include "Defs.mqh"
#include "Logger.mqh"
#include "Utils.mqh"

class TradeExecutor
{
private:
   CTrade m_trade;
   Logger *m_logger;
   bool   m_allow_trade;
public:
  TradeExecutor():m_logger(NULL),m_allow_trade(true){}
  ~TradeExecutor(){}

   void SetLogger(Logger *logger){m_logger=logger;}
   void SetTradeAllowed(bool allowed){m_allow_trade=allowed;}
   bool Initialize(){return true;}

  bool Execute(const OrderRequest &req)
   {
      if(!m_allow_trade)
         return false;

      bool result=false;

      // use latest market price and allow small slippage
      m_trade.SetDeviationInPoints(10);
      double exec_price=(req.type==ORDER_TYPE_BUY)?
                        SymbolInfoDouble(req.symbol,SYMBOL_ASK):
                        SymbolInfoDouble(req.symbol,SYMBOL_BID);

      if(req.type==ORDER_TYPE_BUY)
         result=m_trade.Buy(req.volume,req.symbol,exec_price,req.sl,req.tp,req.comment);
      else if(req.type==ORDER_TYPE_SELL)
         result=m_trade.Sell(req.volume,req.symbol,exec_price,req.sl,req.tp,req.comment);

      if(!result)
      {
         if(m_logger!=NULL)
            m_logger.LogTrade("Send",req,false);
      }
      else
      {
         // store position stage for partial exits using a global variable
         ulong ticket=m_trade.ResultOrder();
         if(ticket>0)
            GlobalVariableSet("stage_"+(string)ticket,0.0);
         if(m_logger!=NULL)
            m_logger.LogTrade("Send",req,true);
      }

      return result;
   }

   // manage partial exits and trailing stops as per the trading guide
  void ManageOpenPositions(const AssetConfig &assets[],int count,ENUM_TIMEFRAMES tf)
  {
      for(int i=PositionsTotal()-1;i>=0;i--)
      {
         ulong ticket=PositionGetTicket(i);
         if(!PositionSelectByTicket(ticket))
            continue;

         string symbol=PositionGetString(POSITION_SYMBOL);
         ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         double volume=PositionGetDouble(POSITION_VOLUME);
         double entry =PositionGetDouble(POSITION_PRICE_OPEN);
         double sl    =PositionGetDouble(POSITION_SL);

         double price=(type==POSITION_TYPE_BUY)?SymbolInfoDouble(symbol,SYMBOL_BID):SymbolInfoDouble(symbol,SYMBOL_ASK);
         double point=SymbolInfoDouble(symbol,SYMBOL_POINT);

         double risk=MathAbs(entry-sl);
         if(risk<=0.0) continue;

         double firstTarget =(type==POSITION_TYPE_BUY)? entry+risk : entry-risk;
         double secondTarget=(type==POSITION_TYPE_BUY)? entry+2*risk : entry-2*risk;
         double trailTrigger=secondTarget; // trailing inicia apos segunda parcial

         // find asset parameters for this symbol
         double rangeThreshold=10.0;
         ENUM_TIMEFRAMES assetAtrTf=tf;
         int assetAtrPeriod=14;
         double assetTrailStart=0.0;
         double assetTrailDist=0.0;
         for(int a=0;a<count;a++)
         {
            if(assets[a].symbol==symbol)
            {
               rangeThreshold=assets[a].rangeThreshold;
               assetAtrTf=assets[a].atrTf;
               assetAtrPeriod=assets[a].atrPeriod;
               assetTrailStart=assets[a].trailStart;
               assetTrailDist=assets[a].trailDist;
               break;
           }
        }
        MARKET_PHASE phase=PHASE_UNDEFINED;

         string gv="stage_"+(string)ticket;
         double stage=0.0;
         if(GlobalVariableCheck(gv)) stage=GlobalVariableGet(gv);

         if(stage<1.0)
         {
            // primeira parcial 50% em 1R e stop para breakeven
            if( (type==POSITION_TYPE_BUY && price>=firstTarget) ||
                (type==POSITION_TYPE_SELL && price<=firstTarget) )
            {
               double lot_step = SymbolInfoDouble(symbol,SYMBOL_VOLUME_STEP);
               int vol_digits = GetVolumeDigits(symbol);
               double closeVol = volume/2.0;
               closeVol = MathFloor(closeVol/lot_step + 0.0000001)*lot_step;
               closeVol = NormalizeDouble(closeVol,vol_digits);
               m_trade.PositionClosePartial(symbol,closeVol);
               // move stop to breakeven with small buffer as
               // recommended in the trading guide (line 5473)
               double buffer=risk*0.1;               // 10% of initial risk
               double minBuf=2*point;                // at least two ticks
               if(buffer<minBuf) buffer=minBuf;
               double be=(type==POSITION_TYPE_BUY)? entry+buffer : entry-buffer;
               m_trade.PositionModify(symbol,be,0.0);
               GlobalVariableSet(gv,1.0);
               if(m_logger!=NULL)
               {
                  m_logger.Log(LOG_INFO,"First partial executed");
                  ENUM_ORDER_TYPE dummyType=(type==POSITION_TYPE_BUY?ORDER_TYPE_BUY:ORDER_TYPE_SELL);
                  OrderRequest dummy; dummy.symbol=symbol; dummy.volume=closeVol; dummy.price=price; dummy.sl=entry; dummy.tp=0; dummy.type=dummyType; dummy.comment="Partial1";
                  m_logger.LogTrade("Partial",dummy,true);
               }
               // refresh info after partial
               PositionSelectByTicket(ticket);
               sl=PositionGetDouble(POSITION_SL);
               volume=PositionGetDouble(POSITION_VOLUME);
            }
         }
         else if(stage<2.0)
         {
            // segunda parcial 25% em 2R
            if( (type==POSITION_TYPE_BUY && price>=secondTarget) ||
                (type==POSITION_TYPE_SELL && price<=secondTarget) )
            {
               double lot_step = SymbolInfoDouble(symbol,SYMBOL_VOLUME_STEP);
               int vol_digits = GetVolumeDigits(symbol);
               double closeVol = volume/2.0;
               closeVol = MathFloor(closeVol/lot_step + 0.0000001)*lot_step;
               closeVol = NormalizeDouble(closeVol,vol_digits);
               m_trade.PositionClosePartial(symbol,closeVol);
               GlobalVariableSet(gv,2.0);
               if(m_logger!=NULL)
               {
                  m_logger.Log(LOG_INFO,"Second partial executed");
                  ENUM_ORDER_TYPE dummyType=(type==POSITION_TYPE_BUY?ORDER_TYPE_BUY:ORDER_TYPE_SELL);
                  OrderRequest dummy; dummy.symbol=symbol; dummy.volume=closeVol; dummy.price=price; dummy.sl=sl; dummy.tp=0; dummy.type=dummyType; dummy.comment="Partial2";
                  m_logger.LogTrade("Partial",dummy,true);
               }
               // refresh info
               PositionSelectByTicket(ticket);
               sl=PositionGetDouble(POSITION_SL);
               volume=PositionGetDouble(POSITION_VOLUME);
            }
         }
         if(stage>=2.0)
         {
            // trailing stop apos segunda parcial
            if( (type==POSITION_TYPE_BUY && price>=trailTrigger) ||
                (type==POSITION_TYPE_SELL && price<=trailTrigger) )
            {
               double new_sl=sl;
               if(phase==PHASE_TREND)
               {
                  double ema20=GetEMA(symbol,tf,20);
                  double vwap =GetVWAP(symbol,tf);
                  if(type==POSITION_TYPE_BUY)
                  {
                     double trail=MathMax(iLow(symbol,tf,1),ema20-5*point);
                     double trailVwap=vwap-2*point; // guia: trailing pelo VWAP
                     if(trailVwap>trail) trail=trailVwap;
                     if(trail>new_sl) new_sl=trail;
                  }
                  else
                  {
                     double trail=MathMin(iHigh(symbol,tf,1),ema20+5*point);
                     double trailVwap=vwap+2*point;
                     if(trailVwap<trail) trail=trailVwap;
                     if(trail<new_sl || sl==0.0) new_sl=trail;
                  }
               }
               else // range or reversal
               {
                  if(type==POSITION_TYPE_BUY)
                  {
                     double trail=iLow(symbol,tf,1)-5*point;
                     if(trail>new_sl) new_sl=trail;
                  }
                  else
                  {
                     double trail=iHigh(symbol,tf,1)+5*point;
                     if(trail<new_sl || sl==0.0) new_sl=trail;
                  }
               }
               // trailing adicional baseado no ATR diario para o WIN
               if(StringFind(symbol,"WIN")==0)
               {
                  double atr=GetATR(symbol,assetAtrTf,assetAtrPeriod);
                  if(atr>0.0)
                  {
                     double dist=atr*0.25;      // 25% do ATR diario
                     double minDist=200*point;  // guia: 300-400 pontos
                     double maxDist=300*point;
                     if(dist<minDist) dist=minDist;
                     if(dist>maxDist) dist=maxDist;
                     if(type==POSITION_TYPE_BUY)
                     {
                        double trail=price-dist;
                        if(trail>new_sl) new_sl=trail;
                     }
                     else
                     {
                        double trail=price+dist;
                        if(trail<new_sl || sl==0.0) new_sl=trail;
                     }
                  }
               }
               // trailing específico por ativo conforme configuracao
               if(assetTrailStart>0.0)
               {
                  double profit=MathAbs(price-entry);
                  bool trigger=false;
                  double distPts=assetTrailDist*point;
                  if(StringFind(symbol,"BTC")==0)
                  {
                     if(profit>=assetTrailStart)
                        trigger=true;
                  }
                  else
                  {
                     if(profit>=assetTrailStart*point)
                        trigger=true;
                  }

                  if(trigger)
                  {
                     double dist=(StringFind(symbol,"BTC")==0)?assetTrailDist:distPts;
                     if(type==POSITION_TYPE_BUY)
                     {
                        double trail=price-dist;
                        if(trail>new_sl) new_sl=trail;
                     }
                     else
                     {
                        double trail=price+dist;
                        if(trail<new_sl || sl==0.0) new_sl=trail;
                     }
                  }
               }

               if(new_sl!=sl)
               {
                  m_trade.PositionModify(symbol,new_sl,0.0);
                  if(m_logger!=NULL)
                  {
                     m_logger.Log(LOG_INFO,"Trailing stop moved");
                     ENUM_ORDER_TYPE tmpType=(type==POSITION_TYPE_BUY?ORDER_TYPE_BUY:ORDER_TYPE_SELL);
                     OrderRequest tmp; tmp.symbol=symbol; tmp.volume=volume; tmp.price=new_sl; tmp.sl=0; tmp.tp=0; tmp.type=tmpType; tmp.comment="Trail";
                     m_logger.LogTrade("Trail",tmp,true);
                  }
               }
            }
         }
      }
      // remove stage variables for tickets no longer open
      CleanupStageVariables();
   }

   // Delete global variables that track partial stages when their corresponding
   // positions are no longer present. Prevents stale data from accumulating.
   void CleanupStageVariables()
   {
      int total=GlobalVariablesTotal();
      for(int i=total-1;i>=0;i--)
      {
         string name=GlobalVariableName(i);
         if(StringFind(name,"stage_")==0)
         {
            ulong ticket=(ulong)StringToInteger(StringSubstr(name,6));
            if(!PositionSelectByTicket(ticket))
               GlobalVariableDel(name);
         }
      }
   }
   // Retorna descricao textual do erro (simplificada)
   string GetErrorDescription(int code)
   {
      return(IntegerToString(code));
   }

   // Converte o ultimo erro em string para fins de log
   string GetLastErrorDescription()
   {
      return(GetErrorDescription(GetLastError()));
   }

   // Fecha todas as posições abertas – usado para encerrar operações ao fim do dia
   void CloseAllPositions()
   {
      for(int i=PositionsTotal()-1;i>=0;i--)
      {
         ulong ticket=PositionGetTicket(i);
         if(!PositionSelectByTicket(ticket))
            continue;
         string symbol=PositionGetString(POSITION_SYMBOL);
         double volume=PositionGetDouble(POSITION_VOLUME);
         ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         double price=(type==POSITION_TYPE_BUY)?SymbolInfoDouble(symbol,SYMBOL_BID)
                                             :SymbolInfoDouble(symbol,SYMBOL_ASK);
         m_trade.PositionClose(ticket);
         if(m_logger!=NULL)
         {
            OrderRequest tmp; tmp.symbol=symbol; tmp.volume=volume; tmp.price=price;
            tmp.sl=0; tmp.tp=0; tmp.type=(type==POSITION_TYPE_BUY?ORDER_TYPE_SELL:ORDER_TYPE_BUY);
            tmp.comment="EODClose"; tmp.magic=0;
            m_logger.LogTrade("CloseEOD",tmp,true);
         }
      }
      CleanupStageVariables();
   }
};

#endif // INTEGRATEDPA_TRADEEXECUTOR_MQH
