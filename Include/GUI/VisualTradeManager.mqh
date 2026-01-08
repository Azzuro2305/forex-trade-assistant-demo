//+------------------------------------------------------------------+
//| VisualTradeManager.mqh                                           |
//| Manages visual trading interface                                 |
//+------------------------------------------------------------------+
#property copyright "Azzuro"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "VisualTradeLines.mqh"
#include "TradingPanel.mqh"
#include "../Engine/TradeManager.mqh"
#include "../Engine/RiskManager.mqh"
#include "../Utils/Helpers.mqh"
#include "../Core/SymbolUtils.mqh"
#include "../Core/MathRisk.mqh"

//+------------------------------------------------------------------+
//| Visual Trade Manager class                                       |
//+------------------------------------------------------------------+
class CVisualTradeManager
{
private:
   CVisualTradeLines* m_tradeLines;
   CTradingPanel*     m_panel;
   CTradeManager*     m_tradeManager;
   CRiskManager*      m_riskManager;
   CLogger*           m_logger;
   bool               m_enabled;
   bool               m_enableUI;
   
public:
   CVisualTradeManager(CTradeManager* tradeMgr, CRiskManager* riskMgr, CLogger* logger)
   {
      m_tradeManager = tradeMgr;
      m_riskManager = riskMgr;
      m_logger = logger;
      m_enabled = InpEnableVisualTrading;
      m_enableUI = InpEnableUI;  // Use EnableUI flag instead of VPSMode
      
      m_tradeLines = new CVisualTradeLines();
      m_panel = new CTradingPanel(InpPanelX, InpPanelY, logger);
   }
   
   ~CVisualTradeManager()
   {
      if(m_tradeLines != NULL) { delete m_tradeLines; m_tradeLines = NULL; }
      if(m_panel != NULL) { delete m_panel; m_panel = NULL; }
   }
   
