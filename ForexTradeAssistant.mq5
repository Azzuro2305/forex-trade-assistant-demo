//+------------------------------------------------------------------+
//| ForexTradeAssistant.mq5                                          |
//| Main Expert Advisor file - VPS Compatible                        |
//+------------------------------------------------------------------+
#property copyright "Azzuro"
#property link      "https://www.mql5.com"
#property version   "2.00"
#property strict

//+------------------------------------------------------------------+
//| Includes - Core (Always loaded)                                  |
//+------------------------------------------------------------------+
#include "Include/Config/Inputs.mqh"
#include "Include/Config/RuntimeConfig.mqh"
#include "Include/Core/Logger.mqh"
#include "Include/Engine/Engine.mqh"

//+------------------------------------------------------------------+
//| Includes - GUI (Conditional - Only if EnableUI=true)            |
//+------------------------------------------------------------------+
// Note: GUI includes are loaded but only used if InpEnableUI=true
// This allows the EA to compile with GUI code but skip execution on VPS
#include "Include/GUI/VisualTradeManager.mqh"

//+------------------------------------------------------------------+
//| Global objects                                                   |
//+------------------------------------------------------------------+
CRuntimeConfig* g_config = NULL;
CLogger*        g_logger = NULL;
CEngine*        g_engine = NULL;
CVisualTradeManager* g_visualTrade = NULL;  // GUI object (only used if EnableUI=true)

// Runtime GUI flag (set from input)
bool g_enableUI = true;

//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit()
{
   // Initialize runtime config
   g_config = new CRuntimeConfig();
   g_enableUI = g_config.IsUIEnabled();
   
   // Initialize logger
   g_logger = new CLogger(EA_NAME);
   g_logger.Info("Initializing " + EA_NAME + " v" + EA_VERSION);
   
   // Validate inputs
   if(InpMagicNumber <= 0)
   {
      g_logger.Error("Invalid Magic Number: " + IntegerToString(InpMagicNumber));
      return INIT_PARAMETERS_INCORRECT;
   }
   
   if(InpLotSize <= 0)
   {
      g_logger.Error("Invalid Lot Size: " + DoubleToString(InpLotSize, 2));
      return INIT_PARAMETERS_INCORRECT;
   }
   
   // Initialize engine (VPS-safe)
   g_engine = new CEngine(g_config, g_logger);
   if(!g_engine.Initialize())
   {
      g_logger.Error("Engine initialization failed");
      return INIT_FAILED;
   }
   
   // Initialize GUI (only if UI enabled)
   if(g_enableUI && InpEnableVisualTrading)
   {
      // Get managers from engine for GUI
      CTradeManager* tradeMgr = g_engine.GetTradeManager();
      CRiskManager* riskMgr = g_engine.GetRiskManager();
      
      if(tradeMgr != NULL && riskMgr != NULL)
      {
         g_visualTrade = new CVisualTradeManager(tradeMgr, riskMgr, g_logger);
         if(!g_visualTrade.Initialize())
         {
            g_logger.Warn("Visual trading initialization failed, continuing without GUI");
            delete g_visualTrade;
            g_visualTrade = NULL;
         }
         else
         {
            g_logger.Info("UI enabled - Visual trading initialized");
         }
      }
   }
   else
   {
      g_logger.Info("UI disabled - Running in VPS mode");
   }
   
   // Log initialization complete
   g_logger.Info("EA initialized successfully");
   g_logger.Info("Magic Number: " + IntegerToString(InpMagicNumber));
   g_logger.Info("Risk Per Trade: " + DoubleToString(InpRiskPercent, 2) + "%");
   g_logger.Info("Max Daily Loss: " + DoubleToString(InpMaxDailyLoss, 2) + "%");
   g_logger.Info("Trading Enabled: " + (string)InpEnableTrading);
   g_logger.Info("UI Enabled: " + (string)g_enableUI);
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization                                         |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(g_logger != NULL)
   {
      string reasonText = "";
      switch(reason)
      {
         case REASON_PROGRAM:    reasonText = "EA stopped manually"; break;
         case REASON_REMOVE:     reasonText = "EA removed from chart"; break;
         case REASON_RECOMPILE:  reasonText = "EA recompiled"; break;
         case REASON_CHARTCHANGE: reasonText = "Chart symbol/timeframe changed"; break;
         case REASON_CHARTCLOSE: reasonText = "Chart closed"; break;
         case REASON_PARAMETERS: reasonText = "Input parameters changed"; break;
         case REASON_ACCOUNT:    reasonText = "Account changed"; break;
         case REASON_TEMPLATE:   reasonText = "Template applied"; break;
         case REASON_INITFAILED: reasonText = "Initialization failed"; break;
         case REASON_CLOSE:      reasonText = "Terminal closed"; break;
         default:                reasonText = "Unknown reason: " + IntegerToString(reason);
      }
      g_logger.Info("EA deinitialized: " + reasonText);
   }
   
   // Clean up objects
   if(g_visualTrade != NULL)   { delete g_visualTrade; g_visualTrade = NULL; }
   if(g_engine != NULL)        { delete g_engine; g_engine = NULL; }
   if(g_logger != NULL)         { delete g_logger; g_logger = NULL; }
   if(g_config != NULL)        { delete g_config; g_config = NULL; }
}

//+------------------------------------------------------------------+
//| Expert tick function                                            |
//+------------------------------------------------------------------+
void OnTick()
{
   // Process engine (VPS-safe - always runs)
   if(g_engine != NULL)
   {
      g_engine.Process();
   }
   
   // Update GUI (only if UI enabled)
   if(g_enableUI && g_visualTrade != NULL)
   {
      g_visualTrade.Update();
   }
}

//+------------------------------------------------------------------+
//| Trade transaction event handler                                 |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                       const MqlTradeRequest& request,
                       const MqlTradeResult& result)
{
   // Handle trade events in engine (VPS-safe)
   if(g_engine != NULL)
   {
      g_engine.OnTradeTransaction(trans, request, result);
   }
}

//+------------------------------------------------------------------+
//| Chart event handler (LOCAL ONLY - not called on VPS)           |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
{
   // Only handle chart events if UI is enabled
   if(!g_enableUI) return;
   
   // Handle visual trading events
   if(g_visualTrade != NULL)
   {
      g_visualTrade.OnChartEvent(id, lparam, dparam, sparam);
   }
}

//+------------------------------------------------------------------+
