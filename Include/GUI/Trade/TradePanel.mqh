//+------------------------------------------------------------------+
//| TradePanel.mqh                                                   |
//| Trade Tab Panel - Buy/Sell controls                             |
//+------------------------------------------------------------------+
#property copyright "Azzuro"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Panel.mqh"
#include "../Controls.mqh"
#include "VisualTradeLines.mqh"
#include "../../Engine/TradeManager.mqh"
#include "../../Engine/RiskManager.mqh"
#include "../../Core/Logger.mqh"
#include "../../Core/MathRisk.mqh"
#include "../../Core/SymbolUtils.mqh"
#include "../../Utils/Helpers.mqh"

//+------------------------------------------------------------------+
//| Trade Panel class                                                |
//+------------------------------------------------------------------+
class CTradePanel : public CPanel
{
private:
   CTradeManager*  m_tradeManager;
   CRiskManager*   m_riskManager;
   CLogger*        m_logger;
   CVisualTradeLines* m_visualLines;
   
   // Input values
   double          m_volume;
   int             m_stopLoss;
   int             m_takeProfit;
   double          m_riskPercent;
   
   // Control names
   string          m_btnBuyName;
   string          m_btnSellName;
   string          m_editVolumeName;
   string          m_editSLName;
   string          m_editTPName;
   string          m_editRiskName;
   string          m_labelVolumeName;
   string          m_labelSLName;
   string          m_labelTPName;
   string          m_labelRiskName;
   string          m_labelBuyValueName;
   string          m_labelSellValueName;
   
public:
   CTradePanel(CTradeManager* tradeMgr, CRiskManager* riskMgr, CLogger* logger)
      : CPanel("TradePanel_" + IntegerToString(GetTickCount()), 0, 0, PANEL_WIDTH, PANEL_HEIGHT - HEADER_HEIGHT - TAB_HEIGHT)
   {
      m_tradeManager = tradeMgr;
      m_riskManager = riskMgr;
      m_logger = logger;
      m_visualLines = new CVisualTradeLines();
      
      m_volume = InpLotSize;
      m_stopLoss = InpStopLoss;
      m_takeProfit = InpTakeProfit;
      m_riskPercent = InpRiskPercent;
      
      m_btnBuyName = m_panelName + "_BtnBuy";
      m_btnSellName = m_panelName + "_BtnSell";
      m_editVolumeName = m_panelName + "_EditVolume";
      m_editSLName = m_panelName + "_EditSL";
      m_editTPName = m_panelName + "_EditTP";
      m_editRiskName = m_panelName + "_EditRisk";
      m_labelVolumeName = m_panelName + "_LabelVolume";
      m_labelSLName = m_panelName + "_LabelSL";
      m_labelTPName = m_panelName + "_LabelTP";
      m_labelRiskName = m_panelName + "_LabelRisk";
      m_labelBuyValueName = m_panelName + "_LabelBuyValue";
      m_labelSellValueName = m_panelName + "_LabelSellValue";
   }
   
