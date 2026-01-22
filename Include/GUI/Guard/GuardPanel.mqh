//+------------------------------------------------------------------+
//| GuardPanel.mqh                                                   |
//| Guard Tab Panel - Loss limits and guard settings                |
//+------------------------------------------------------------------+
#property copyright "Azzuro"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Panel.mqh"
#include "../Controls.mqh"
#include "../../Engine/DDGuard.mqh"
#include "../../Engine/RiskManager.mqh"
#include "../../Core/Logger.mqh"

//+------------------------------------------------------------------+
//| Guard Panel class                                                |
//+------------------------------------------------------------------+
class CGuardPanel : public CPanel
{
private:
   CDDGuard*       m_ddGuard;
   CRiskManager*   m_riskManager;
   CLogger*        m_logger;
   
   // Settings
   double          m_dailyLossLimit;
   double          m_weeklyLossLimit;
   bool            m_guardModeActive;
   bool            m_notificationsEnabled;
   
   // Control names
   string          m_labelDailyLossName;
   string          m_labelWeeklyLossName;
   string          m_toggleGuardModeName;
   string          m_toggleNotificationsName;
   string          m_labelStatusName;
   
public:
   CGuardPanel(CDDGuard* ddGuard, CRiskManager* riskMgr, CLogger* logger)
      : CPanel("GuardPanel_" + IntegerToString(GetTickCount()), 0, 0, PANEL_WIDTH, PANEL_HEIGHT - HEADER_HEIGHT - TAB_HEIGHT)
   {
      m_ddGuard = ddGuard;
      m_riskManager = riskMgr;
      m_logger = logger;
      
      m_dailyLossLimit = InpMaxDailyLoss;
      m_weeklyLossLimit = 10.0; // Default weekly limit
      m_guardModeActive = true;
      m_notificationsEnabled = true;
      
      m_labelDailyLossName = m_panelName + "_LabelDailyLoss";
      m_labelWeeklyLossName = m_panelName + "_LabelWeeklyLoss";
      m_toggleGuardModeName = m_panelName + "_ToggleGuardMode";
      m_toggleNotificationsName = m_panelName + "_ToggleNotifications";
      m_labelStatusName = m_panelName + "_LabelStatus";
   }
   
