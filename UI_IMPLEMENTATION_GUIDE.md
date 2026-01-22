# UI Implementation Guide

## Overview
A comprehensive 4-tab UI system has been implemented for the ForexTradeAssistant EA, fully compatible with MetaQuotes VPS through the `InpEnableUI` flag.

## UI Structure

### Main Components

1. **UIController.mqh** - Main UI controller managing tabs and overall layout
2. **Theme.mqh** - Color scheme and styling constants
3. **Panel.mqh** - Base panel class
4. **Controls.mqh** - UI control helper functions

### Tab Panels

1. **TradePanel.mqh** - Trade tab (Buy/Sell controls)
2. **ManagePanel.mqh** - Manage tab (Auto BE, Trailing Stop)
3. **GuardPanel.mqh** - Guard tab (Loss limits, Guard mode)
4. **ReviewPanel.mqh** - Review tab (Trade history visualization)

## Features by Tab

### 1. Trade Tab
- **Buy/Sell Buttons**: Quick trade execution
- **Volume Input**: Lot size input
- **SL Input**: Stop loss in points
- **TP Input**: Take profit in points
- **Risk per Trade**: Risk percentage input
- **Large Buy/Sell Buttons**: With calculated profit values ($)
- **Real-time Calculations**: Updates trade values based on inputs

**Binding**: Uses `CTradeManager` and `CRiskManager` from Engine

### 2. Manage Tab
- **Auto Break Even Toggle**: Enable/disable BE management
- **Break Even Points**: Points profit before moving to BE
- **Break Even Offset**: Offset from entry (in pips)
- **Auto Trailing Stop Toggle**: Enable/disable trailing
- **Start Trailing At**: Points profit before trailing starts
- **Trailing By**: Points to trail by
- **Guard Mode Toggle**: Enable/disable guard mode

**Binding**: Uses `CBEManager` and `CTrailingManager` from Engine

### 3. Guard Tab
- **Daily Loss Limit**: Shows current daily loss ($ and %)
- **Weekly Loss Limit**: Shows weekly loss limit
- **Guard Mode Toggle**: Enable/disable guard mode
- **Notifications Toggle**: Enable/disable notifications
- **Status Indicator**: Shows "All Systems Normal" or "Trading Halted"

**Binding**: Uses `CDDGuard` and `CRiskManager` from Engine

### 4. Review Tab
- **Previous/Next Buttons**: Navigate through trade history
- **Trade Counter**: Shows "X of Y" trades
- **Statistics Display**:
  - Avg Win
  - Avg Loss
  - Win Rate
  - Profit Factor
  - MFE/MAE (pips)
- **Chart Visualization**:
  - Entry line (gold)
  - SL line (red, dashed)
  - TP line (green, dashed)
  - Exit line (green/red, dotted)
  - Entry arrow (up/down)
  - Exit arrow (X mark)
  - Stats label on chart showing:
    - Trade ticket
    - Efficiency %
    - Profit ($)
    - Duration (minutes)
    - MFE/MAE (pips)

**Binding**: Loads trade history from account, displays visually on chart

## VPS Compatibility

### EnableUI Flag
All UI code checks `InpEnableUI` before executing:
- ✅ Set `InpEnableUI = false` for VPS deployment
- ✅ All GUI code is skipped (no ObjectCreate calls)
- ✅ Engine components run normally
- ✅ No chart objects created
- ✅ No OnChartEvent handlers execute

### Code Structure
```mql5
if(!m_enableUI) return;  // All GUI functions check this first
```

## Usage

### Local Development
```mql5
InpEnableUI = true
```
- Full UI functionality
- All tabs available
- Chart visualization active

### VPS Deployment
```mql5
InpEnableUI = false
```
- UI completely disabled
- Engine runs normally
- No GUI overhead

## UI Flow

```
OnInit()
  ├──► Initialize Engine (always)
  └──► Initialize UI Controller (if EnableUI=true)
       ├──► Create Header
       ├──► Create Tabs
       └──► Initialize Panels
            ├──► TradePanel
            ├──► ManagePanel
            ├──► GuardPanel
            └──► ReviewPanel

OnTick()
  ├──► Engine.Process() (always)
  └──► UI.Update() (if EnableUI=true)

OnChartEvent()
  └──► UI.OnChartEvent() (if EnableUI=true)
       └──► Active Panel.OnChartEvent()
```

## Panel Interactions

### Trade Panel
- User inputs: Volume, SL, TP, Risk %
- Calculates: Lot size, Trade value
- Executes: Buy/Sell orders via TradeManager

### Manage Panel
- User toggles: Auto BE, Auto Trailing, Guard Mode
- User inputs: BE points, BE offset, Trailing parameters
- Updates: BEManager, TrailingManager settings in real-time

### Guard Panel
- Displays: Current daily/weekly loss
- User toggles: Guard Mode, Notifications
- Monitors: DDGuard status

### Review Panel
- Loads: Trade history from account
- Displays: Trade statistics
- Visualizes: Each trade on chart with lines and stats
- Navigation: Previous/Next buttons

## Chart Visualization (Review Tab)

When viewing a trade:
1. **Entry Line**: Horizontal line at entry price (gold)
2. **SL Line**: Horizontal line at stop loss (red, dashed)
3. **TP Line**: Horizontal line at take profit (green, dashed)
4. **Exit Line**: Horizontal line at exit price (green if profit, red if loss, dotted)
5. **Entry Arrow**: Arrow at entry point (up for buy, down for sell)
6. **Exit Arrow**: X mark at exit point
7. **Stats Label**: Text box showing:
   - Trade ticket number
   - Efficiency percentage
   - Profit/Loss in $
   - Trade duration in minutes
   - MFE/MAE in pips

## Implementation Notes

1. **All UI code is conditional**: Every function checks `m_enableUI` or `InpEnableUI`
2. **No VPS dependencies**: Engine components have no GUI dependencies
3. **State rebuildable**: Review panel loads from history, no file dependencies
4. **Real-time updates**: Panels update on OnTick() when visible
5. **Clean separation**: UI code is completely isolated from Engine code

## File Structure

```
Include/GUI/
├── UIController.mqh    ← Main UI controller
├── Theme.mqh           ← Colors and styling
├── Panel.mqh           ← Base panel class
├── Controls.mqh        ← UI control helpers
├── TradePanel.mqh      ← Trade tab
├── ManagePanel.mqh     ← Manage tab
├── GuardPanel.mqh      ← Guard tab
└── ReviewPanel.mqh     ← Review tab (with chart viz)
```

## Testing Checklist

- [ ] UI displays correctly with `InpEnableUI = true`
- [ ] All tabs switch correctly
- [ ] Trade panel executes trades
- [ ] Manage panel updates Engine settings
- [ ] Guard panel shows correct loss limits
- [ ] Review panel loads and displays trades
- [ ] Chart visualization shows correctly
- [ ] Previous/Next navigation works
- [ ] UI is completely disabled with `InpEnableUI = false`
- [ ] Engine runs normally on VPS (EnableUI=false)

## Future Enhancements

- Add drag-and-drop panel positioning
- Add more detailed trade statistics
- Add trade filtering in Review tab
- Add export functionality for trade history
- Add more visual indicators in Review tab
