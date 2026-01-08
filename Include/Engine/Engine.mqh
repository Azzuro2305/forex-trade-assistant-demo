//+------------------------------------------------------------------+
//| Engine.mqh                                                       |
//| Main Trading Engine - VPS-SAFE ONLY                             |
//+------------------------------------------------------------------+
#property copyright "Azzuro"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Config/Inputs.mqh"
#include "../Config/RuntimeConfig.mqh"
#include "../Core/Logger.mqh"
#include "../Core/TimeUtils.mqh"
#include "RiskManager.mqh"
#include "TradeManager.mqh"
#include "BEManager.mqh"
#include "TrailingManager.mqh"
#include "DDGuard.mqh"
#include "TradeEvents.mqh"
#include "Strategy.mqh"

//+------------------------------------------------------------------+
//| Trading Engine class                                            |
//+------------------------------------------------------------------+
class CEngine
{
private:
   CRuntimeConfig*  m_config;
   CLogger*         m_logger;
   CRiskManager*    m_riskManager;
   CTradeManager*   m_tradeManager;
   CBEManager*      m_beManager;
   CTrailingManager* m_trailingManager;
   CDDGuard*        m_ddGuard;
   CTradeEvents*    m_tradeEvents;
   CStrategy*       m_strategy;
   
   // Break Even settings
   int              m_bePoints;
   double           m_beOffset;
   
   // Trailing Stop settings
   int              m_trailingStart;
   int              m_trailingStep;
   int              m_trailingStop;
   
   // Drawdown Guard settings
   double           m_maxDrawdownPercent;
   
public:
   CEngine(CRuntimeConfig* config, CLogger* logger)
      : m_config(config), m_logger(logger)
   {
      m_riskManager = NULL;
      m_tradeManager = NULL;
      m_beManager = NULL;
      m_trailingManager = NULL;
      m_ddGuard = NULL;
      m_tradeEvents = NULL;
      m_strategy = NULL;
      
      // Default settings
      m_bePoints = 20;
      m_beOffset = 5.0;
      m_trailingStart = 30;
      m_trailingStep = 10;
      m_trailingStop = 20;
      m_maxDrawdownPercent = 10.0;
   }
   
   ~CEngine()
   {
      if(m_strategy != NULL) { delete m_strategy; m_strategy = NULL; }
      if(m_tradeEvents != NULL) { delete m_tradeEvents; m_tradeEvents = NULL; }
      if(m_ddGuard != NULL) { delete m_ddGuard; m_ddGuard = NULL; }
      if(m_trailingManager != NULL) { delete m_trailingManager; m_trailingManager = NULL; }
      if(m_beManager != NULL) { delete m_beManager; m_beManager = NULL; }
      if(m_tradeManager != NULL) { delete m_tradeManager; m_tradeManager = NULL; }
      if(m_riskManager != NULL) { delete m_riskManager; m_riskManager = NULL; }
   }
   
   //+------------------------------------------------------------------+
   //| Initialize engine                                               |
   //+------------------------------------------------------------------+
   bool Initialize()
   {
      if(m_config == NULL || m_logger == NULL)
         return false;
      
      // Initialize risk manager
      m_riskManager = new CRiskManager(InpRiskPercent, InpMaxDailyLoss, 
                                      InpMaxOpenPositions, m_logger);
      
      // Initialize trade manager
      m_tradeManager = new CTradeManager(m_config.GetMagicNumber(), 
                                        m_config.GetTradeComment(), m_logger);
      
      // Initialize break even manager
      m_beManager = new CBEManager(m_config.GetMagicNumber(), m_bePoints, m_beOffset,
                                   m_tradeManager, m_logger);
      
      // Initialize trailing manager
      m_trailingManager = new CTrailingManager(m_config.GetMagicNumber(), 
                                              m_trailingStart, m_trailingStep, m_trailingStop,
                                              m_tradeManager, m_logger);
      
      // Initialize drawdown guard
      m_ddGuard = new CDDGuard(m_config.GetMagicNumber(), m_maxDrawdownPercent,
                              m_tradeManager, m_logger);
      
      // Initialize trade events
      m_tradeEvents = new CTradeEvents(m_config.GetMagicNumber(), m_logger);
      
      // Initialize strategy
      m_strategy = new CStrategy(m_tradeManager, m_riskManager, m_logger);
      
      if(m_logger != NULL)
         m_logger.Info("Engine initialized successfully");
      
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Process engine (called from OnTick)                             |
   //+------------------------------------------------------------------+
   void Process()
   {
      if(m_config == NULL || !m_config.IsTradingEnabled())
         return;
      
      // Update drawdown guard
      if(m_ddGuard != NULL)
      {
         m_ddGuard.Update();
         
         // Check if trading is allowed
         if(!m_ddGuard.CanTrade())
            return;
      }
      
      // Process break even
      if(m_beManager != NULL)
         m_beManager.Process();
      
      // Process trailing stops
      if(m_trailingManager != NULL)
         m_trailingManager.Process();
      
      // Process strategy (if initialized)
      if(m_strategy != NULL)
      {
         m_strategy.Process();
      }
   }
   
   //+------------------------------------------------------------------+
   //| Handle trade transaction                                        |
   //+------------------------------------------------------------------+
   void OnTradeTransaction(const MqlTradeTransaction& trans,
                         const MqlTradeRequest& request,
                         const MqlTradeResult& result)
   {
      if(m_tradeEvents != NULL)
         m_tradeEvents.OnTradeTransaction(trans, request, result);
   }
   
   //+------------------------------------------------------------------+
   //| Get managers (for strategy access)                            |
   //+------------------------------------------------------------------+
   CRiskManager* GetRiskManager() { return m_riskManager; }
   CTradeManager* GetTradeManager() { return m_tradeManager; }
   CBEManager* GetBEManager() { return m_beManager; }
   CTrailingManager* GetTrailingManager() { return m_trailingManager; }
   CDDGuard* GetDDGuard() { return m_ddGuard; }
   
   //+------------------------------------------------------------------+
   //| Set strategy                                                    |
   //+------------------------------------------------------------------+
   void SetStrategy(CStrategy* strategy) { m_strategy = strategy; }
   
   //+------------------------------------------------------------------+
   //| Set break even parameters                                      |
   //+------------------------------------------------------------------+
   void SetBEParameters(int bePoints, double beOffset)
   {
      m_bePoints = bePoints;
      m_beOffset = beOffset;
      if(m_beManager != NULL)
      {
         m_beManager.SetBEPoints(bePoints);
         m_beManager.SetBEOffset(beOffset);
      }
   }
   
   //+------------------------------------------------------------------+
   //| Set trailing stop parameters                                   |
   //+------------------------------------------------------------------+
   void SetTrailingParameters(int start, int step, int stop)
   {
      m_trailingStart = start;
      m_trailingStep = step;
      m_trailingStop = stop;
      if(m_trailingManager != NULL)
      {
         m_trailingManager.SetTrailingStart(start);
         m_trailingManager.SetTrailingStep(step);
         m_trailingManager.SetTrailingStop(stop);
      }
   }
   
   //+------------------------------------------------------------------+
   //| Set max drawdown percent                                       |
   //+------------------------------------------------------------------+
   void SetMaxDrawdownPercent(double percent)
   {
      m_maxDrawdownPercent = percent;
      if(m_ddGuard != NULL)
         m_ddGuard.SetMaxDrawdownPercent(percent);
   }
};

//+------------------------------------------------------------------+