   //+------------------------------------------------------------------+
   //| Create panel                                                    |
   //+------------------------------------------------------------------+
   bool Create() override
   {
      if(!m_enableUI || !m_visible) return true;
      
      int startY = m_y + 20;
      int currentY = startY;
      
      // Volume input
      if(!CreateUILabel(m_labelVolumeName, m_x + 20, currentY, "Volume:", COLOR_TEXT_PRIMARY))
         return false;
      if(!CreateUIEdit(m_editVolumeName, m_x + 100, currentY, 100, 25, DoubleToString(m_volume, 2)))
         return false;
      
      currentY += 35;
      
      // SL input
      if(!CreateUILabel(m_labelSLName, m_x + 20, currentY, "SL:", COLOR_TEXT_PRIMARY))
         return false;
      if(!CreateUIEdit(m_editSLName, m_x + 100, currentY, 100, 25, IntegerToString(m_stopLoss)))
         return false;
      
      currentY += 35;
      
      // TP input
      if(!CreateUILabel(m_labelTPName, m_x + 20, currentY, "TP:", COLOR_TEXT_PRIMARY))
         return false;
      if(!CreateUIEdit(m_editTPName, m_x + 100, currentY, 100, 25, IntegerToString(m_takeProfit)))
         return false;
      
      currentY += 35;
      
      // Risk per Trade input
      if(!CreateUILabel(m_labelRiskName, m_x + 20, currentY, "Risk per Trade:", COLOR_TEXT_PRIMARY))
         return false;
      if(!CreateUIEdit(m_editRiskName, m_x + 120, currentY, 80, 25, DoubleToString(m_riskPercent, 2) + "%"))
         return false;
      
      currentY += 50;
      
      // Large Buy/Sell buttons with calculated values
      double buyValue = CalculateTradeValue(true);
      double sellValue = CalculateTradeValue(false);
      
      if(!CreateUIButton(m_btnBuyName + "_Large", m_x + 20, currentY, 140, 30, "BUY", COLOR_BUTTON_BUY))
         return false;
      // if(!CreateUILabel(m_labelBuyValueName, m_x + 30, currentY + 40, "$" + DoubleToString(buyValue, 2), COLOR_TEXT_PRIMARY))
      //    return false;
      
      if(!CreateUIButton(m_btnSellName + "_Large", m_x + 200, currentY, 140, 30, "SELL", COLOR_BUTTON_SELL))
         return false;
      // if(!CreateUILabel(m_labelSellValueName, m_x + 300, currentY + 40, "$" + DoubleToString(sellValue, 2), COLOR_TEXT_PRIMARY))
      //    return false;
      
      ChartRedraw();
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Calculate risk amount in currency                               |
   //+------------------------------------------------------------------+
   double CalculateRiskAmount()
   {
      if(m_riskManager == NULL || m_stopLoss <= 0) return 0;
      
      // Get lot size and SL points from visual lines if active, otherwise use inputs
      double lotSize = m_volume;
      int slPoints = m_stopLoss;
      
      if(m_visualLines != NULL && m_visualLines.IsActive())
      {
         slPoints = m_visualLines.GetSLPoints();
         if(slPoints > 0)
         {
            // Calculate lot size based on risk percentage and SL
            lotSize = m_riskManager.CalculateLotSize(slPoints);
         }
      }
      else
      {
         // Calculate lot size based on risk percentage
         lotSize = m_riskManager.CalculateLotSize(slPoints);
      }
      
      // Calculate risk amount in currency (call global function)
      return ::CalculateRiskAmount(lotSize, slPoints);
   }
   
   //+------------------------------------------------------------------+
   //| Calculate profit amount in currency                             |
   //+------------------------------------------------------------------+
   double CalculateProfitAmount()
   {
      if(m_riskManager == NULL || m_takeProfit <= 0) return 0;
      
      // Get lot size and TP points from visual lines if active, otherwise use inputs
      double lotSize = m_volume;
      int tpPoints = m_takeProfit;
      
      if(m_visualLines != NULL && m_visualLines.IsActive())
      {
         tpPoints = m_visualLines.GetTPPoints();
         int slPoints = m_visualLines.GetSLPoints();
         if(slPoints > 0)
         {
            // Calculate lot size based on risk percentage and SL
            lotSize = m_riskManager.CalculateLotSize(slPoints);
         }
      }
      else
      {
         // Calculate lot size based on risk percentage
         int slPoints = m_stopLoss;
         if(slPoints > 0)
            lotSize = m_riskManager.CalculateLotSize(slPoints);
      }
      
      // Calculate profit amount in currency (call global function)
      return ::CalculateProfitAmount(lotSize, tpPoints);
   }
   
   //+------------------------------------------------------------------+
   //| Calculate trade value (risk amount for buttons)                |
   //+------------------------------------------------------------------+
   double CalculateTradeValue(bool isBuy)
   {
      // Return risk amount to display on buttons
      return CalculateRiskAmount();
   }
   
   //+------------------------------------------------------------------+
   //| Handle chart event                                              |
   //+------------------------------------------------------------------+
   bool OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam) override
   {
      if(!m_enableUI) return false;
      
      // Handle visual lines events first
      if(m_visualLines != NULL && m_visualLines.IsActive())
      {
         // Handle input box edits for visual lines
         if(id == CHARTEVENT_OBJECT_ENDEDIT)
         {
            // #region agent log
            string dataJson0 = "{\"hypothesisId\":\"C\",\"sparam\":\"" + sparam + "\",\"containsVTL\":" + (StringFind(sparam, "VTL_") >= 0 ? "true" : "false") + "}";
            WriteDebugLog("TradePanel.mqh:221", "CHARTEVENT_OBJECT_ENDEDIT received", dataJson0);
            // #endregion agent log
            
            if(StringFind(sparam, "VTL_") >= 0)
            {
               string inputText = ObjectGetString(0, sparam, OBJPROP_TEXT);
               
               // #region agent log
               string dataJson1 = "{\"hypothesisId\":\"D\",\"sparam\":\"" + sparam + "\",\"inputText\":\"" + inputText + "\"}";
               WriteDebugLog("TradePanel.mqh:227", "Before HandleInputEdit", dataJson1);
               // #endregion agent log
               
               if(m_visualLines.HandleInputEdit(sparam, inputText))
               {
                  // #region agent log
                  string dataJson2 = "{\"hypothesisId\":\"E\",\"sparam\":\"" + sparam + "\",\"result\":\"success\"}";
                  WriteDebugLog("TradePanel.mqh:230", "HandleInputEdit returned true", dataJson2);
                  // #endregion agent log
                  
                  UpdateVisualLinesFromInputs();
                  ChartRedraw();
                  return true;
               }
               else
               {
                  // #region agent log
                  string dataJson3 = "{\"hypothesisId\":\"E\",\"sparam\":\"" + sparam + "\",\"result\":\"failed\"}";
                  WriteDebugLog("TradePanel.mqh:235", "HandleInputEdit returned false", dataJson3);
                  // #endregion agent log
               }
            }
         }
         
         // Handle open button click on visual lines
         if(id == CHARTEVENT_OBJECT_CLICK)
         {
            if(m_visualLines.IsOpenButtonClicked(sparam))
            {
               ExecuteTradeFromVisualLines();
               return true;
            }
            
            // Handle pin button click
            if(m_visualLines.IsPinButtonClicked(sparam))
            {
               m_visualLines.TogglePinForLine(sparam);
               return true;
            }
         }
         
         // Handle line dragging - update values when lines are moved
         // CRITICAL: Return false to let MT5 handle native dragging, we only sync UI
         if(id == CHARTEVENT_OBJECT_DRAG)
         {
            if(StringFind(sparam, "VTL_") >= 0)
            {
               // Just ensure it's selectable (don't interfere with MT5's drag handling)
               ObjectSetInteger(0, sparam, OBJPROP_SELECTABLE, true);
               
               // Update visual lines UI (but don't block native drag)
               m_visualLines.Update();
               m_visualLines.RefreshShadedAreas();
               UpdateInputsFromVisualLines();
               UpdateValues(); // This will update risk/profit labels
               ChartRedraw(); // Redraw immediately to show updated shaded areas
               return false; // CRITICAL: Let MT5 handle the actual dragging!
            }
         }
         
         // Handle drag end (CHANGE event) - validate after drag completes
         if(id == CHARTEVENT_OBJECT_CHANGE)
         {
            if(StringFind(sparam, "VTL_") >= 0 && StringFind(sparam, "_Entry") >= 0)
            {
               // Validate entry price after drag ends
               double currentPrice = ObjectGetDouble(0, sparam, OBJPROP_PRICE);
               double validatedPrice = m_visualLines.ValidateEntryPrice(currentPrice);
               
               // If price is out of bounds, correct it
               if(MathAbs(validatedPrice - currentPrice) > 0.000001)
               {
                  ObjectSetDouble(0, sparam, OBJPROP_PRICE, validatedPrice);
                  ChartRedraw(0);
               }
               
               // Update our internal state
               m_visualLines.HandleEntryLineDrag(sparam);
               return false; // Let other handlers process too
            }
         }
         
         // Handle chart zoom/pan - update shaded areas immediately
         if(id == CHARTEVENT_CHART_CHANGE)
         {
            if(m_visualLines != NULL && m_visualLines.IsActive())
            {
               // CRITICAL: Update shaded areas immediately when chart is zoomed/panned
               // This prevents lag when zooming with mouse wheel
               m_visualLines.RefreshShadedAreas();
               ChartRedraw();
            }
         }
      }
      
      // Handle panel button clicks
      if(id == CHARTEVENT_OBJECT_CLICK)
      {
         if(sparam == m_btnBuyName + "_Large")
         {
            CreateBuyVisualSetup();
            return true;
         }
         else if(sparam == m_btnSellName + "_Large")
         {
            CreateSellVisualSetup();
            return true;
         }
      }
      else if(id == CHARTEVENT_OBJECT_ENDEDIT)
      {
         if(sparam == m_editVolumeName)
         {
            string text = ObjectGetString(0, m_editVolumeName, OBJPROP_TEXT);
            m_volume = StringToDouble(text);
            UpdateValues();
            return true;
         }
         else if(sparam == m_editSLName)
         {
            string text = ObjectGetString(0, m_editSLName, OBJPROP_TEXT);
            m_stopLoss = (int)StringToInteger(text);
            UpdateVisualLinesFromInputs();
            UpdateValues();
            return true;
         }
         else if(sparam == m_editTPName)
         {
            string text = ObjectGetString(0, m_editTPName, OBJPROP_TEXT);
            m_takeProfit = (int)StringToInteger(text);
            UpdateVisualLinesFromInputs();
            UpdateValues();
            return true;
         }
         else if(sparam == m_editRiskName)
         {
            string text = ObjectGetString(0, m_editRiskName, OBJPROP_TEXT);
            text = StringSubstr(text, 0, StringFind(text, "%"));
            m_riskPercent = StringToDouble(text);
            UpdateValues();
            return true;
         }
      }
      
      return false;
   }
   
