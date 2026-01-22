//+------------------------------------------------------------------+
//| ManagePanel.mqh                                                  |
//| Manage Tab Panel - Auto BE and Trailing Stop controls          |
//+------------------------------------------------------------------+
#property copyright "Azzuro"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Panel.mqh"
#include "../Controls.mqh"
#include "../../Engine/BEManager.mqh"
#include "../../Engine/TrailingManager.mqh"
#include "../../Core/Logger.mqh"

//+------------------------------------------------------------------+
//| Manage Panel class                                               |
//+------------------------------------------------------------------+
class CManagePanel : public CPanel
{
private:
   CBEManager*         m_beManager;
   CTrailingManager*   m_trailingManager;
   CLogger*            m_logger;
   
   // Settings
   bool                m_autoBEEnabled;
   int                 m_bePoints;
   double              m_beOffset;
   bool                m_autoTrailingEnabled;
   int                 m_trailingStart;
   int                 m_trailingStep;
   int                 m_trailingStop;
   bool                m_guardModeActive;
   
   // Control names
   string              m_toggleBEName;
   string              m_editBEPointsName;
   string              m_editBEOffsetName;
   string              m_toggleTrailingName;
   string              m_editTrailingStartName;
   string              m_editTrailingStepName;
   string              m_editTrailingStopName;
   string              m_btnGuardModeName;
   
public:
   CManagePanel(CBEManager* beMgr, CTrailingManager* trailingMgr, CLogger* logger)
      : CPanel("ManagePanel_" + IntegerToString(GetTickCount()), 0, 0, PANEL_WIDTH, PANEL_HEIGHT - HEADER_HEIGHT - TAB_HEIGHT)
   {
      m_beManager = beMgr;
      m_trailingManager = trailingMgr;
      m_logger = logger;
      
      m_autoBEEnabled = true;
      m_bePoints = 20;
      m_beOffset = 1.0;
      m_autoTrailingEnabled = true;
      m_trailingStart = 15;
      m_trailingStep = 5;
      m_trailingStop = 5;
      m_guardModeActive = true;
      
      m_toggleBEName = m_panelName + "_ToggleBE";
      m_editBEPointsName = m_panelName + "_EditBEPoints";
      m_editBEOffsetName = m_panelName + "_EditBEOffset";
      m_toggleTrailingName = m_panelName + "_ToggleTrailing";
      m_editTrailingStartName = m_panelName + "_EditTrailingStart";
      m_editTrailingStepName = m_panelName + "_EditTrailingStep";
      m_editTrailingStopName = m_panelName + "_EditTrailingStop";
      m_btnGuardModeName = m_panelName + "_BtnGuardMode";
   }
   
