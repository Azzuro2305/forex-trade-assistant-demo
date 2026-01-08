# ForexTradeAssistant - VPS-Compatible Refactoring Summary

## Overview
The entire project has been refactored to be fully VPS-compatible using an `EnableUI` flag. The structure now clearly separates VPS-safe Engine code from Local-only GUI/Review code.

## New Folder Structure

```
ForexTradeAssistant.mqproj
│
├─ Headers
│   └─ Include
│       ├─ Config
│       │   ├─ Inputs.mqh          ← EA Input Parameters (VPS-safe)
│       │   └─ RuntimeConfig.mqh   ← Runtime Configuration (VPS-safe)
│       │
│       ├─ Core                    ← Basic Utilities (VPS-safe)
│       │   ├─ MathRisk.mqh        ← Risk calculation utilities
│       │   ├─ SymbolUtils.mqh    ← Symbol and price utilities
│       │   ├─ TimeUtils.mqh       ← Time and bar utilities
│       │   └─ Logger.mqh         ← Logging utilities
│       │
│       ├─ Engine                  ← VPS-SAFE ONLY
│       │   ├─ Engine.mqh          ← Main engine controller
│       │   ├─ RiskManager.mqh    ← Risk management
│       │   ├─ TradeManager.mqh   ← Order management
│       │   ├─ Strategy.mqh       ← Trading strategy logic
│       │   ├─ BEManager.mqh      ← Break Even manager
│       │   ├─ TrailingManager.mqh ← Trailing stop manager
│       │   ├─ DDGuard.mqh        ← Drawdown guard
│       │   └─ TradeEvents.mqh    ← Trade event handler
│       │
│       ├─ Storage                 ← OPTIONAL, NON-CRITICAL
│       │   ├─ StateModel.mqh      ← State model (optional)
│       │   └─ StateRebuild.mqh   ← State rebuild utilities (optional)
│       │
│       ├─ GUI                     ← LOCAL ONLY
│       │   ├─ TradingPanel.mqh   ← Trading panel UI
│       │   ├─ VisualTradeLines.mqh ← Visual trade lines
│       │   └─ VisualTradeManager.mqh ← Visual trade manager
│       │
│       ├─ Review                  ← LOCAL ONLY
│       │   ├─ HistoryParser.mqh  ← Trade history parser
│       │   ├─ TradeGrouper.mqh   ← Trade grouping utilities
│       │   ├─ TradeStats.mqh     ← Trade statistics
│       │   └─ ReviewUI.mqh       ← Review UI
│       │
│       ├─ Chart                   ← LOCAL ONLY
│       │   ├─ DrawManager.mqh    ← Chart drawing manager
│       │   └─ ObjectNames.mqh    ← Object naming utilities
│       │
│       └─ Utils
│           └─ Helpers.mqh        ← General helper functions
│
├─ Sources
│   └─ ForexTradeAssistant.mq5   ← Main EA file
│
└─ Resources
    ├─ Icons
    └─ Fonts
```

## Key Changes

### 1. Configuration (Config/)
- **Inputs.mqh**: All EA input parameters, including new `InpEnableUI` flag
- **RuntimeConfig.mqh**: Runtime configuration class that manages UI state

### 2. Core Utilities (Core/)
- **MathRisk.mqh**: Risk calculation functions (lot sizing, risk amounts)
- **SymbolUtils.mqh**: Symbol and price utilities (normalize, convert points)
- **TimeUtils.mqh**: Time and bar utilities (new bar detection, market hours)
- **Logger.mqh**: Logging utilities

### 3. Engine (Engine/) - VPS-SAFE ONLY
All Engine components follow strict VPS rules:
- ❌ NO `ObjectCreate`
- ❌ NO `OnChartEvent`
- ❌ NO GUI calls
- ✅ Only `OnTick`, `OnTimer`, `OnTradeTransaction`

**Components:**
- **Engine.mqh**: Main controller that orchestrates all engine components
- **RiskManager.mqh**: Risk management and lot size calculation
- **TradeManager.mqh**: Order execution and position management
- **Strategy.mqh**: Trading strategy logic
- **BEManager.mqh**: Break Even management (moves SL to BE when profit reached)
- **TrailingManager.mqh**: Trailing stop management
- **DDGuard.mqh**: Drawdown guard (halts trading if DD limit exceeded)
- **TradeEvents.mqh**: Handles `OnTradeTransaction` events

### 4. GUI (GUI/) - LOCAL ONLY
All GUI components check `InpEnableUI` before executing:
- **TradingPanel.mqh**: Trading control panel
- **VisualTradeLines.mqh**: Draggable visual trade lines
- **VisualTradeManager.mqh**: Visual trading manager

### 5. Optional Components
- **Storage/**: Optional state management (non-critical)
- **Review/**: Trade review and analysis (local only)
- **Chart/**: Chart drawing utilities (local only)

## VPS Compatibility

### How It Works
1. **EnableUI Flag**: Set `InpEnableUI = false` for VPS deployment
2. **Conditional Execution**: GUI code checks `InpEnableUI` before executing
3. **Engine Always Runs**: Engine components run regardless of UI state
4. **State Rebuildable**: Engine can rebuild state from open positions (no file dependencies)

### VPS Deployment Checklist
- ✅ Set `InpEnableUI = false` in input parameters
- ✅ Engine components will run normally
- ✅ GUI components will skip all execution
- ✅ No chart objects will be created
- ✅ No `OnChartEvent` handlers will execute
- ✅ State rebuilds from open positions on restart

## Migration Notes

### Old Files (Can be removed)
- `Include/Config/Settings.mqh` → Replaced by `Inputs.mqh` and `RuntimeConfig.mqh`
- `Include/Core/RiskManager.mqh` → Moved to `Include/Engine/RiskManager.mqh`
- `Include/Core/TradeManager.mqh` → Moved to `Include/Engine/TradeManager.mqh`
- `Include/Core/Strategy.mqh` → Moved to `Include/Engine/Strategy.mqh`
- `Include/Utils/Utils.mqh` → Split into `Core/` utilities and `Utils/Helpers.mqh`

### Breaking Changes
- All includes have been updated to new paths
- `InpVPSMode` replaced with `InpEnableUI`
- Utility functions now require symbol parameter (optional, defaults to `_Symbol`)

## Usage

### Local Development (with UI)
```mql5
InpEnableUI = true
InpEnableVisualTrading = true
```

### VPS Deployment (no UI)
```mql5
InpEnableUI = false
InpEnableVisualTrading = false  // Ignored if EnableUI=false
```

## Engine Features

### Break Even Manager
- Moves stop loss to break even when profit reaches threshold
- Configurable via `SetBEParameters(bePoints, beOffset)`

### Trailing Stop Manager
- Trails stop loss as price moves in favor
- Configurable via `SetTrailingParameters(start, step, stop)`

### Drawdown Guard
- Monitors account drawdown
- Halts trading if max drawdown exceeded
- Resumes when drawdown recovers
- Configurable via `SetMaxDrawdownPercent(percent)`

## Testing

1. **Local Testing**: Run with `InpEnableUI = true` to test GUI
2. **VPS Testing**: Run with `InpEnableUI = false` to verify VPS compatibility
3. **State Recovery**: Restart EA and verify it rebuilds state from positions

## Notes

- All Engine code is VPS-safe and follows MetaQuotes VPS guidelines
- GUI code is completely isolated and will not execute on VPS
- State is rebuildable from open positions (no file dependencies)
- The structure is scalable and maintainable
