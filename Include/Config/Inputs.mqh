//+------------------------------------------------------------------+
//| Inputs.mqh                                                       |
//| EA Input Parameters - VPS-safe configuration                    |
//+------------------------------------------------------------------+
#property copyright "Azzuro"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| EA Constants                                                      |
//+------------------------------------------------------------------+
#define EA_NAME "ForexTradeAssistant"
#define EA_VERSION "2.00"

//+------------------------------------------------------------------+
//| General Settings                                                 |
//+------------------------------------------------------------------+
input group "=== General Settings ==="
input int    InpMagicNumber = 123456;        // Magic Number
input string InpTradeComment = "FTA_EA";     // Trade Comment

//+------------------------------------------------------------------+
//| Trading Settings                                                 |
//+------------------------------------------------------------------+
input group "=== Trading Settings ==="
input double InpLotSize = 0.01;              // Lot Size
input int    InpSlippage = 30;               // Slippage (points)
input int    InpStopLoss = 1000;               // Stop Loss (points)
input int    InpTakeProfit = 2000;            // Take Profit (points)

//+------------------------------------------------------------------+
//| Risk Management                                                  |
//+------------------------------------------------------------------+
input group "=== Risk Management ==="
input double InpRiskPercent = 2.0;           // Risk Per Trade (%)
input double InpMaxDailyLoss = 5.0;          // Max Daily Loss (%)
input int    InpMaxOpenPositions = 3;       // Max Open Positions

//+------------------------------------------------------------------+
//| Strategy Settings                                                |
//+------------------------------------------------------------------+
input group "=== Strategy Settings ==="
input int    InpTimeframe = PERIOD_H1;       // Timeframe
input bool   InpEnableTrading = true;        // Enable Trading

//+------------------------------------------------------------------+
//| UI Control (VPS Compatibility)                                 |
//+------------------------------------------------------------------+
input group "=== UI Control ==="
input bool   InpEnableUI = true;             // Enable UI (set false for VPS)

//+------------------------------------------------------------------+
//| Visual Trading GUI (Local Only - ignored if EnableUI=false)      |
//+------------------------------------------------------------------+
input group "=== Visual Trading GUI (Local Only) ==="
input bool   InpEnableVisualTrading = false;  // Enable Visual Trading
input int    InpPanelX = 20;                 // Panel X Position
input int    InpPanelY = 50;                 // Panel Y Position
input color  InpBuyLineColor = Blue;    // Buy Line Color
input color  InpSellLineColor = Blue;      // Sell Line Color
input color  InpTPLineColor = clrLimeGreen;       // TP Line Color
input color  InpSLLineColor = clrRed;            // SL Line Color
input int    InpLineWidth = 1;              // Line Width
input int    InpLineStyle = STYLE_SOLID;    // Line Style
input bool   InpUseFixedRR = false;         // Use Fixed Risk/Reward
input double InpFixedRR = 2.0;              // Fixed Risk/Reward Ratio

//+------------------------------------------------------------------+
