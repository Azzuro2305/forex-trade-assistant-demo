//+------------------------------------------------------------------+
//| StateModel.mqh                                                   |
//| State model for EA - OPTIONAL, NON-CRITICAL                      |
//+------------------------------------------------------------------+
#property copyright "Azzuro"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| State Model class (Optional - for state persistence)            |
//+------------------------------------------------------------------+
// Note: This is optional and non-critical for VPS operation
// State should be rebuildable from open positions and account info

class CStateModel
{
private:
   // State variables (non-critical)
   datetime m_lastUpdate;
   int      m_lastPositionCount;
   
public:
   CStateModel()
   {
      m_lastUpdate = 0;
      m_lastPositionCount = 0;
   }
   
   void Update()
   {
      m_lastUpdate = TimeCurrent();
      m_lastPositionCount = PositionsTotal();
   }
   
   datetime GetLastUpdate() const { return m_lastUpdate; }
   int GetLastPositionCount() const { return m_lastPositionCount; }
};

//+------------------------------------------------------------------+