   //+------------------------------------------------------------------+
   //| Initialize                                                       |
   //+------------------------------------------------------------------+
   bool Initialize()
   {
      if(!m_enabled) return true;
      
      if(m_enableUI)
      {
         if(!m_panel.Create())
         {
            if(m_logger != NULL)
               m_logger.Error("Failed to create trading panel");
            return false;
         }
      }
      
      if(m_logger != NULL)
         m_logger.Info("Visual trading initialized" + (m_enableUI ? "" : " (UI Disabled)"));
      
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Handle chart event                                              |
   //+------------------------------------------------------------------+
   void OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
   {
      if(!m_enabled || !m_enableUI) return;
      
      // Handle input box edits for visual lines
      if(id == CHARTEVENT_OBJECT_ENDEDIT && m_tradeLines != NULL && m_tradeLines.IsActive())
      {
         if(StringFind(sparam, "VTL_") >= 0)
         {
            string inputText = ObjectGetString(0, sparam, OBJPROP_TEXT);
            if(m_tradeLines.HandleInputEdit(sparam, inputText))
            {
               UpdateLotSizeDisplay();
               ChartRedraw();
            }
         }
      }
      
      // Handle open button click
      if(id == CHARTEVENT_OBJECT_CLICK && m_tradeLines != NULL && m_tradeLines.IsActive())
      {
         if(m_tradeLines.IsOpenButtonClicked(sparam))
         {
            ExecuteTrade();
            return;
         }
      }
      
      // Handle line click - auto-select for immediate dragging
      if(id == CHARTEVENT_CLICK && m_tradeLines != NULL && m_tradeLines.IsActive())
      {
         if(StringFind(sparam, "VTL_") >= 0 && (StringFind(sparam, "_Entry") >= 0 || 
            StringFind(sparam, "_TP") >= 0 || StringFind(sparam, "_SL") >= 0))
         {
            // Line clicked - ensure it's selected for dragging
            ObjectSetInteger(0, sparam, OBJPROP_SELECTED, true);
            ChartRedraw();
         }
      }
      
      // Handle line dragging
      if(id == CHARTEVENT_OBJECT_DRAG && m_tradeLines != NULL && m_tradeLines.IsActive())
      {
         if(StringFind(sparam, "VTL_") >= 0 && StringFind(sparam, "_Entry") >= 0)
         {
            // Entry line dragged - update lot size and order type label
            m_tradeLines.Update();
            UpdateLotSizeDisplay();
         }
         else if(StringFind(sparam, "VTL_") >= 0)
         {
            // TP or SL dragged - update lot size and shaded areas
            m_tradeLines.Update();
            UpdateLotSizeDisplay();
         }
      }
      
      // Handle panel events
      if(m_panel != NULL)
      {
         if(m_panel.OnChartEvent(id, lparam, dparam, sparam))
         {
            // Handle panel button clicks
            if(m_panel.IsBuyClicked(sparam))
            {
               CreateBuySetup();
            }
            else if(m_panel.IsSellClicked(sparam))
            {
               CreateSellSetup();
            }
            else if(m_panel.IsCloseAllClicked(sparam))
            {
               CloseAllPositions();
            }
            else if(m_panel.IsClearLinesClicked(sparam))
            {
               ClearLines();
            }
            else if(m_panel.IsExecuteClicked(sparam))
            {
               ExecuteTrade();
            }
         }
      }
      
      // Handle keyboard shortcuts (Enter to execute trade)
      if(id == CHARTEVENT_KEYDOWN)
      {
         if(lparam == 13) // Enter key
         {
            if(m_tradeLines != NULL && m_tradeLines.IsActive())
            {
               ExecuteTrade();
            }
         }
         else if(lparam == 27) // Escape key
         {
            ClearLines();
         }
      }
   }
   
   //+------------------------------------------------------------------+
   //| Update (called from OnTick)                                    |
   //+------------------------------------------------------------------+
   void Update()
   {
      if(!m_enabled) return;
      
      if(m_tradeLines != NULL && m_tradeLines.IsActive())
      {
         m_tradeLines.Update();
         UpdateLotSizeDisplay();
      }
      
      if(m_panel != NULL && m_enableUI)
      {
         m_panel.UpdateAccountInfo();
      }
   }
   
   //+------------------------------------------------------------------+
   //| Create buy setup                                                |
   //+------------------------------------------------------------------+
   void CreateBuySetup()
   {
      if(!m_enableUI) return;
      
      double entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double tpPrice = 0;
      double slPrice = 0;
      
      // Use fixed RR if enabled
      if(InpUseFixedRR && InpFixedRR > 0)
      {
         int slPoints = InpStopLoss > 0 ? InpStopLoss : 50;
         int tpPoints = (int)MathRound(slPoints * InpFixedRR);
         tpPrice = entryPrice + PointsToPrice(tpPoints);
         slPrice = entryPrice - PointsToPrice(slPoints);
      }
      else
      {
         // Use price gaps: TP = 30.00, SL = 10.00
         tpPrice = NormalizePrice(entryPrice + 30.00);
         slPrice = NormalizePrice(entryPrice - 10.00);
      }
      
      if(m_tradeLines != NULL)
      {
         if(m_tradeLines.CreateBuySetup(entryPrice, tpPrice, slPrice))
         {
            UpdateLotSizeDisplay();
            if(m_logger != NULL)
               m_logger.Info("Buy setup created at " + DoubleToString(entryPrice, _Digits));
         }
      }
   }
   
   //+------------------------------------------------------------------+
   //| Create sell setup                                               |
   //+------------------------------------------------------------------+
   void CreateSellSetup()
   {
      if(!m_enableUI) return;
      
      double entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double tpPrice = 0;
      double slPrice = 0;
      
      // Use fixed RR if enabled
      if(InpUseFixedRR && InpFixedRR > 0)
      {
         int slPoints = InpStopLoss > 0 ? InpStopLoss : 50;
         int tpPoints = (int)MathRound(slPoints * InpFixedRR);
         tpPrice = entryPrice - PointsToPrice(tpPoints);
         slPrice = entryPrice + PointsToPrice(slPoints);
      }
      else
      {
         // Use price gaps: TP = 30.00, SL = 10.00
         tpPrice = NormalizePrice(entryPrice - 30.00);
         slPrice = NormalizePrice(entryPrice + 10.00);
      }
      
      if(m_tradeLines != NULL)
      {
         if(m_tradeLines.CreateSellSetup(entryPrice, tpPrice, slPrice))
         {
            UpdateLotSizeDisplay();
            if(m_logger != NULL)
               m_logger.Info("Sell setup created at " + DoubleToString(entryPrice, _Digits));
         }
      }
   }
   
   //+------------------------------------------------------------------+
   //| Execute trade from visual lines                                 |
   //+------------------------------------------------------------------+
   bool ExecuteTrade()
   {
      if(m_tradeLines == NULL || !m_tradeLines.IsActive())
      {
         if(m_logger != NULL)
            m_logger.Warn("No active trade setup");
         return false;
      }
      
      if(m_tradeManager == NULL || m_riskManager == NULL)
      {
         if(m_logger != NULL)
            m_logger.Error("Trade manager or risk manager not initialized");
         return false;
      }
      
      double entryPrice = m_tradeLines.GetEntryPrice();
      double tpPrice = m_tradeLines.GetTPPrice();
      double slPrice = m_tradeLines.GetSLPrice();
      int tpPoints = m_tradeLines.GetTPPoints();
      int slPoints = m_tradeLines.GetSLPoints();
      bool isBuy = m_tradeLines.IsBuy();
      ENUM_ORDER_TYPE orderType = m_tradeLines.GetOrderType();
      
      // #region agent log
      double currentAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double currentBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      string dataJson = "{\"hypothesisId\":\"D\",\"entryPrice\":" + DoubleToString(entryPrice, 8) + ",\"orderType\":" + IntegerToString(orderType) + ",\"isBuy\":" + (isBuy ? "true" : "false") + ",\"currentAsk\":" + DoubleToString(currentAsk, 8) + ",\"currentBid\":" + DoubleToString(currentBid, 8) + "}";
      WriteDebugLog("VisualTradeManager.mqh:294", "ExecuteTrade entryPrice retrieved", dataJson);
      // #endregion agent log
      
      // Calculate lot size based on risk mode
      double lotSize = 0;
      ENUM_RISK_MODE riskMode = RISK_MODE_PERCENT;
      
      if(m_panel != NULL && m_enableUI)
      {
         riskMode = m_panel.GetRiskMode();
         
         if(riskMode == RISK_MODE_CURRENCY)
         {
            double riskAmount = m_panel.GetRiskCurrency();
            lotSize = m_riskManager.CalculateLotSizeByCurrency(riskAmount, slPoints);
         }
         else if(riskMode == RISK_MODE_PERCENT)
         {
            double riskPercent = m_panel.GetRiskPercent();
            lotSize = m_riskManager.CalculateLotSizeByPercent(riskPercent, slPoints);
         }
         else if(riskMode == RISK_MODE_FIXED)
         {
            double fixedLot = m_panel.GetFixedLotSize();
            lotSize = m_riskManager.CalculateLotSizeFixed(fixedLot);
         }
      }
      else
      {
         // VPS mode or no panel - use default risk percent
         lotSize = m_riskManager.CalculateLotSize(slPoints);
      }
      
      if(lotSize <= 0)
      {
         if(m_logger != NULL)
            m_logger.Error("Invalid lot size calculated: " + DoubleToString(lotSize, 2));
         return false;
      }
      
      // Check if AutoTrading is enabled
      if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
      {
         if(m_logger != NULL)
            m_logger.Error("Trading is not allowed in terminal settings");
         return false;
      }
      
      if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
      {
         if(m_logger != NULL)
            m_logger.Error("Trading is not allowed - check AutoTrading button");
         return false;
      }
      
      // Execute trade
      bool success = false;
      
      if(orderType == ORDER_TYPE_BUY || orderType == ORDER_TYPE_SELL)
      {
         // Market order
         if(isBuy)
            success = m_tradeManager.OpenBuy(lotSize, slPoints, tpPoints);
         else
            success = m_tradeManager.OpenSell(lotSize, slPoints, tpPoints);
      }
      else
      {
         // Pending order - execute at entry price
         if(orderType == ORDER_TYPE_BUY_LIMIT)
         {
            success = m_tradeManager.OpenBuyLimit(entryPrice, lotSize, slPoints, tpPoints);
         }
         else if(orderType == ORDER_TYPE_BUY_STOP)
         {
            // #region agent log
            double currentAsk2 = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            string dataJson2 = "{\"hypothesisId\":\"A,B\",\"entryPrice\":" + DoubleToString(entryPrice, 8) + ",\"currentAsk\":" + DoubleToString(currentAsk2, 8) + ",\"lotSize\":" + DoubleToString(lotSize, 2) + ",\"slPoints\":" + IntegerToString(slPoints) + ",\"tpPoints\":" + IntegerToString(tpPoints) + "}";
            WriteDebugLog("VisualTradeManager.mqh:372", "Before OpenBuyStop call", dataJson2);
            // #endregion agent log
            success = m_tradeManager.OpenBuyStop(entryPrice, lotSize, slPoints, tpPoints);
         }
         else if(orderType == ORDER_TYPE_SELL_LIMIT)
         {
            success = m_tradeManager.OpenSellLimit(entryPrice, lotSize, slPoints, tpPoints);
         }
         else if(orderType == ORDER_TYPE_SELL_STOP)
         {
            success = m_tradeManager.OpenSellStop(entryPrice, lotSize, slPoints, tpPoints);
         }
         
         if(m_logger != NULL && success)
            m_logger.Info("Pending order placed: " + EnumToString(orderType) + " at " + DoubleToString(entryPrice, _Digits));
      }
      
      if(success)
      {
         if(m_logger != NULL)
            m_logger.Info("Trade executed: " + (isBuy ? "BUY" : "SELL") + " " + 
                         DoubleToString(lotSize, 2) + " lots, SL: " + IntegerToString(slPoints) + 
                         " pts, TP: " + IntegerToString(tpPoints) + " pts");
         
         // Clear lines after successful trade
         ClearLines();
      }
      else
      {
         if(m_logger != NULL)
            m_logger.Error("Trade execution failed");
      }
      
      return success;
   }
   
   //+------------------------------------------------------------------+
   //| Close all positions                                             |
   //+------------------------------------------------------------------+
   void CloseAllPositions()
   {
      if(m_tradeManager != NULL)
      {
         if(m_tradeManager.CloseAllPositions())
         {
            if(m_logger != NULL)
               m_logger.Info("All positions closed");
         }
      }
   }
   
   //+------------------------------------------------------------------+
   //| Clear visual lines                                              |
   //+------------------------------------------------------------------+
   void ClearLines()
   {
      if(m_tradeLines != NULL)
      {
         m_tradeLines.DeleteAll();
         if(m_logger != NULL)
            m_logger.Debug("Visual lines cleared");
      }
   }
   
   //+------------------------------------------------------------------+
   //| Update lot size display                                        |
   //+------------------------------------------------------------------+
   void UpdateLotSizeDisplay()
   {
      if(!m_enableUI || m_panel == NULL || m_tradeLines == NULL || !m_tradeLines.IsActive())
         return;
      
      int slPoints = m_tradeLines.GetSLPoints();
      if(slPoints <= 0) return;
      
      double lotSize = 0;
      ENUM_RISK_MODE riskMode = RISK_MODE_PERCENT;
      
      if(m_panel != NULL)
      {
         riskMode = m_panel.GetRiskMode();
         
         if(riskMode == RISK_MODE_CURRENCY)
         {
            double riskAmount = m_panel.GetRiskCurrency();
            lotSize = m_riskManager.CalculateLotSizeByCurrency(riskAmount, slPoints);
         }
         else if(riskMode == RISK_MODE_PERCENT)
         {
            double riskPercent = m_panel.GetRiskPercent();
            lotSize = m_riskManager.CalculateLotSizeByPercent(riskPercent, slPoints);
         }
         else if(riskMode == RISK_MODE_FIXED)
         {
            double fixedLot = m_panel.GetFixedLotSize();
            lotSize = m_riskManager.CalculateLotSizeFixed(fixedLot);
         }
      }
      
      if(lotSize > 0)
      {
         m_panel.UpdateLotSize(lotSize, slPoints);
      }
   }
   
   //+------------------------------------------------------------------+
   //| Check if enabled                                                |
   //+------------------------------------------------------------------+
   bool IsEnabled() { return m_enabled; }
   
   //+------------------------------------------------------------------+
   //| Check if UI enabled                                              |
   //+------------------------------------------------------------------+
   bool IsUIEnabled() { return m_enableUI; }
};

//+------------------------------------------------------------------+