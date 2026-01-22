//+------------------------------------------------------------------+
//| ReviewPanel.mqh                                                  |
//| Review Tab Panel - Trade history visualization                  |
//+------------------------------------------------------------------+
#property copyright "Azzuro"
#property link      "https://www.mql5.com"
#property version   "1.01"
#property strict

#include "../Panel.mqh"
#include "../Controls.mqh"
#include "../../Core/Logger.mqh"
#include "../../Core/SymbolUtils.mqh"
#include "../../Core/MathRisk.mqh"
#include "../../Utils/Helpers.mqh"
#include <Canvas\Canvas.mqh>

//+------------------------------------------------------------------+
//| Trade data structure                                             |
//+------------------------------------------------------------------+
struct STradeData
{
   ulong           ticket;              // position id
   string          symbol;
   datetime        openTime;
   datetime        closeTime;
   double          openPrice;
   double          closePrice;
   double          slPrice;
   double          tpPrice;
   double          volume;
   double          profit;
   ENUM_DEAL_TYPE  dealType;            // BUY/SELL (direction)
   int             durationMinutes;
   double          efficiencyPercent;
   double          mfe;                 // Maximum Favorable Excursion (simplified)
   double          mae;                 // Maximum Adverse Excursion (simplified)
};

//+------------------------------------------------------------------+
//| Review Panel class                                               |
//+------------------------------------------------------------------+
class CReviewPanel : public CPanel
{
private:
   CLogger*        m_logger;
   int             m_magicNumber;

   // Trade history
   STradeData      m_trades[];
   int             m_totalTrades;
   int             m_currentTradeIndex;

   // Prevent re-render loop caused by ChartNavigate() firing CHART_CHANGE
   bool            m_ignoreNextChartChange;

   // Canvas objects for shaded areas
   CCanvas*        m_canvasSL;
   CCanvas*        m_canvasTP;
   CCanvas*        m_canvasExit;

   // Shaded area object names
   string          m_shadeSLName;
   string          m_shadeTPName;
   string          m_shadeExitName;

   // Arrow object names
   string          m_arrowEntryName;
   string          m_arrowExitName;

   // Stat box UI element names
   string          m_statBoxName;
   string          m_statEfficiencyName;
   string          m_statHoldingTimeName;
   string          m_statExitQualityName;
   string          m_statRemainingRiskName;
   string          m_statExpectedGainName;
   string          m_statPnLName;
   string          m_statTicketName;

   // Control names
   string          m_btnPreviousName;
   string          m_btnNextName;
   string          m_labelTradeCountName;

   //+------------------------------------------------------------------+
   //| Create transparent shaded area using CCanvas                    |
   //+------------------------------------------------------------------+
   void CreateShadedArea(CCanvas* &canvas,
                         const string name,
                         const datetime timeStart,
                         const datetime timeEnd,
                         const double priceLow,
                         const double priceHigh,
                         const int red,
                         const int green,
                         const int blue,
                         const int alpha)
   {
      // Delete existing object if any
      if(ObjectFind(0, name) >= 0)
         ObjectDelete(0, name);
      
      if(canvas != NULL)
      {
         delete canvas;
         canvas = NULL;
      }

      int x1, y1, x2, y2;
      bool gotCoords1 = ChartTimePriceToXY(0, 0, timeStart, priceLow, x1, y1);
      bool gotCoords2 = ChartTimePriceToXY(0, 0, timeEnd, priceHigh, x2, y2);
      
      // If coordinates not available (times not visible), try using current visible area
      if(!gotCoords1 || !gotCoords2)
      {
         // Get first visible bar time and calculate last visible bar time
         datetime firstBar = (datetime)ChartGetInteger(0, CHART_FIRST_VISIBLE_BAR);
         int visibleBars = (int)ChartGetInteger(0, CHART_VISIBLE_BARS);
         ENUM_TIMEFRAMES period = Period();
         int periodSeconds = PeriodSeconds(period);
         datetime lastBar = firstBar + (visibleBars * periodSeconds);
         
         // Calculate approximate times if not visible
         if(!gotCoords1)
         {
            // Use first visible bar or trade start time, whichever is earlier
            datetime useTime = (timeStart < firstBar) ? firstBar : timeStart;
            ChartTimePriceToXY(0, 0, useTime, priceLow, x1, y1);
         }
         if(!gotCoords2)
         {
            // Use last visible bar or trade end time
            datetime useTime = (timeEnd > lastBar) ? lastBar : timeEnd;
            ChartTimePriceToXY(0, 0, useTime, priceHigh, x2, y2);
         }
      }

      // Ensure correct order
      if(x1 > x2) { int tmp = x1; x1 = x2; x2 = tmp; }
      if(y1 > y2) { int tmp = y1; y1 = y2; y2 = tmp; }

      int width  = x2 - x1;
      int height = y2 - y1;

      // Ensure minimum size
      if(width < 2) width = 2;
      if(height < 2) height = 2;
      
      // Clamp to chart bounds
      int chartWidth = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
      int chartHeight = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);
      if(x1 < 0) x1 = 0;
      if(y1 < 0) y1 = 0;
      if(x2 > chartWidth) { x2 = chartWidth; width = x2 - x1; }
      if(y2 > chartHeight) { y2 = chartHeight; height = y2 - y1; }
      
