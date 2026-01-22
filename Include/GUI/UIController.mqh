//+------------------------------------------------------------------+
//| UIController.mqh                                                 |
//| Main UI Controller with 4 tabs                                  |
//+------------------------------------------------------------------+
#property copyright "Azzuro"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../Config/Inputs.mqh"
#include "../Core/Logger.mqh"
#include "../Utils/Helpers.mqh"
#include "Theme.mqh"
#include "Panel.mqh"
#include "Controls.mqh"
#include "Trade/TradePanel.mqh"
#include "Manage/ManagePanel.mqh"
#include "Guard/GuardPanel.mqh"
#include "Review/ReviewPanel.mqh"

//+------------------------------------------------------------------+
//| Tab enumeration                                                  |
//+------------------------------------------------------------------+
enum ENUM_UI_TAB
{
   TAB_TRADE = 0,
   TAB_MANAGE = 1,
   TAB_GUARD = 2,
   TAB_REVIEW = 3
};

//+------------------------------------------------------------------+
//| Main UI Controller class                                        |
//+------------------------------------------------------------------+
class CUIController
{
private:
   bool            m_enableUI;
   string          m_panelName;
   int             m_x;
   int             m_y;
   ENUM_UI_TAB     m_activeTab;
   
   // Tab panels
   CTradePanel*    m_tradePanel;
   CManagePanel*   m_managePanel;
   CGuardPanel*    m_guardPanel;
   CReviewPanel*   m_reviewPanel;
   
   // UI Elements
   string          m_headerName;
   string          m_tabTradeName;
   string          m_tabManageName;
   string          m_tabGuardName;
   string          m_tabReviewName;
   string          m_btnCloseName;
   
   CLogger*        m_logger;
   
