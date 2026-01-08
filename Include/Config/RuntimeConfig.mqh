//+------------------------------------------------------------------+
//| RuntimeConfig.mqh                                                |
//| Runtime configuration and state - VPS-safe                      |
//+------------------------------------------------------------------+
#property copyright "Azzuro"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "Inputs.mqh"

//+------------------------------------------------------------------+
//| Runtime Configuration Class                                      |
//+------------------------------------------------------------------+
class CRuntimeConfig
{
private:
   bool m_enableUI;
   bool m_enableTrading;
   int  m_magicNumber;
   string m_tradeComment;
   
public:
   CRuntimeConfig()
   {
      m_enableUI = InpEnableUI;
      m_enableTrading = InpEnableTrading;
      m_magicNumber = InpMagicNumber;
      m_tradeComment = InpTradeComment;
   }
   
   bool IsUIEnabled() const { return m_enableUI; }
   bool IsTradingEnabled() const { return m_enableTrading; }
   int GetMagicNumber() const { return m_magicNumber; }
   string GetTradeComment() const { return m_tradeComment; }
   
   // Check if running on VPS (no chart objects available)
   bool IsVPSMode() const
   {
      // On VPS, chart objects typically fail or are unavailable
      // This is a heuristic check - UI should be disabled via InpEnableUI
      return !m_enableUI;
   }
};

//+------------------------------------------------------------------+