      if(width <= 0 || height <= 0) return;

      // Create canvas
      canvas = new CCanvas();

      // Create bitmap label with ARGB format for transparency
      if(!canvas.CreateBitmapLabel(name, x1, y1, width, height, COLOR_FORMAT_ARGB_NORMALIZE))
      {
         delete canvas;
         canvas = NULL;
         return;
      }

      // Make sure it is visible (not forced behind chart background)
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
      ObjectSetInteger(0, name, OBJPROP_ZORDER, 1);

      uint transparentColor = ColorToARGB((color)((red << 16) | (green << 8) | blue), (uchar)alpha);
      canvas.Erase(transparentColor);
      canvas.Update();
   }

   //+------------------------------------------------------------------+
   //| Calculate exit quality (0-100%)                                 |
   //+------------------------------------------------------------------+
   double CalculateExitQuality(const STradeData &trade)
   {
      double pointValue = GetPointValue(trade.symbol);

      double entryToTP = MathAbs(trade.tpPrice - trade.openPrice) / pointValue;
      if(entryToTP <= 0.0) return 50.0;

      double tpDistance = MathAbs(trade.closePrice - trade.tpPrice) / pointValue;
      double quality = 100.0 * (1.0 - (tpDistance / entryToTP));

      if(quality < 0.0)   quality = 0.0;
      if(quality > 100.0) quality = 100.0;
      return quality;
   }

   //+------------------------------------------------------------------+
   //| Calculate remaining risk ($)                                     |
   //+------------------------------------------------------------------+
   double CalculateRemainingRisk(const STradeData &trade)
   {
      double pointValue = GetPointValue(trade.symbol);
      double slPoints = MathAbs(trade.slPrice - trade.openPrice) / pointValue;
      if(slPoints <= 0.0) return 0.0;

      double exitToSL = MathAbs(trade.closePrice - trade.slPrice) / pointValue;
      double remainingRiskPercent = (exitToSL / slPoints) * 100.0;

      double originalRisk = CalculateRiskAmount(trade.volume, (int)slPoints, trade.symbol);
      return originalRisk * (remainingRiskPercent / 100.0);
   }

   //+------------------------------------------------------------------+
   //| Calculate expected gain ($)                                      |
   //+------------------------------------------------------------------+
   double CalculateExpectedGain(const STradeData &trade)
   {
      double pointValue = GetPointValue(trade.symbol);
      double tpPoints = MathAbs(trade.tpPrice - trade.openPrice) / pointValue;
      if(tpPoints <= 0.0) return 0.0;
      return CalculateProfitAmount(trade.volume, (int)tpPoints, trade.symbol);
   }