   //+------------------------------------------------------------------+
   //| Create buy visual setup                                         |
   //+------------------------------------------------------------------+
   void CreateBuyVisualSetup()
   {
      if(m_visualLines == NULL) return;
      
      double entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double tpPrice = 0;
      double slPrice = 0;
      
      // Calculate TP and SL from inputs
      if(m_takeProfit > 0)
         tpPrice = entryPrice + PointsToPrice(m_takeProfit);
      else
         tpPrice = NormalizePrice(entryPrice + 30.00);
      
      if(m_stopLoss > 0)
         slPrice = entryPrice - PointsToPrice(m_stopLoss);
      else
         slPrice = NormalizePrice(entryPrice - 10.00);
      
      if(m_visualLines.CreateBuySetup(entryPrice, tpPrice, slPrice))
      {
         UpdateInputsFromVisualLines();
         UpdateValues(); // This will update risk/profit labels
         if(m_logger != NULL)
            m_logger.Info("Buy visual setup created");
      }
   }
   
   //+------------------------------------------------------------------+
   //| Create sell visual setup                                        |
   //+------------------------------------------------------------------+
   void CreateSellVisualSetup()
   {
      if(m_visualLines == NULL) return;
      
      double entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double tpPrice = 0;
      double slPrice = 0;
      
      // Calculate TP and SL from inputs
      if(m_takeProfit > 0)
         tpPrice = entryPrice - PointsToPrice(m_takeProfit);
      else
         tpPrice = NormalizePrice(entryPrice - 30.00);
      
      if(m_stopLoss > 0)
         slPrice = entryPrice + PointsToPrice(m_stopLoss);
      else
         slPrice = NormalizePrice(entryPrice + 10.00);
      
      if(m_visualLines.CreateSellSetup(entryPrice, tpPrice, slPrice))
      {
         UpdateInputsFromVisualLines();
         UpdateValues(); // This will update risk/profit labels
         if(m_logger != NULL)
            m_logger.Info("Sell visual setup created");
      }
   }
   
