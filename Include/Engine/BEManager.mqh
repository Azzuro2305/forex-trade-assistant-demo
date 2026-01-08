//+------------------------------------------------------------------+
//| BEManager.mqh                                                    |
//| Break Even Manager - VPS-SAFE ONLY                               |
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
//| Break Even Manager class                                         |
//+------------------------------------------------------------------+
class CBEManager
{
private:
   int      m_magicNumber;
   int      m_bePoints;        // Points profit before moving to BE
   double   m_beOffset;         // Offset from entry (in points) for BE
   CLogger* m_logger;
   CTradeManager* m_tradeManager;
   
public:
   CBEManager(int magic, int bePoints, double beOffset, CTradeManager* tradeMgr, CLogger* logger)
      : m_magicNumber(magic), m_bePoints(bePoints), m_beOffset(beOffset), 
        m_tradeManager(tradeMgr), m_logger(logger)
   {
   }
   
   //+------------------------------------------------------------------+
   //| Process break even for all positions                            |
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
   //| Process break even for single position                         |
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
      
      // Check if profit reached threshold
      if(profitPoints < m_bePoints)
         return; // Not enough profit yet
      
      // Check if already at break even or better
      bool alreadyAtBE = false;
      if(posType == POSITION_TYPE_BUY)
      {
         if(currentSL > 0 && currentSL >= entryPrice - (m_beOffset * pointValue))
            alreadyAtBE = true;
      }
      else
      {
         if(currentSL > 0 && currentSL <= entryPrice + (m_beOffset * pointValue))
            alreadyAtBE = true;
      }
      
      if(alreadyAtBE)
         return; // Already moved to BE
      
      // Move to break even
      double newSL = 0;
      if(posType == POSITION_TYPE_BUY)
      {
         newSL = entryPrice + (m_beOffset * pointValue); // Slightly above entry
      }
      else
      {
         newSL = entryPrice - (m_beOffset * pointValue); // Slightly below entry
      }
      
      double currentTP = PositionGetDouble(POSITION_TP);
      
      if(m_tradeManager != NULL)
      {
         if(m_tradeManager.ModifyPosition(ticket, newSL, currentTP))
         {
            if(m_logger != NULL)
               m_logger.Info("Position " + IntegerToString(ticket) + " moved to break even at " + DoubleToString(newSL, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)));
         }
      }
   }
   
   //+------------------------------------------------------------------+
   //| Set break even points                                           |
   //+------------------------------------------------------------------+
   void SetBEPoints(int bePoints) { m_bePoints = bePoints; }
   
   //+------------------------------------------------------------------+
   //| Set break even offset                                           |
   //+------------------------------------------------------------------+
   void SetBEOffset(double beOffset) { m_beOffset = beOffset; }
};

//+------------------------------------------------------------------+