   //+------------------------------------------------------------------+
   //| Create panel                                                    |
   //+------------------------------------------------------------------+
   bool Create() override
   {
      if(!m_enableUI || !m_visible) return true;
      
      int startY = m_y + 20;
      int currentY = startY;
      
      // Auto Break Even section
      if(!CreateUIToggle(m_toggleBEName, m_x + 20, currentY, 200, 30, "Auto Break Even", m_autoBEEnabled))
         return false;
      
      currentY += 40;
      
      if(!CreateUILabel(m_panelName + "_LabelBEPoints", m_x + 40, currentY, "Break Even at:", COLOR_TEXT_SECONDARY))
         return false;
      if(!CreateUIEdit(m_editBEPointsName, m_x + 150, currentY, 80, 25, IntegerToString(m_bePoints) + " pips"))
         return false;
      
      currentY += 35;
      
      if(!CreateUILabel(m_panelName + "_LabelBEOffset", m_x + 40, currentY, "Offset:", COLOR_TEXT_SECONDARY))
         return false;
      if(!CreateUIEdit(m_editBEOffsetName, m_x + 150, currentY, 80, 25, DoubleToString(m_beOffset, 1) + " pip <"))
         return false;
      
      currentY += 50;
      
      // Auto Trailing Stop section
      if(!CreateUIToggle(m_toggleTrailingName, m_x + 20, currentY, 200, 30, "Auto Trailing Stop", m_autoTrailingEnabled))
         return false;
      
      currentY += 40;
      
      if(!CreateUILabel(m_panelName + "_LabelTrailingStart", m_x + 40, currentY, "Start trailing at:", COLOR_TEXT_SECONDARY))
         return false;
      if(!CreateUIEdit(m_editTrailingStartName, m_x + 150, currentY, 80, 25, "+" + IntegerToString(m_trailingStart) + " pips"))
         return false;
      
      currentY += 35;
      
      if(!CreateUILabel(m_panelName + "_LabelTrailingBy", m_x + 40, currentY, "Trailing by:", COLOR_TEXT_SECONDARY))
         return false;
      if(!CreateUIEdit(m_editTrailingStepName, m_x + 150, currentY, 80, 25, IntegerToString(m_trailingStep) + " pips"))
         return false;
      
      currentY += 50;
      
      // Guard Mode button
      if(!CreateUIButton(m_btnGuardModeName, m_x + 20, currentY, 500, 40, 
                        "GUARD MODE: " + (m_guardModeActive ? "ACTIVE" : "INACTIVE"), 
                        m_guardModeActive ? COLOR_ACCENT_GREEN : COLOR_BG_PANEL))
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
         if(sparam == m_toggleBEName)
         {
            m_autoBEEnabled = !m_autoBEEnabled;
            CreateUIToggle(m_toggleBEName, m_x + 20, m_y + 20, 200, 30, "Auto Break Even", m_autoBEEnabled);
            ChartRedraw();
            return true;
         }
         else if(sparam == m_toggleTrailingName)
         {
            m_autoTrailingEnabled = !m_autoTrailingEnabled;
            CreateUIToggle(m_toggleTrailingName, m_x + 20, m_y + 120, 200, 30, "Auto Trailing Stop", m_autoTrailingEnabled);
            ChartRedraw();
            return true;
         }
         else if(sparam == m_btnGuardModeName)
         {
            m_guardModeActive = !m_guardModeActive;
            CreateUIButton(m_btnGuardModeName, m_x + 20, m_y + 250, 500, 40, 
                          "GUARD MODE: " + (m_guardModeActive ? "ACTIVE" : "INACTIVE"), 
                          m_guardModeActive ? COLOR_ACCENT_GREEN : COLOR_BG_PANEL);
            ChartRedraw();
            return true;
         }
      }
      else if(id == CHARTEVENT_OBJECT_ENDEDIT)
      {
         if(sparam == m_editBEPointsName)
         {
            string text = ObjectGetString(0, m_editBEPointsName, OBJPROP_TEXT);
            text = StringSubstr(text, 0, StringFind(text, " "));
            m_bePoints = (int)StringToInteger(text);
            if(m_beManager != NULL)
               m_beManager.SetBEPoints(m_bePoints);
            return true;
         }
         else if(sparam == m_editBEOffsetName)
         {
            string text = ObjectGetString(0, m_editBEOffsetName, OBJPROP_TEXT);
            text = StringSubstr(text, 0, StringFind(text, " "));
            m_beOffset = StringToDouble(text);
            if(m_beManager != NULL)
               m_beManager.SetBEOffset(m_beOffset);
            return true;
         }
         else if(sparam == m_editTrailingStartName)
         {
            string text = ObjectGetString(0, m_editTrailingStartName, OBJPROP_TEXT);
            text = StringSubstr(text, 1, StringFind(text, " ") - 1);
            m_trailingStart = (int)StringToInteger(text);
            if(m_trailingManager != NULL)
               m_trailingManager.SetTrailingStart(m_trailingStart);
            return true;
         }
         else if(sparam == m_editTrailingStepName)
         {
            string text = ObjectGetString(0, m_editTrailingStepName, OBJPROP_TEXT);
            text = StringSubstr(text, 0, StringFind(text, " "));
            m_trailingStep = (int)StringToInteger(text);
            if(m_trailingManager != NULL)
               m_trailingManager.SetTrailingStep(m_trailingStep);
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
      // Update displayed values if needed
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