public:
   CReviewPanel(int magic, CLogger* logger)
      : CPanel("ReviewPanel_" + IntegerToString(GetTickCount()), 0, 0, PANEL_WIDTH, PANEL_HEIGHT - HEADER_HEIGHT - TAB_HEIGHT)
   {
      m_logger = logger;
      m_magicNumber = magic;
      m_totalTrades = 0;
      m_currentTradeIndex = -1;
      m_ignoreNextChartChange = false;

      ArrayResize(m_trades, 0);

      m_canvasSL = NULL;
      m_canvasTP = NULL;
      m_canvasExit = NULL;

      m_shadeSLName   = m_panelName + "_ShadeSL";
      m_shadeTPName   = m_panelName + "_ShadeTP";
      m_shadeExitName = m_panelName + "_ShadeExit";
      m_arrowEntryName = m_panelName + "_ArrowEntry";
      m_arrowExitName  = m_panelName + "_ArrowExit";

      m_statBoxName          = m_panelName + "_StatBox";
      m_statEfficiencyName   = m_panelName + "_StatEfficiency";
      m_statHoldingTimeName  = m_panelName + "_StatHoldingTime";
      m_statExitQualityName  = m_panelName + "_StatExitQuality";
      m_statRemainingRiskName= m_panelName + "_StatRemainingRisk";
      m_statExpectedGainName = m_panelName + "_StatExpectedGain";
      m_statPnLName          = m_panelName + "_StatPnL";
      m_statTicketName       = m_panelName + "_StatTicket";

      m_btnPreviousName      = m_panelName + "_BtnPrevious";
      m_btnNextName          = m_panelName + "_BtnNext";
      m_labelTradeCountName  = m_panelName + "_LabelTradeCount";
   }

   ~CReviewPanel()
   {
      if(m_canvasSL != NULL)   { delete m_canvasSL;   m_canvasSL = NULL; }
      if(m_canvasTP != NULL)   { delete m_canvasTP;   m_canvasTP = NULL; }
      if(m_canvasExit != NULL) { delete m_canvasExit; m_canvasExit = NULL; }
   }

   //+------------------------------------------------------------------+
   //| Create panel                                                    |
   //+------------------------------------------------------------------+
   bool Create() override
   {
      if(!m_enableUI || !m_visible) return true;

      LoadTradeHistory();

      int startY = m_y + 20;

      if(!CreateUIButton(m_btnPreviousName, m_x + 20, startY, 100, 30, "Previous", COLOR_BG_PANEL))
         return false;

      if(!CreateUILabel(m_labelTradeCountName, m_x + 140, startY + 5, "0 of 0", COLOR_TEXT_PRIMARY))
         return false;

      if(!CreateUIButton(m_btnNextName, m_x + 220, startY, 100, 30, "Next", COLOR_BG_PANEL))
         return false;

      startY += 50;

      if(!CreateUIRectangle(m_statBoxName, m_x + 20, startY, PANEL_WIDTH - 40, 200, COLOR_BG_PANEL))
         return false;

      startY += 15;

      if(!CreateUILabel(m_statTicketName, m_x + 30, startY, "Ticket: -", COLOR_TEXT_PRIMARY))
         return false;
      startY += 25;

      if(!CreateUILabel(m_panelName + "_LabelEfficiency", m_x + 30, startY, "Trade Efficiency:", COLOR_TEXT_SECONDARY))
         return false;
      if(!CreateUILabel(m_statEfficiencyName, m_x + 150, startY, "0.0%", COLOR_TEXT_PRIMARY))
         return false;
      startY += 25;

      if(!CreateUILabel(m_panelName + "_LabelHoldingTime", m_x + 30, startY, "Holding Time:", COLOR_TEXT_SECONDARY))
         return false;
      if(!CreateUILabel(m_statHoldingTimeName, m_x + 150, startY, "0 min", COLOR_TEXT_PRIMARY))
         return false;
      startY += 25;

      if(!CreateUILabel(m_panelName + "_LabelExitQuality", m_x + 30, startY, "Exit Quality:", COLOR_TEXT_SECONDARY))
         return false;
      if(!CreateUILabel(m_statExitQualityName, m_x + 150, startY, "0.0%", COLOR_TEXT_PRIMARY))
         return false;
      startY += 25;

      if(!CreateUILabel(m_panelName + "_LabelRemainingRisk", m_x + 30, startY, "Remaining Risk:", COLOR_TEXT_SECONDARY))
         return false;
      if(!CreateUILabel(m_statRemainingRiskName, m_x + 150, startY, "$0.00", COLOR_ACCENT_RED))
         return false;
      startY += 25;

      if(!CreateUILabel(m_panelName + "_LabelExpectedGain", m_x + 30, startY, "Expected Gain:", COLOR_TEXT_SECONDARY))
         return false;
      if(!CreateUILabel(m_statExpectedGainName, m_x + 150, startY, "$0.00", COLOR_ACCENT_GREEN))
         return false;
      startY += 25;

      if(!CreateUILabel(m_panelName + "_LabelPnL", m_x + 30, startY, "PnL:", COLOR_TEXT_SECONDARY))
         return false;
      if(!CreateUILabel(m_statPnLName, m_x + 150, startY, "$0.00", COLOR_TEXT_PRIMARY))
         return false;

      if(m_totalTrades > 0)
      {
         m_currentTradeIndex = 0;
         DisplayTrade(m_currentTradeIndex, false);
      }

      ChartRedraw(0);
      return true;
   }

   //+------------------------------------------------------------------+
   //| Load trade history                                              |
   //| FIXES:
   //|  - Only uses HistorySelect(from,to) once (no HistorySelectByPosition inside loop)
   //|  - Only counts closing deals (DEAL_ENTRY_OUT)
   //|  - Stable open deal lookup
   //+------------------------------------------------------------------+
   void LoadTradeHistory()
   {
      if(!m_enableUI) return;

      ArrayResize(m_trades, 0);
      m_totalTrades = 0;

      datetime fromDate = 0;
      datetime toDate   = TimeCurrent();

      if(!HistorySelect(fromDate, toDate))
      {
         if(m_logger != NULL)
            m_logger.Error("Failed to select history");
         return;
      }

      int totalDeals = HistoryDealsTotal();
      if(totalDeals <= 0)
         return;

      // Pre-allocate (max), then shrink
      ArrayResize(m_trades, totalDeals);

      for(int i = 0; i < totalDeals; i++)
      {
         ulong dealTicket = HistoryDealGetTicket(i);
         if(dealTicket == 0) continue;

         long magic = HistoryDealGetInteger(dealTicket, DEAL_MAGIC);
         if(magic != (long)m_magicNumber)
            continue;

         ENUM_DEAL_TYPE dealType = (ENUM_DEAL_TYPE)HistoryDealGetInteger(dealTicket, DEAL_TYPE);
         if(dealType != DEAL_TYPE_BUY && dealType != DEAL_TYPE_SELL)
            continue;

         // Only closing deals (otherwise open/close can collapse)
         ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
         if(entry != DEAL_ENTRY_OUT)
            continue;

         ulong posId = (ulong)HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
         if(posId == 0) continue;

         STradeData trade = {};
         trade.ticket     = posId;
         trade.symbol     = HistoryDealGetString(dealTicket, DEAL_SYMBOL);
         trade.closeTime  = (datetime)HistoryDealGetInteger(dealTicket, DEAL_TIME);
         trade.closePrice = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
         trade.volume     = HistoryDealGetDouble(dealTicket, DEAL_VOLUME);
         trade.profit     = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
         trade.dealType   = dealType;

         // Find opening deal for this position (DEAL_ENTRY_IN)
         trade.openTime  = 0;
         trade.openPrice = 0.0;

         // First, search for opening deal in current selection
         for(int j = 0; j < totalDeals; j++)
         {
            ulong openDealTicket = HistoryDealGetTicket(j);
            if(openDealTicket == 0) continue;

            if((ulong)HistoryDealGetInteger(openDealTicket, DEAL_POSITION_ID) != posId)
               continue;

            ENUM_DEAL_ENTRY e = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(openDealTicket, DEAL_ENTRY);
            if(e == DEAL_ENTRY_IN)
            {
               trade.openTime  = (datetime)HistoryDealGetInteger(openDealTicket, DEAL_TIME);
               trade.openPrice = HistoryDealGetDouble(openDealTicket, DEAL_PRICE);
               break;
            }
         }
         
         // If not found, try using HistorySelectByPosition (more reliable but changes selection)
         if(trade.openTime == 0)
         {
            // Temporarily select by position
            if(HistorySelectByPosition(posId))
            {
               int posDeals = HistoryDealsTotal();
               for(int j = 0; j < posDeals; j++)
               {
                  ulong openDealTicket = HistoryDealGetTicket(j);
                  if(openDealTicket == 0) continue;
                  
                  ENUM_DEAL_ENTRY e = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(openDealTicket, DEAL_ENTRY);
                  if(e == DEAL_ENTRY_IN)
                  {
                     trade.openTime  = (datetime)HistoryDealGetInteger(openDealTicket, DEAL_TIME);
                     trade.openPrice = HistoryDealGetDouble(openDealTicket, DEAL_PRICE);
                     break;
                  }
               }
            }
            // Restore original selection
            HistorySelect(fromDate, toDate);
         }

         // Duration
         if(trade.openTime > 0)
            trade.durationMinutes = (int)((trade.closeTime - trade.openTime) / 60);
         else
            trade.durationMinutes = 0;

         // SL/TP estimate (for visualization)
         double pointValue = GetPointValue(trade.symbol);
         trade.slPrice = 0.0;
         trade.tpPrice = 0.0;

         if(trade.openPrice > 0.0 && pointValue > 0.0)
         {
            if(dealType == DEAL_TYPE_BUY)
            {
               trade.slPrice = trade.openPrice - (50 * pointValue);
               trade.tpPrice = trade.openPrice + (100 * pointValue);
            }
            else
            {
               trade.slPrice = trade.openPrice + (50 * pointValue);
               trade.tpPrice = trade.openPrice - (100 * pointValue);
            }
         }

         // Efficiency
         double priceRange = MathAbs(trade.closePrice - trade.openPrice);
         double tpRange    = MathAbs(trade.tpPrice - trade.openPrice);
         trade.efficiencyPercent = (tpRange > 0.0 ? (priceRange / tpRange) * 100.0 : 0.0);

         // Simplified MFE/MAE
         trade.mfe = (pointValue > 0.0 ? priceRange / pointValue : 0.0);
         trade.mae = (pointValue > 0.0 ? MathAbs(trade.slPrice - trade.openPrice) / pointValue : 0.0);

         m_trades[m_totalTrades] = trade;
         m_totalTrades++;
      }

      ArrayResize(m_trades, m_totalTrades);

      // Sort by close time (newest first)
      for(int a = 0; a < m_totalTrades - 1; a++)
      {
         for(int b = 0; b < m_totalTrades - a - 1; b++)
         {
            if(m_trades[b].closeTime < m_trades[b + 1].closeTime)
            {
               STradeData tmp = m_trades[b];
               m_trades[b] = m_trades[b + 1];
               m_trades[b + 1] = tmp;
            }
         }
      }

      if(m_logger != NULL)
      {
         m_logger.Info("Loaded " + IntegerToString(m_totalTrades) + " trades from history");
         
         // Log details of first few trades for debugging
         int logCount = MathMin(10, m_totalTrades);
         for(int i = 0; i < logCount; i++)
         {
            m_logger.Info("Trade " + IntegerToString(i) + ": ticket=" + IntegerToString(m_trades[i].ticket) + 
                         ", openTime=" + (m_trades[i].openTime > 0 ? TimeToString(m_trades[i].openTime) : "INVALID") + 
                         ", closeTime=" + TimeToString(m_trades[i].closeTime) + 
                         ", duration=" + IntegerToString(m_trades[i].durationMinutes) + " min");
         }
      }
      
      // #region agent log
      WriteDebugLog("ReviewPanel.mqh:452", "Trade history loaded", "{\"totalTrades\":" + IntegerToString(m_totalTrades) + "}");
      // #endregion agent log
   }

   //+------------------------------------------------------------------+
   //| Display trade on chart                                          |
   //+------------------------------------------------------------------+
   void DisplayTrade(int index, bool navigateChart = false)
   {
      if(!m_enableUI) return;
      if(index < 0 || index >= m_totalTrades) return;

      ClearTradeDisplay();

      STradeData trade = m_trades[index];
      bool isWin = (trade.profit >= 0.0);
      bool isBuy = (trade.dealType == DEAL_TYPE_BUY);

      int shadeRed, shadeGreen, shadeBlue;
      int shadeAlpha = 120;

      if(isWin) { shadeRed = 0; shadeGreen = 180; shadeBlue = 0; }
      else      { shadeRed = 255; shadeGreen = 0; shadeBlue = 0; }

      // Need valid open/close times & prices for proper shading
      if(trade.openTime > 0 && trade.closeTime > 0 && trade.openPrice > 0.0 && trade.closePrice > 0.0)
      {
         // Entry->SL
         if(trade.slPrice > 0.0)
         {
            double slLow  = MathMin(trade.openPrice, trade.slPrice);
            double slHigh = MathMax(trade.openPrice, trade.slPrice);
            CreateShadedArea(m_canvasSL, m_shadeSLName, trade.openTime, trade.closeTime, slLow, slHigh,
                             shadeRed, shadeGreen, shadeBlue, shadeAlpha);
         }

         // Entry->TP
         if(trade.tpPrice > 0.0)
         {
            double tpLow  = MathMin(trade.openPrice, trade.tpPrice);
            double tpHigh = MathMax(trade.openPrice, trade.tpPrice);
            CreateShadedArea(m_canvasTP, m_shadeTPName, trade.openTime, trade.closeTime, tpLow, tpHigh,
                             shadeRed, shadeGreen, shadeBlue, shadeAlpha);
         }

         // Entry->Exit
         double exitLow  = MathMin(trade.openPrice, trade.closePrice);
         double exitHigh = MathMax(trade.openPrice, trade.closePrice);
         CreateShadedArea(m_canvasExit, m_shadeExitName, trade.openTime, trade.closeTime, exitLow, exitHigh,
                          shadeRed, shadeGreen, shadeBlue, shadeAlpha);
      }

      // Entry arrow
      if(ObjectFind(0, m_arrowEntryName) < 0)
         ObjectCreate(0, m_arrowEntryName, OBJ_ARROW, 0, trade.openTime, trade.openPrice);
      else
      {
         ObjectSetInteger(0, m_arrowEntryName, OBJPROP_TIME, trade.openTime);
         ObjectSetDouble(0, m_arrowEntryName, OBJPROP_PRICE, trade.openPrice);
      }
      ObjectSetInteger(0, m_arrowEntryName, OBJPROP_ARROWCODE, isBuy ? 233 : 234);
      ObjectSetInteger(0, m_arrowEntryName, OBJPROP_COLOR, isBuy ? COLOR_ACCENT_GREEN : COLOR_ACCENT_RED);
      ObjectSetInteger(0, m_arrowEntryName, OBJPROP_WIDTH, 3);

      // Exit arrow
      if(ObjectFind(0, m_arrowExitName) < 0)
         ObjectCreate(0, m_arrowExitName, OBJ_ARROW, 0, trade.closeTime, trade.closePrice);
      else
      {
         ObjectSetInteger(0, m_arrowExitName, OBJPROP_TIME, trade.closeTime);
         ObjectSetDouble(0, m_arrowExitName, OBJPROP_PRICE, trade.closePrice);
      }
      ObjectSetInteger(0, m_arrowExitName, OBJPROP_ARROWCODE, isWin ? 233 : 234);
      ObjectSetInteger(0, m_arrowExitName, OBJPROP_COLOR, isWin ? COLOR_ACCENT_GREEN : COLOR_ACCENT_RED);
      ObjectSetInteger(0, m_arrowExitName, OBJPROP_WIDTH, 3);

      UpdateStatBox(trade);

      ObjectSetString(0, m_labelTradeCountName, OBJPROP_TEXT,
                      IntegerToString(index + 1) + " of " + IntegerToString(m_totalTrades));

      if(navigateChart)
         NavigateChartToTrade(trade);

      ChartRedraw(0);
   }

   //+------------------------------------------------------------------+
   //| Navigate chart to show trade location ONCE per click            |
   //| - turns off autoscroll so user can drag freely after navigation |
   //| - ignores the next CHART_CHANGE fired by ChartNavigate()        |
   //+------------------------------------------------------------------+
   void NavigateChartToTrade(const STradeData &trade)
   {
      if(!m_enableUI) return;
      if(trade.openTime <= 0) return;

      // IMPORTANT: don't fight the user after navigation
      // Use explicit (long) casts to match ChartSetInteger signature
      ChartSetInteger(0, CHART_AUTOSCROLL, (long)false);
      ChartSetInteger(0, CHART_SHIFT,      (long)true);
      // Ensure user interactions stay enabled
      ChartSetInteger(0, CHART_MOUSE_SCROLL,     (long)true);
      ChartSetInteger(0, CHART_KEYBOARD_CONTROL, (long)true);

      ENUM_TIMEFRAMES period = Period();
      int periodSeconds = PeriodSeconds(period);
      if(periodSeconds <= 0) return;

      datetime currentTime = TimeCurrent();
      long barsFromCurrent = (long)((currentTime - trade.openTime) / periodSeconds);

      if(barsFromCurrent > 0)
      {
         m_ignoreNextChartChange = true;
         ChartNavigate(0, CHART_END, -(int)barsFromCurrent);
      }

      ChartRedraw(0);
   }

   //+------------------------------------------------------------------+
   //| Update stat box with individual trade stats                     |
   //+------------------------------------------------------------------+
   void UpdateStatBox(const STradeData &trade)
   {
      if(!m_enableUI) return;

      double exitQuality   = CalculateExitQuality(trade);
      double remainingRisk = CalculateRemainingRisk(trade);
      double expectedGain  = CalculateExpectedGain(trade);

      string holdingTime;
      if(trade.durationMinutes < 60)
         holdingTime = IntegerToString(trade.durationMinutes) + " min";
      else if(trade.durationMinutes < 1440)
         holdingTime = IntegerToString(trade.durationMinutes / 60) + " hr " + IntegerToString(trade.durationMinutes % 60) + " min";
      else
         holdingTime = IntegerToString(trade.durationMinutes / 1440) + " day " + IntegerToString((trade.durationMinutes % 1440) / 60) + " hr";

      ObjectSetString(0, m_statTicketName, OBJPROP_TEXT, "Ticket: " + IntegerToString((int)trade.ticket));
      ObjectSetString(0, m_statEfficiencyName, OBJPROP_TEXT, DoubleToString(trade.efficiencyPercent, 1) + "%");
      ObjectSetString(0, m_statHoldingTimeName, OBJPROP_TEXT, holdingTime);
      ObjectSetString(0, m_statExitQualityName, OBJPROP_TEXT, DoubleToString(exitQuality, 1) + "%");
      ObjectSetString(0, m_statRemainingRiskName, OBJPROP_TEXT, "$" + DoubleToString(remainingRisk, 2));
      ObjectSetString(0, m_statExpectedGainName, OBJPROP_TEXT, "$" + DoubleToString(expectedGain, 2));

      color pnlColor = (trade.profit >= 0.0 ? COLOR_ACCENT_GREEN : COLOR_ACCENT_RED);
      ObjectSetString(0, m_statPnLName, OBJPROP_TEXT, "$" + DoubleToString(trade.profit, 2));
      ObjectSetInteger(0, m_statPnLName, OBJPROP_COLOR, pnlColor);
   }

   //+------------------------------------------------------------------+
   //| Clear trade display                                             |
   //+------------------------------------------------------------------+
   void ClearTradeDisplay()
   {
      if(!m_enableUI) return;

      if(m_canvasSL != NULL)
      {
         if(ObjectFind(0, m_shadeSLName) >= 0) ObjectDelete(0, m_shadeSLName);
         delete m_canvasSL;
         m_canvasSL = NULL;
      }
      if(m_canvasTP != NULL)
      {
         if(ObjectFind(0, m_shadeTPName) >= 0) ObjectDelete(0, m_shadeTPName);
         delete m_canvasTP;
         m_canvasTP = NULL;
      }
      if(m_canvasExit != NULL)
      {
         if(ObjectFind(0, m_shadeExitName) >= 0) ObjectDelete(0, m_shadeExitName);
         delete m_canvasExit;
         m_canvasExit = NULL;
      }

      if(ObjectFind(0, m_arrowEntryName) >= 0) ObjectDelete(0, m_arrowEntryName);
      if(ObjectFind(0, m_arrowExitName)  >= 0) ObjectDelete(0, m_arrowExitName);
   }

   //+------------------------------------------------------------------+
   //| Handle chart event                                              |
   //+------------------------------------------------------------------+
   bool OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam) override
   {
      if(!m_enableUI) return false;

      if(id == CHARTEVENT_OBJECT_CLICK)
      {
         if(m_totalTrades <= 0) return true;

         // Previous (older) - wrap
         if(sparam == m_btnPreviousName || StringFind(sparam, "_BtnPrevious") >= 0)
         {
            // #region agent log
            WriteDebugLog("ReviewPanel.mqh:647", "Previous button clicked", "{\"currentIndex\":" + IntegerToString(m_currentTradeIndex) + ",\"totalTrades\":" + IntegerToString(m_totalTrades) + "}");
            // #endregion agent log
            
            m_currentTradeIndex++;
            if(m_currentTradeIndex >= m_totalTrades)
               m_currentTradeIndex = 0;

            // Display trade immediately (will navigate if needed)
            DisplayTrade(m_currentTradeIndex, true);
            ObjectSetInteger(0, m_btnPreviousName, OBJPROP_STATE, false);
            ChartRedraw(0);
            return true;
         }

         // Next (newer) - wrap
         if(sparam == m_btnNextName || StringFind(sparam, "_BtnNext") >= 0)
         {
            // #region agent log
            WriteDebugLog("ReviewPanel.mqh:662", "Next button clicked", "{\"currentIndex\":" + IntegerToString(m_currentTradeIndex) + ",\"totalTrades\":" + IntegerToString(m_totalTrades) + "}");
            // #endregion agent log
            
            m_currentTradeIndex--;
            if(m_currentTradeIndex < 0)
               m_currentTradeIndex = m_totalTrades - 1;

            // Display trade immediately (will navigate if needed)
            DisplayTrade(m_currentTradeIndex, true);
            ObjectSetInteger(0, m_btnNextName, OBJPROP_STATE, false);
            ChartRedraw(0);
            return true;
         }
      }

      // Chart changed (zoom/pan OR our ChartNavigate). Always redraw current trade.
      if(id == CHARTEVENT_CHART_CHANGE)
      {
         if(m_currentTradeIndex >= 0 && m_currentTradeIndex < m_totalTrades)
         {
            if(m_ignoreNextChartChange)
               m_ignoreNextChartChange = false;

            DisplayTrade(m_currentTradeIndex, false);
         }
         return true;
      }

      return false;
   }

   void Update() override

   {
      if(!m_enableUI) return;
   }

   //+------------------------------------------------------------------+
   //| Delete all objects                                              |
   //+------------------------------------------------------------------+
   void DeleteAll() override
   {
      if(!m_enableUI) return;

      ClearTradeDisplay();

      ObjectsDeleteAll(0, m_panelName);

      int total = ObjectsTotal(0);
      for(int i = total - 1; i >= 0; i--)
      {
         string name = ObjectName(0, i);
         if(StringFind(name, m_panelName) == 0)
            ObjectDelete(0, name);
      }

      ChartRedraw(0);
   }
};
//+------------------------------------------------------------------+