   //+------------------------------------------------------------------+
   //| Execute trade from visual lines                                 |
   //+------------------------------------------------------------------+
   void ExecuteTradeFromVisualLines()
   {
      if(m_tradeManager == NULL || m_riskManager == NULL || m_visualLines == NULL)
      {
         if(m_logger != NULL)
            m_logger.Error("ExecuteTradeFromVisualLines: Missing managers or visual lines");
         return;
      }
      
      if(!m_visualLines.IsActive())
      {
         if(m_logger != NULL)
            m_logger.Warn("ExecuteTradeFromVisualLines: Visual lines not active");
         return;
      }
      
      double entryPrice = m_visualLines.GetEntryPrice();
      int tpPoints = m_visualLines.GetTPPoints();
      int slPoints = m_visualLines.GetSLPoints();
      bool isBuy = m_visualLines.IsBuy();
      
      if(entryPrice <= 0 || slPoints <= 0)
      {
         if(m_logger != NULL)
            m_logger.Error("ExecuteTradeFromVisualLines: Invalid entry price or SL points - Entry: " + DoubleToString(entryPrice, 5) + ", SL: " + IntegerToString(slPoints));
         return;
      }
      
      // Use manual lot size if set, otherwise calculate based on risk
      double lotSize = m_volume > 0 ? m_volume : m_riskManager.CalculateLotSize(slPoints);
      
      if(lotSize <= 0)
      {
         if(m_logger != NULL)
            m_logger.Error("ExecuteTradeFromVisualLines: Invalid lot size calculated: " + DoubleToString(lotSize, 2));
         return;
      }
      
      ENUM_ORDER_TYPE orderType = m_visualLines.GetOrderType();
      
      if(m_logger != NULL)
         m_logger.Info("Executing trade: " + (isBuy ? "BUY" : "SELL") + ", Lot: " + DoubleToString(lotSize, 2) + 
                      ", SL: " + IntegerToString(slPoints) + " pts, TP: " + IntegerToString(tpPoints) + " pts, OrderType: " + EnumToString(orderType));
      
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
         // Pending order
         if(orderType == ORDER_TYPE_BUY_LIMIT)
            success = m_tradeManager.OpenBuyLimit(entryPrice, lotSize, slPoints, tpPoints);
         else if(orderType == ORDER_TYPE_BUY_STOP)
            success = m_tradeManager.OpenBuyStop(entryPrice, lotSize, slPoints, tpPoints);
         else if(orderType == ORDER_TYPE_SELL_LIMIT)
            success = m_tradeManager.OpenSellLimit(entryPrice, lotSize, slPoints, tpPoints);
         else if(orderType == ORDER_TYPE_SELL_STOP)
            success = m_tradeManager.OpenSellStop(entryPrice, lotSize, slPoints, tpPoints);
      }
      
