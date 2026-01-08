//+------------------------------------------------------------------+
//| TrailingManager.mqh                                              |
//| Trailing Stop Manager - VPS-SAFE ONLY                           |
//+------------------------------------------------------------------+
#property copyright "Azzuro"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Config/Inputs.mqh"
#include "../Core/SymbolUtils.mqh"
#include "../Core/Logger.mqh"
#include "TradeManager.mqh"

//+------------------------------------------------------------------+
//| Trailing Stop Manager class                                     |
//+------------------------------------------------------------------+
class CTrailingManager
{
private:
   int      m_magicNumber;
   int      m_trailingStart;   // Points profit before trailing starts
   int      m_trailingStep;    // Points to trail by
   int      m_trailingStop;     // Trailing stop distance in points
   CLogger* m_logger;
   CTradeManager* m_tradeManager;
   
public:
   CTrailingManager(int magic, int trailingStart, int trailingStep, int trailingStop, 
                    CTradeManager* tradeMgr, CLogger* logger)
      : m_magicNumber(magic), m_trailingStart(trailingStart), 
        m_trailingStep(trailingStep), m_trailingStop(trailingStop),
        m_tradeManager(tradeMgr), m_logger(logger)
   {
   }
   
   //+------------------------------------------------------------------+
   //| Process trailing stop for all positions                        |
   //+------------------------------------------------------------------+
   void Process()
   {
      for(int i = 0; i < PositionsTotal(); i++)
      {
         ulong ticket = PositionGetTicket(i);
         if(ticket > 0 && PositionGetInteger(POSITION_MAGIC) == m_magicNumber)
         {
            ProcessPosition(ticket);
         }
      }
   }
   
   //+------------------------------------------------------------------+
   //| Process trailing stop for single position                      |
   //+------------------------------------------------------------------+
   void ProcessPosition(ulong ticket)
   {
      if(!PositionSelectByTicket(ticket))
         return;
      
      string symbol = PositionGetString(POSITION_SYMBOL);
      double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentSL = PositionGetDouble(POSITION_SL);
      ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      
      double currentPrice = (posType == POSITION_TYPE_BUY) ? 
                           SymbolInfoDouble(symbol, SYMBOL_BID) : 
                           SymbolInfoDouble(symbol, SYMBOL_ASK);
      
      double pointValue = GetPointValue(symbol);
      double profitPoints = 0;
      
      // Calculate profit in points
      if(posType == POSITION_TYPE_BUY)
         profitPoints = (currentPrice - entryPrice) / pointValue;
      else
         profitPoints = (entryPrice - currentPrice) / pointValue;
      
      // Check if profit reached trailing start threshold
      if(profitPoints < m_trailingStart)
         return; // Not enough profit to start trailing
      
      // Calculate new trailing stop level
      double newSL = 0;
      if(posType == POSITION_TYPE_BUY)
      {
         newSL = currentPrice - (m_trailingStop * pointValue);
         
         // Only move SL up, never down
         if(currentSL > 0 && newSL <= currentSL)
            return; // Don't move SL backwards
         
         // Only move if distance is at least trailing step
         if(currentSL > 0 && (newSL - currentSL) < (m_trailingStep * pointValue))
            return; // Not enough movement yet
      }
      else
      {
         newSL = currentPrice + (m_trailingStop * pointValue);
         
         // Only move SL down, never up
         if(currentSL > 0 && newSL >= currentSL)
            return; // Don't move SL backwards
         
         // Only move if distance is at least trailing step
         if(currentSL > 0 && (currentSL - newSL) < (m_trailingStep * pointValue))
            return; // Not enough movement yet
      }
      
      double currentTP = PositionGetDouble(POSITION_TP);
      
      if(m_tradeManager != NULL)
      {
         if(m_tradeManager.ModifyPosition(ticket, newSL, currentTP))
         {
            if(m_logger != NULL)
               m_logger.Info("Position " + IntegerToString(ticket) + " trailing stop updated to " + DoubleToString(newSL, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)));
         }
      }
   }
   
   //+------------------------------------------------------------------+
   //| Set trailing parameters                                        |
   //+------------------------------------------------------------------+
   void SetTrailingStart(int start) { m_trailingStart = start; }
   void SetTrailingStep(int step) { m_trailingStep = step; }
   void SetTrailingStop(int stop) { m_trailingStop = stop; }
};

//+------------------------------------------------------------------+