   //+------------------------------------------------------------------+
   //| Create panel                                                    |
   //+------------------------------------------------------------------+
   bool Create() override
   {
      if(!m_enableUI || !m_visible) return true;
      
      int startY = m_y + 20;
      int currentY = startY;
      
      // Daily Loss Limit
      double dailyLoss = m_riskManager != NULL ? m_riskManager.GetDailyLoss() : 0;
      double dailyLossPercent = m_riskManager != NULL ? m_riskManager.GetDailyLossPercent() : 0;
      string dailyText = "$" + DoubleToString(dailyLoss, 2) + " (" + DoubleToString(dailyLossPercent, 1) + "%)";
      
      if(!CreateUILabel(m_panelName + "_LabelDailyTitle", m_x + 20, currentY, "Daily Loss Limit:", COLOR_TEXT_PRIMARY))
         return false;
      if(!CreateUILabel(m_labelDailyLossName, m_x + 150, currentY, dailyText, 
                       dailyLossPercent >= m_dailyLossLimit ? COLOR_ACCENT_RED : COLOR_TEXT_SECONDARY))
         return false;
      
      currentY += 35;
      
      // Weekly Loss Limit
      if(!CreateUILabel(m_panelName + "_LabelWeeklyTitle", m_x + 20, currentY, "Weekly Loss Limit:", COLOR_TEXT_PRIMARY))
         return false;
      if(!CreateUILabel(m_labelWeeklyLossName, m_x + 150, currentY, "$" + DoubleToString(m_weeklyLossLimit * 100, 2) + " (" + DoubleToString(m_weeklyLossLimit, 1) + "%)", COLOR_TEXT_SECONDARY))
         return false;
      
      currentY += 50;
      
      // Guard Mode toggle
      if(!CreateUIToggle(m_toggleGuardModeName, m_x + 20, currentY, 250, 30, "GUARD MODE: ACTIVE", m_guardModeActive))
         return false;
      
      currentY += 40;
      
      // Notifications toggle
      if(!CreateUIToggle(m_toggleNotificationsName, m_x + 20, currentY, 250, 30, "Notifications", m_notificationsEnabled))
         return false;
      
      currentY += 50;
      
      // Status indicator
      string statusText = "Status: All Systems Normal";
      color statusColor = COLOR_ACCENT_GREEN;
      
      if(m_ddGuard != NULL && m_ddGuard.IsTradingHalted())
      {
         statusText = "Status: Trading Halted - Drawdown Limit Exceeded";
         statusColor = COLOR_ACCENT_RED;
      }
      
      if(!CreateUILabel(m_labelStatusName, m_x + 20, currentY, statusText, statusColor))
         return false;
      
      ChartRedraw();
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Handle chart event                                              |
   //+------------------------------------------------------------------+
   bool OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam) override
   {
      if(!m_enableUI) return false;
      
      if(id == CHARTEVENT_OBJECT_CLICK)
      {
         if(sparam == m_toggleGuardModeName)
         {
            m_guardModeActive = !m_guardModeActive;
            CreateUIToggle(m_toggleGuardModeName, m_x + 20, m_y + 90, 250, 30, 
                          "GUARD MODE: " + (m_guardModeActive ? "ACTIVE" : "INACTIVE"), m_guardModeActive);
            ChartRedraw();
            return true;
         }
         else if(sparam == m_toggleNotificationsName)
         {
            m_notificationsEnabled = !m_notificationsEnabled;
            CreateUIToggle(m_toggleNotificationsName, m_x + 20, m_y + 130, 250, 30, "Notifications", m_notificationsEnabled);
            ChartRedraw();
            return true;
         }
      }
      
      return false;
   }
   
   //+------------------------------------------------------------------+
   //| Update panel                                                    |
   //+------------------------------------------------------------------+
   void Update() override
   {
      if(!m_enableUI) return;
      
      // Update loss displays
      if(m_riskManager != NULL)
      {
         double dailyLoss = m_riskManager.GetDailyLoss();
         double dailyLossPercent = m_riskManager.GetDailyLossPercent();
         string dailyText = "$" + DoubleToString(dailyLoss, 2) + " (" + DoubleToString(dailyLossPercent, 1) + "%)";
         
         ObjectSetString(0, m_labelDailyLossName, OBJPROP_TEXT, dailyText);
         ObjectSetInteger(0, m_labelDailyLossName, OBJPROP_COLOR, 
                         dailyLossPercent >= m_dailyLossLimit ? COLOR_ACCENT_RED : COLOR_TEXT_SECONDARY);
      }
      
      // Update status
      string statusText = "Status: All Systems Normal";
      color statusColor = COLOR_ACCENT_GREEN;
      
      if(m_ddGuard != NULL && m_ddGuard.IsTradingHalted())
      {
         statusText = "Status: Trading Halted - Drawdown Limit Exceeded";
         statusColor = COLOR_ACCENT_RED;
      }
      
      ObjectSetString(0, m_labelStatusName, OBJPROP_TEXT, statusText);
      ObjectSetInteger(0, m_labelStatusName, OBJPROP_COLOR, statusColor);
      
      ChartRedraw();
   }
   
   //+------------------------------------------------------------------+
   //| Delete all objects                                             |
   //+------------------------------------------------------------------+
   void DeleteAll() override
   {
      if(!m_enableUI) return;
      
      // Delete all panel objects with this panel name
      ObjectsDeleteAll(0, m_panelName);
      
      // CRITICAL: Also delete by base prefix to catch all variations
      int total = ObjectsTotal(0);
      for(int i = total - 1; i >= 0; i--)
      {
         string name = ObjectName(0, i);
         if(StringFind(name, m_panelName) == 0)
            ObjectDelete(0, name);
      }
      
      ChartRedraw();
   }
};

//+------------------------------------------------------------------+
