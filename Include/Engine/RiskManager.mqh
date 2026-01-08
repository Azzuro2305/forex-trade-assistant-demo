//+------------------------------------------------------------------+
//| RiskManager.mqh                                                  |
//| Risk management - VPS-SAFE ONLY                                 |
//+------------------------------------------------------------------+
#property copyright "Azzuro"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Config/Inputs.mqh"
#include "../Core/MathRisk.mqh"
#include "../Core/SymbolUtils.mqh"
#include "../Core/TimeUtils.mqh"
#include "../Core/Logger.mqh"

//+------------------------------------------------------------------+
//| Risk Manager class                                              |
//+------------------------------------------------------------------+
class CRiskManager
{
private:
   double   m_riskPercent;
   double   m_maxDailyLoss;
   int      m_maxOpenPositions;
   double   m_initialBalance;
   datetime m_currentDay;
   double   m_dailyLoss;
   CLogger* m_logger;

public:
   CRiskManager(double riskPercent, double maxDailyLoss, int maxOpenPos, CLogger* logger)
      : m_riskPercent(riskPercent), m_maxDailyLoss(maxDailyLoss), 
        m_maxOpenPositions(maxOpenPos), m_logger(logger)
   {
      m_initialBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      m_currentDay = 0;
      m_dailyLoss = 0;
      UpdateDailyLoss();
   }
   
   //+------------------------------------------------------------------+
   //| Update daily loss tracking                                      |
   //+------------------------------------------------------------------+
   void UpdateDailyLoss()
   {
      datetime today = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
      
      if(today != m_currentDay)
      {
         m_currentDay = today;
         m_initialBalance = AccountInfoDouble(ACCOUNT_BALANCE);
         m_dailyLoss = 0;
      }
      else
      {
         double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
         m_dailyLoss = m_initialBalance - currentBalance;
      }
   }
   
   //+------------------------------------------------------------------+
   //| Calculate lot size based on risk                               |
   //+------------------------------------------------------------------+
   double CalculateLotSize(int stopLossPoints, string symbol = NULL)
   {
      if(stopLossPoints <= 0) return InpLotSize;
      UpdateDailyLoss();
      return CalculateLotSizeByRisk(m_riskPercent, stopLossPoints, symbol);
   }
   
   //+------------------------------------------------------------------+
   //| Calculate lot size based on risk amount in currency            |
   //+------------------------------------------------------------------+
   double CalculateLotSizeByCurrency(double riskAmount, int stopLossPoints, string symbol = NULL)
   {
      return ::CalculateLotSizeByCurrency(riskAmount, stopLossPoints, symbol);
   }
   
   //+------------------------------------------------------------------+
   //| Calculate lot size based on risk percentage                    |
   //+------------------------------------------------------------------+
   double CalculateLotSizeByPercent(double riskPercent, int stopLossPoints, string symbol = NULL)
   {
      return CalculateLotSizeByRisk(riskPercent, stopLossPoints, symbol);
   }
   
   //+------------------------------------------------------------------+
   //| Calculate lot size for fixed volume                            |
   //+------------------------------------------------------------------+
   double CalculateLotSizeFixed(double fixedLotSize, string symbol = NULL)
   {
      return NormalizeLot(fixedLotSize, symbol);
   }
   
   //+------------------------------------------------------------------+
   //| Check if trading is allowed                                    |
   //+------------------------------------------------------------------+
   bool CanTrade(int currentOpenPositions)
   {
      UpdateDailyLoss();
      
      double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      if(m_initialBalance <= 0) return true; // Safety check
      
      double dailyLossPercent = (m_dailyLoss / m_initialBalance) * 100.0;
      
      // Check daily loss limit
      if(dailyLossPercent >= m_maxDailyLoss)
      {
         if(m_logger != NULL)
            m_logger.Warn("Daily loss limit reached: " + DoubleToString(dailyLossPercent, 2) + "%");
         return false;
      }
      
      // Check max open positions
      if(currentOpenPositions >= m_maxOpenPositions)
      {
         if(m_logger != NULL)
            m_logger.Debug("Max open positions reached: " + IntegerToString(currentOpenPositions));
         return false;
      }
      
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Get current daily loss percentage                              |
   //+------------------------------------------------------------------+
   double GetDailyLossPercent()
   {
      UpdateDailyLoss();
      if(m_initialBalance > 0)
         return (m_dailyLoss / m_initialBalance) * 100.0;
      return 0;
   }
   
   //+------------------------------------------------------------------+
   //| Get daily loss amount                                          |
   //+------------------------------------------------------------------+
   double GetDailyLoss()
   {
      UpdateDailyLoss();
      return m_dailyLoss;
   }
};

//+------------------------------------------------------------------+