   //+------------------------------------------------------------------+
   //| Create header                                                    |
   //+------------------------------------------------------------------+
   bool CreateHeader()
   {
      if(!m_enableUI) return true;
      
      // Main panel background
      string bgName = m_panelName + "_Background";
      if(ObjectFind(0, bgName) >= 0)
         ObjectDelete(0, bgName);
      
      if(!ObjectCreate(0, bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0))
         return false;
      
      ObjectSetInteger(0, bgName, OBJPROP_XDISTANCE, m_x);
      ObjectSetInteger(0, bgName, OBJPROP_YDISTANCE, m_y);
      ObjectSetInteger(0, bgName, OBJPROP_XSIZE, PANEL_WIDTH);
      ObjectSetInteger(0, bgName, OBJPROP_YSIZE, PANEL_HEIGHT);
      ObjectSetInteger(0, bgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, bgName, OBJPROP_BGCOLOR, COLOR_BG_PANEL);
      ObjectSetInteger(0, bgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, bgName, OBJPROP_BORDER_COLOR, COLOR_BORDER);
      ObjectSetInteger(0, bgName, OBJPROP_BACK, true);
      
      // Header background
      if(ObjectFind(0, m_headerName) >= 0)
         ObjectDelete(0, m_headerName);
      
      if(!ObjectCreate(0, m_headerName, OBJ_RECTANGLE_LABEL, 0, 0, 0))
         return false;
      
      ObjectSetInteger(0, m_headerName, OBJPROP_XDISTANCE, m_x);
      ObjectSetInteger(0, m_headerName, OBJPROP_YDISTANCE, m_y);
      ObjectSetInteger(0, m_headerName, OBJPROP_XSIZE, PANEL_WIDTH);
      ObjectSetInteger(0, m_headerName, OBJPROP_YSIZE, HEADER_HEIGHT);
      ObjectSetInteger(0, m_headerName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, m_headerName, OBJPROP_BGCOLOR, COLOR_BG_HEADER);
      ObjectSetInteger(0, m_headerName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, m_headerName, OBJPROP_BORDER_COLOR, COLOR_BORDER);
      ObjectSetInteger(0, m_headerName, OBJPROP_BACK, false);
      
      // Title
      string titleName = m_panelName + "_Title";
      if(ObjectFind(0, titleName) >= 0)
         ObjectDelete(0, titleName);
      
      if(ObjectCreate(0, titleName, OBJ_LABEL, 0, 0, 0))
      {
         ObjectSetInteger(0, titleName, OBJPROP_XDISTANCE, m_x + 20);
         ObjectSetInteger(0, titleName, OBJPROP_YDISTANCE, m_y + 10);
         ObjectSetInteger(0, titleName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
         ObjectSetString(0, titleName, OBJPROP_TEXT, "FOREX TRADE ASSISTANT");
         ObjectSetInteger(0, titleName, OBJPROP_COLOR, COLOR_ACCENT_GOLD);
         ObjectSetInteger(0, titleName, OBJPROP_FONTSIZE, FONT_SIZE_TITLE);
         ObjectSetString(0, titleName, OBJPROP_FONT, FONT_NAME_BOLD);
      }
      
      // Subtitle
      string subtitleName = m_panelName + "_Subtitle";
      if(ObjectFind(0, subtitleName) >= 0)
         ObjectDelete(0, subtitleName);
      
      if(ObjectCreate(0, subtitleName, OBJ_LABEL, 0, 0, 0))
      {
         ObjectSetInteger(0, subtitleName, OBJPROP_XDISTANCE, m_x + 20);
         ObjectSetInteger(0, subtitleName, OBJPROP_YDISTANCE, m_y + 30);
         ObjectSetInteger(0, subtitleName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
         ObjectSetString(0, subtitleName, OBJPROP_TEXT, "PRO FIT TRADING TOOL");
         ObjectSetInteger(0, subtitleName, OBJPROP_COLOR, COLOR_TEXT_SECONDARY);
         ObjectSetInteger(0, subtitleName, OBJPROP_FONTSIZE, FONT_SIZE_NORMAL);
      }
      
      // Close button
      if(!CreateButton(m_btnCloseName, m_x + PANEL_WIDTH - 35, m_y + 10, 25, 25, "X", COLOR_BG_PANEL))
         return false;
      
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Create tabs                                                     |
   //+------------------------------------------------------------------+
   bool CreateTabs()
   {
      if(!m_enableUI) return true;
      
      int tabY = m_y + HEADER_HEIGHT;
      int tabWidth = PANEL_WIDTH / 4;
      
      // Trade tab
      color tradeColor = (m_activeTab == TAB_TRADE) ? COLOR_ACCENT_GOLD : COLOR_BG_PANEL;
      if(!CreateButton(m_tabTradeName, m_x, tabY, tabWidth, TAB_HEIGHT, "Trade", tradeColor))
         return false;
      
      // Manage tab
      color manageColor = (m_activeTab == TAB_MANAGE) ? COLOR_ACCENT_GOLD : COLOR_BG_PANEL;
      if(!CreateButton(m_tabManageName, m_x + tabWidth, tabY, tabWidth, TAB_HEIGHT, "Manage", manageColor))
         return false;
      
      // Guard tab
      color guardColor = (m_activeTab == TAB_GUARD) ? COLOR_ACCENT_GOLD : COLOR_BG_PANEL;
      if(!CreateButton(m_tabGuardName, m_x + tabWidth * 2, tabY, tabWidth, TAB_HEIGHT, "Guard", guardColor))
         return false;
      
      // Review tab
      color reviewColor = (m_activeTab == TAB_REVIEW) ? COLOR_ACCENT_GOLD : COLOR_BG_PANEL;
      if(!CreateButton(m_tabReviewName, m_x + tabWidth * 3, tabY, tabWidth, TAB_HEIGHT, "Review", reviewColor))
         return false;
      
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Create button helper                                            |
   //+------------------------------------------------------------------+
   bool CreateButton(string name, int x, int y, int width, int height, string text, color bgColor)
   {
      if(!m_enableUI) return true;
      
      if(ObjectFind(0, name) >= 0)
         ObjectDelete(0, name);
      
      if(!ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0))
         return false;
      
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
      ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetInteger(0, name, OBJPROP_COLOR, COLOR_TEXT_PRIMARY);
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bgColor);
      ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, COLOR_BORDER);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, FONT_SIZE_NORMAL);
      ObjectSetString(0, name, OBJPROP_FONT, FONT_NAME);
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Switch tab                                                      |
   //+------------------------------------------------------------------+
   void SwitchTab(ENUM_UI_TAB tab)
   {
      if(!m_enableUI) return;
      
      m_activeTab = tab;
      CreateTabs();
      
      // Hide all panels (delete their objects)
      if(m_tradePanel != NULL) 
      {
         m_tradePanel.DeleteAll();
         m_tradePanel.SetVisible(false);
      }
      if(m_managePanel != NULL) 
      {
         m_managePanel.DeleteAll();
         m_managePanel.SetVisible(false);
      }
      if(m_guardPanel != NULL) 
      {
         m_guardPanel.DeleteAll();
         m_guardPanel.SetVisible(false);
      }
      if(m_reviewPanel != NULL) 
      {
         m_reviewPanel.DeleteAll();
         m_reviewPanel.SetVisible(false);
      }
      
      // Show active panel
      switch(tab)
      {
         case TAB_TRADE:
            if(m_tradePanel != NULL) 
            {
               m_tradePanel.SetVisible(true);
               m_tradePanel.Create();
            }
            break;
         case TAB_MANAGE:
            if(m_managePanel != NULL) 
            {
               m_managePanel.SetVisible(true);
               m_managePanel.Create();
            }
            break;
         case TAB_GUARD:
            if(m_guardPanel != NULL) 
            {
               m_guardPanel.SetVisible(true);
               m_guardPanel.Create();
            }
            break;
         case TAB_REVIEW:
            if(m_reviewPanel != NULL) 
            {
               m_reviewPanel.SetVisible(true);
               m_reviewPanel.Create();
            }
            break;
      }
      
      ChartRedraw();
   }
   
public:
   CUIController(int x = 50, int y = 50, CLogger* logger = NULL)
   {
      m_x = x;
      m_y = y;
      m_enableUI = InpEnableUI;
      m_activeTab = TAB_TRADE;
      m_panelName = "FTA_UI_" + IntegerToString(GetTickCount());
      
      m_tradePanel = NULL;
      m_managePanel = NULL;
      m_guardPanel = NULL;
      m_reviewPanel = NULL;
      
      m_headerName = m_panelName + "_Header";
      m_tabTradeName = m_panelName + "_TabTrade";
      m_tabManageName = m_panelName + "_TabManage";
      m_tabGuardName = m_panelName + "_TabGuard";
      m_tabReviewName = m_panelName + "_TabReview";
      m_btnCloseName = m_panelName + "_BtnClose";
      
      m_logger = logger;
   }
   
   ~CUIController()
   {
      // CRITICAL: Delete all panel objects BEFORE deleting panel instances
      // This ensures all UI elements are cleaned up properly
      if(m_tradePanel != NULL) 
      {
         m_tradePanel.DeleteAll();
         delete m_tradePanel; 
         m_tradePanel = NULL;
      }
      if(m_managePanel != NULL) 
      {
         m_managePanel.DeleteAll();
         delete m_managePanel; 
         m_managePanel = NULL;
      }
      if(m_guardPanel != NULL) 
      {
         m_guardPanel.DeleteAll();
         delete m_guardPanel; 
         m_guardPanel = NULL;
      }
      if(m_reviewPanel != NULL) 
      {
         m_reviewPanel.DeleteAll();
         delete m_reviewPanel; 
         m_reviewPanel = NULL;
      }
      
      // Delete all UIController objects
      DeleteAll();
   }
   
   //+------------------------------------------------------------------+
   //| Initialize UI                                                   |
   //+------------------------------------------------------------------+
   bool Initialize(CTradeManager* tradeMgr, CRiskManager* riskMgr, 
                   CBEManager* beMgr, CTrailingManager* trailingMgr,
                   CDDGuard* ddGuard, int magicNumber)
   {
      if(!m_enableUI) return true;
      
      if(!CreateHeader()) return false;
      if(!CreateTabs()) return false;
      
      // Calculate panel position (below header and tabs)
      int panelY = m_y + HEADER_HEIGHT + TAB_HEIGHT;
      int panelHeight = PANEL_HEIGHT - HEADER_HEIGHT - TAB_HEIGHT;
      
      // Initialize panels (will be created when tab is switched)
      m_tradePanel = new CTradePanel(tradeMgr, riskMgr, m_logger);
      m_tradePanel.m_x = m_x;
      m_tradePanel.m_y = panelY;
      m_tradePanel.m_width = PANEL_WIDTH;
      m_tradePanel.m_height = panelHeight;
      
      m_managePanel = new CManagePanel(beMgr, trailingMgr, m_logger);
      m_managePanel.m_x = m_x;
      m_managePanel.m_y = panelY;
      m_managePanel.m_width = PANEL_WIDTH;
      m_managePanel.m_height = panelHeight;
      
      m_guardPanel = new CGuardPanel(ddGuard, riskMgr, m_logger);
      m_guardPanel.m_x = m_x;
      m_guardPanel.m_y = panelY;
      m_guardPanel.m_width = PANEL_WIDTH;
      m_guardPanel.m_height = panelHeight;
      
      m_reviewPanel = new CReviewPanel(magicNumber, m_logger);
      m_reviewPanel.m_x = m_x;
      m_reviewPanel.m_y = panelY;
      m_reviewPanel.m_width = PANEL_WIDTH;
      m_reviewPanel.m_height = panelHeight;
      
      // Show default tab (will create the panel)
      SwitchTab(TAB_TRADE);
      
      ChartRedraw();
      return true;
   }
   
   //+------------------------------------------------------------------+
   //| Handle chart event                                              |
   //+------------------------------------------------------------------+
   bool OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
   {
      if(!m_enableUI) return false;
      
      if(id == CHARTEVENT_OBJECT_CLICK)
      {
         // Tab switching
         if(sparam == m_tabTradeName)
         {
            SwitchTab(TAB_TRADE);
            return true;
         }
         else if(sparam == m_tabManageName)
         {
            SwitchTab(TAB_MANAGE);
            return true;
         }
         else if(sparam == m_tabGuardName)
         {
            SwitchTab(TAB_GUARD);
            return true;
         }
         else if(sparam == m_tabReviewName)
         {
            SwitchTab(TAB_REVIEW);
            return true;
         }
         else if(sparam == m_btnCloseName)
         {
            SetVisible(false);
            return true;
         }
      }
      
      // Forward events to active panel
      switch(m_activeTab)
      {
         case TAB_TRADE:
            if(m_tradePanel != NULL) return m_tradePanel.OnChartEvent(id, lparam, dparam, sparam);
            break;
         case TAB_MANAGE:
            if(m_managePanel != NULL) return m_managePanel.OnChartEvent(id, lparam, dparam, sparam);
            break;
         case TAB_GUARD:
            if(m_guardPanel != NULL) return m_guardPanel.OnChartEvent(id, lparam, dparam, sparam);
            break;
         case TAB_REVIEW:
            // #region agent log
            if(id == CHARTEVENT_OBJECT_CLICK)
            {
               WriteDebugLog("UIController.mqh:424", "Forwarding click to ReviewPanel", "{\"sparam\":\"" + sparam + "\",\"activeTab\":\"REVIEW\"}");
            }
            // #endregion agent log
            if(m_reviewPanel != NULL) return m_reviewPanel.OnChartEvent(id, lparam, dparam, sparam);
            break;
      }
      
      return false;
   }
   
   //+------------------------------------------------------------------+
   //| Update UI                                                       |
   //+------------------------------------------------------------------+
   void Update()
   {
      if(!m_enableUI) return;
      
      // Update active panel
      switch(m_activeTab)
      {
         case TAB_TRADE:
            if(m_tradePanel != NULL) m_tradePanel.Update();
            break;
         case TAB_MANAGE:
            if(m_managePanel != NULL) m_managePanel.Update();
            break;
         case TAB_GUARD:
            if(m_guardPanel != NULL) m_guardPanel.Update();
            break;
         case TAB_REVIEW:
            if(m_reviewPanel != NULL) m_reviewPanel.Update();
            break;
      }
   }
   
   //+------------------------------------------------------------------+
   //| Set visible                                                     |
   //+------------------------------------------------------------------+
   void SetVisible(bool visible)
   {
      if(!m_enableUI) return;
      // Implementation for show/hide
   }
   
   //+------------------------------------------------------------------+
   //| Delete all objects                                             |
   //+------------------------------------------------------------------+
   void DeleteAll()
   {
      if(!m_enableUI) return;
      
      // Delete all UI panel objects with this panel name
      ObjectsDeleteAll(0, m_panelName);
      
      // CRITICAL: Delete all objects with common panel prefixes
      // This ensures cleanup even if panel names changed
      ObjectsDeleteAll(0, "TradePanel_");
      ObjectsDeleteAll(0, "ManagePanel_");
      ObjectsDeleteAll(0, "GuardPanel_");
      ObjectsDeleteAll(0, "ReviewPanel_");
      ObjectsDeleteAll(0, "FTA_UI_");
      
      // CRITICAL: Also delete all visual trade lines (VTL_ objects)
      // These are created by TradePanel and might not be cleaned up properly
      int total = ObjectsTotal(0);
      for(int i = total - 1; i >= 0; i--)
      {
         string name = ObjectName(0, i);
         // Delete VTL_ objects
         if(StringFind(name, "VTL_") == 0)
            ObjectDelete(0, name);
         // Delete any objects with EA name prefix
         else if(StringFind(name, EA_NAME + "_") == 0)
            ObjectDelete(0, name);
      }
      
      ChartRedraw();
   }
   
   //+------------------------------------------------------------------+
   //| Get trade panel (for external access)                          |
   //+------------------------------------------------------------------+
   CTradePanel* GetTradePanel() { return m_tradePanel; }
   CManagePanel* GetManagePanel() { return m_managePanel; }
   CGuardPanel* GetGuardPanel() { return m_guardPanel; }
   CReviewPanel* GetReviewPanel() { return m_reviewPanel; }
};

//+------------------------------------------------------------------+