      if(success)
      {
         if(m_logger != NULL)
            m_logger.Info("Trade executed successfully from visual lines: " + (isBuy ? "BUY" : "SELL") + " " + DoubleToString(lotSize, 2) + " lots");
         
         // Clear visual lines after successful trade
         m_visualLines.DeleteAll();
      }
      else
      {
         if(m_logger != NULL)
            m_logger.Error("Trade execution failed from visual lines");
      }
   }
   
   //+------------------------------------------------------------------+
   //| Update visual lines from input values                           |
   //+------------------------------------------------------------------+
   void UpdateVisualLinesFromInputs()
   {
      if(m_visualLines == NULL || !m_visualLines.IsActive()) return;
      
      double entryPrice = m_visualLines.GetEntryPrice();
      if(entryPrice <= 0) return;
      
      bool isBuy = m_visualLines.IsBuy();
      double tpPrice = 0;
      double slPrice = 0;
      
      if(m_takeProfit > 0)
         tpPrice = isBuy ? entryPrice + PointsToPrice(m_takeProfit) : entryPrice - PointsToPrice(m_takeProfit);
      
      if(m_stopLoss > 0)
         slPrice = isBuy ? entryPrice - PointsToPrice(m_stopLoss) : entryPrice + PointsToPrice(m_stopLoss);
      
      if(tpPrice > 0)
         m_visualLines.UpdateTPPrice(tpPrice);
      
      if(slPrice > 0)
         m_visualLines.UpdateSLPrice(slPrice);
      
      m_visualLines.Update();
      
      // CRITICAL: Update shaded areas after line prices change
      // Note: UpdateTPPrice and UpdateSLPrice already call UpdateShadedAreas internally,
      // but we call RefreshShadedAreas here to ensure it's updated after Update() runs
      m_visualLines.RefreshShadedAreas();
      
      UpdateVisualLinesLabels(); // Update risk/profit labels after price changes
   }
   
   //+------------------------------------------------------------------+
   //| Update input values from visual lines                           |
   //+------------------------------------------------------------------+
   void UpdateInputsFromVisualLines()
   {
      if(m_visualLines == NULL || !m_visualLines.IsActive()) return;
      
      int tpPoints = m_visualLines.GetTPPoints();
      int slPoints = m_visualLines.GetSLPoints();
      
      if(tpPoints > 0)
      {
         m_takeProfit = tpPoints;
         ObjectSetString(0, m_editTPName, OBJPROP_TEXT, IntegerToString(m_takeProfit));
      }
      
      if(slPoints > 0)
      {
         m_stopLoss = slPoints;
         ObjectSetString(0, m_editSLName, OBJPROP_TEXT, IntegerToString(m_stopLoss));
      }
   }
   
   //+------------------------------------------------------------------+
   //| Update displayed values                                         |
   //+------------------------------------------------------------------+
   void UpdateValues()
   {
      if(!m_enableUI) return;
      
      // Update button labels with risk amount
      double riskAmount = CalculateRiskAmount();
      ObjectSetString(0, m_labelBuyValueName, OBJPROP_TEXT, "Risk: $" + DoubleToString(riskAmount, 2));
      ObjectSetString(0, m_labelSellValueName, OBJPROP_TEXT, "Risk: $" + DoubleToString(riskAmount, 2));
      
      // Update visual lines labels with risk/profit
      UpdateVisualLinesLabels();
      
      ChartRedraw();
   }
   
   //+------------------------------------------------------------------+
   //| Update visual lines labels with risk and profit                |
   //+------------------------------------------------------------------+
   void UpdateVisualLinesLabels()
   {
      if(m_visualLines == NULL || !m_visualLines.IsActive()) return;
      if(m_riskManager == NULL) return;
      
      int slPoints = m_visualLines.GetSLPoints();
      int tpPoints = m_visualLines.GetTPPoints();
      
      if(slPoints > 0)
      {
         // Use manual lot size if set, otherwise calculate based on risk percentage
         double lotSize = m_volume > 0 ? m_volume : m_riskManager.CalculateLotSize(slPoints);
         double riskAmount = ::CalculateRiskAmount(lotSize, slPoints);
         
         // Update SL line label to show risk
         m_visualLines.UpdateSLLabelRisk(riskAmount);
      }
      
      if(tpPoints > 0 && slPoints > 0)
      {
         // Use manual lot size if set, otherwise calculate based on risk percentage
         double lotSize = m_volume > 0 ? m_volume : m_riskManager.CalculateLotSize(slPoints);
         double profitAmount = ::CalculateProfitAmount(lotSize, tpPoints);
         
         // Update TP line label to show profit
         m_visualLines.UpdateTPLabelProfit(profitAmount);
      }
      
      // Update entry line label to show lot size (formatted like image: "Lot 0.01")
      // Note: "Buy"/"Sell" is in the tag, price is in the white input box, so info shows: "Lot 0.01"
      if(m_visualLines.IsActive())
      {
         double lotSize = m_volume > 0 ? m_volume : (slPoints > 0 ? m_riskManager.CalculateLotSize(slPoints) : InpLotSize);
         string entryLabel = "Lot " + DoubleToString(lotSize, 2);
         m_visualLines.UpdateEntryLabel(entryLabel);
      }
   }
   
   //+------------------------------------------------------------------+
   //| Update panel                                                    |
   //+------------------------------------------------------------------+
   void Update() override
   {
      if(!m_enableUI) return;
      
      // Update visual lines
      if(m_visualLines != NULL && m_visualLines.IsActive())
      {
         m_visualLines.Update();
      }
      
      UpdateValues();
   }
   
   //+------------------------------------------------------------------+
   //| Delete all objects                                             |
   //+------------------------------------------------------------------+
   void DeleteAll() override
   {
      if(!m_enableUI) return;
      
      // Delete visual lines first
      if(m_visualLines != NULL)
         m_visualLines.DeleteAll();
      
      // Delete all panel objects with this panel name
      ObjectsDeleteAll(0, m_panelName);
      
      // CRITICAL: Also delete any objects that might have this panel's prefix
      // This ensures cleanup even if object names changed
      int total = ObjectsTotal(0);
      for(int i = total - 1; i >= 0; i--)
      {
         string name = ObjectName(0, i);
         // Delete objects with this panel name prefix
         if(StringFind(name, m_panelName) == 0)
            ObjectDelete(0, name);
         // Delete VTL_ objects
         else if(StringFind(name, "VTL_") == 0)
            ObjectDelete(0, name);
      }
      
      ChartRedraw();
   }
   
   //+------------------------------------------------------------------+
   //| Destructor                                                      |
   //+------------------------------------------------------------------+
   ~CTradePanel()
   {
      if(m_visualLines != NULL)
      {
         delete m_visualLines;
         m_visualLines = NULL;
      }
   }
};

//+------------------------------------------------------------------+
