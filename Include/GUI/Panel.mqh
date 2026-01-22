//+------------------------------------------------------------------+
//| Panel.mqh                                                        |
//| Base panel class for UI panels                                  |
//+------------------------------------------------------------------+
#property copyright "Azzuro"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "Theme.mqh"

//+------------------------------------------------------------------+
//| Base Panel class                                                 |
//+------------------------------------------------------------------+
class CPanel
{
public:
   string   m_panelName;
   int      m_x;
   int      m_y;
   int      m_width;
   int      m_height;
   bool     m_visible;
   bool     m_enableUI;
   
public:
   CPanel(string name, int x, int y, int width, int height)
   {
      m_panelName = name;
      m_x = x;
      m_y = y;
      m_width = width;
      m_height = height;
      m_visible = false;
      m_enableUI = InpEnableUI;
   }
   
   virtual bool Create() 
   { 
      if(!m_visible) return true;
      return true; 
   }
   virtual void Update() {}
   virtual bool OnChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam) { return false; }
   virtual void SetVisible(bool visible) { m_visible = visible; }
   virtual void DeleteAll() 
   {
      if(!m_enableUI) return;
      ObjectsDeleteAll(0, m_panelName);
   }
};

//+------------------------------------------------------------------+
