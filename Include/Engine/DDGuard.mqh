//+------------------------------------------------------------------+
//| DDGuard.mqh                                                      |
//| Drawdown Guard - VPS-SAFE ONLY                                  |
//+------------------------------------------------------------------+
#property copyright "Azzuro"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Config/Inputs.mqh"
#include "../Core/Logger.mqh"
#include "TradeManager.mqh"

//+------------------------------------------------------------------+
//| Drawdown Guard class                                            |
//+------------------------------------------------------------------+
class CDDGuard
{
private:
   int      m_magicNumber;
   double   m_maxDrawdownPercent;  // Max drawdown percentage
   double   m_initialBalance;      // Balance at start
   double   m_peakBalance;         // Peak balance reached
   double   m_currentDrawdown;     // Current drawdown percentage
   bool     m_tradingHalted;        // Trading halted flag
   CLogger* m_logger;
   CTradeManager* m_tradeManager;
   
public:
   CDDGuard(int magic, double maxDrawdownPercent, CTradeManager* tradeMgr, CLogger* logger)
      : m_magicNumber(magic), m_maxDrawdownPercent(maxDrawdownPercent),
        m_tradeManager(tradeMgr), m_logger(logger)
   {
      m_initialBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      m_peakBalance = m_initialBalance;
      m_currentDrawdown = 0;
      m_tradingHalted = false;
   }
   
   //+------------------------------------------------------------------+
   //| Update drawdown tracking                                        |
   //+------------------------------------------------------------------+
   void Update()
   {
      double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
      
      // Use equity for drawdown calculation (more accurate)
      double currentValue = currentEquity;
      
      // Update peak balance
      if(currentValue > m_peakBalance)
         m_peakBalance = currentValue;
      
      // Calculate drawdown from peak
      if(m_peakBalance > 0)
      {
         m_currentDrawdown = ((m_peakBalance - currentValue) / m_peakBalance) * 100.0;
      }
      else
      {
         m_currentDrawdown = 0;
      }
      
      // Check if drawdown limit exceeded
      if(m_currentDrawdown >= m_maxDrawdownPercent && !m_tradingHalted)
      {
         m_tradingHalted = true;
         
         if(m_logger != NULL)
            m_logger.Warn("Drawdown limit exceeded: " + DoubleToString(m_currentDrawdown, 2) + "% (Limit: " + DoubleToString(m_maxDrawdownPercent, 2) + "%)");
         
         // Optionally close all positions
         // if(m_tradeManager != NULL)
         //    m_tradeManager.CloseAllPositions();
      }
      
      // Reset if drawdown recovered
      if(m_currentDrawdown < (m_maxDrawdownPercent * 0.5) && m_tradingHalted)
      {
         m_tradingHalted = false;
         if(m_logger != NULL)
            m_logger.Info("Drawdown recovered. Trading resumed. Current DD: " + DoubleToString(m_currentDrawdown, 2) + "%");
      }
   }
   
   //+------------------------------------------------------------------+
   //| Check if trading is allowed                                    |
   //+------------------------------------------------------------------+
   bool CanTrade()
   {
      Update();
      return !m_tradingHalted;
   }
   
   //+------------------------------------------------------------------+
   //| Get current drawdown percentage                                |
   //+------------------------------------------------------------------+
   double GetDrawdownPercent()
   {
      Update();
      return m_currentDrawdown;
   }
   
   //+------------------------------------------------------------------+
   //| Check if trading is halted                                     |
   //+------------------------------------------------------------------+
   bool IsTradingHalted() const { return m_tradingHalted; }
   
   //+------------------------------------------------------------------+
   //| Reset guard (for testing or manual reset)                      |
   //+------------------------------------------------------------------+
   void Reset()
   {
      m_initialBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      m_peakBalance = m_initialBalance;
      m_currentDrawdown = 0;
      m_tradingHalted = false;
      
      if(m_logger != NULL)
         m_logger.Info("Drawdown guard reset");
   }
   
   //+------------------------------------------------------------------+
   //| Set max drawdown percent                                       |
   //+------------------------------------------------------------------+
   void SetMaxDrawdownPercent(double percent) { m_maxDrawdownPercent = percent; }
};

//+------------------------------------------------------------------+
