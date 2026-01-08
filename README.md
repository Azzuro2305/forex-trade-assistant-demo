# ForexTradeAssistant - Expert Advisor

A modular, production-ready MetaTrader 5 Expert Advisor for forex trading.

## Project Structure

```
ForexTradeAssistant/
├── ForexTradeAssistant.mq5          # Main EA file
├── ForexTradeAssistant.mqproj        # Project configuration
├── Include/                          # Header files (modules)
│   ├── Config/
│   │   └── Settings.mqh             # Configuration and input parameters
│   ├── Core/
│   │   ├── TradeManager.mqh         # Order management and execution
│   │   ├── RiskManager.mqh          # Risk management and position sizing
│   │   └── Strategy.mqh             # Trading strategy logic
│   ├── Indicators/
│   │   └── IndicatorHelper.mqh      # Technical indicator utilities
│   └── Utils/
│       ├── Logger.mqh                # Logging utilities
│       └── Utils.mqh                 # General utility functions
└── README.md                         # This file
```

## Module Overview

### Config/Settings.mqh
- Contains all input parameters (visible in EA settings)
- Configuration constants
- EA version and metadata

### Core/TradeManager.mqh
- Handles order opening (Buy/Sell)
- Position closing functionality
- Order management operations
- Uses MQL5 trade functions

### Core/RiskManager.mqh
- Calculates position size based on risk percentage
- Tracks daily loss limits
- Manages maximum open positions
- Risk-based lot sizing

### Core/Strategy.mqh
- Main trading strategy logic
- Market analysis
- Signal generation
- Integrates TradeManager and RiskManager

### Indicators/IndicatorHelper.mqh
- Wrapper for technical indicators (MA, RSI, MACD, etc.)
- Simplified indicator access
- Automatic handle management

### Utils/Logger.mqh
- Structured logging with levels (DEBUG, INFO, WARN, ERROR)
- Configurable log output
- Easy debugging and monitoring

### Utils/Utils.mqh
- Price and lot normalization
- Point value calculations
- New bar detection
- Spread calculations
- General helper functions

## Features

- ✅ Modular architecture for easy maintenance
- ✅ Comprehensive risk management
- ✅ Configurable trading parameters
- ✅ Structured logging system
- ✅ Position size calculation based on risk
- ✅ Daily loss limit protection
- ✅ Maximum position limits
- ✅ Clean separation of concerns

## Usage

1. Compile the EA in MetaEditor
2. Attach to a chart in MetaTrader 5
3. Configure input parameters in EA settings
4. Enable/disable trading as needed

## Customization

To implement your trading strategy:

1. Edit `Include/Core/Strategy.mqh`
2. Implement your signal logic in `AnalyzeAndTrade()`
3. Use `IndicatorHelper` for technical analysis
4. Adjust risk parameters in `Settings.mqh`

## Input Parameters

### General Settings
- **Magic Number**: Unique identifier for EA trades
- **Trade Comment**: Comment added to trades

### Trading Settings
- **Lot Size**: Default lot size (if not using risk-based sizing)
- **Slippage**: Maximum slippage in points
- **Stop Loss**: Default stop loss in points
- **Take Profit**: Default take profit in points

### Risk Management
- **Risk Per Trade**: Risk percentage per trade
- **Max Daily Loss**: Maximum daily loss percentage
- **Max Open Positions**: Maximum concurrent positions

### Strategy Settings
- **Timeframe**: Chart timeframe for analysis
- **Enable Trading**: Toggle trading on/off

## Notes

- All modules are designed to be reusable and maintainable
- The structure follows MQL5 best practices
- Easy to extend with additional indicators or strategies
- Production-ready error handling and logging
