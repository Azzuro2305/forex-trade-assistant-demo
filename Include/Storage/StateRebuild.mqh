//+------------------------------------------------------------------+
//| StateRebuild.mqh                                                 |
//| State rebuild utilities - OPTIONAL, NON-CRITICAL                |
//+------------------------------------------------------------------+
#property copyright "Azzuro"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Core/Logger.mqh"

//+------------------------------------------------------------------+
//| State Rebuild class (Optional - for state reconstruction)      |
//+------------------------------------------------------------------+
// Note: This is optional and non-critical for VPS operation
// Engine should be able to rebuild state from open positions

class CStateRebuild
{
private:
   int      m_magicNumber;
   CLogger* m_logger;
   
public:
   CStateRebuild(int magic, CLogger* logger)
      : m_magicNumber(magic), m_logger(logger)
   {
   }
   
   //+------------------------------------------------------------------+
   //| Rebuild state from open positions                               |
   //+------------------------------------------------------------------+
   void RebuildFromPositions()
   {
      if(m_logger != NULL)
         m_logger.Info("Rebuilding state from open positions...");
      
      int positionCount = 0;
      for(int i = 0; i < PositionsTotal(); i++)
      {
         ulong ticket = PositionGetTicket(i);
         if(ticket > 0 && PositionGetInteger(POSITION_MAGIC) == m_magicNumber)
         {
            positionCount++;
            
            if(m_logger != NULL)
            {
               string symbol = PositionGetString(POSITION_SYMBOL);
               double volume = PositionGetDouble(POSITION_VOLUME);
               m_logger.Debug("Found position: " + IntegerToString(ticket) + 
                            " | Symbol: " + symbol + 
                            " | Volume: " + DoubleToString(volume, 2));
            }
         }
      }
      
      if(m_logger != NULL)
         m_logger.Info("State rebuild complete. Found " + IntegerToString(positionCount) + " positions");
   }
};

//+------------------------------------------------------------------+
