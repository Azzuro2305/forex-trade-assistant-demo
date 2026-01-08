# Visual Trading System - User Guide

## Overview

The Visual Trading System provides an intuitive GUI interface for placing trades directly on the chart with visual entry, TP, and SL lines. The system works both with GUI (for desktop) and without GUI (VPS mode).

## Features

✅ **Visual Trading Lines**
- Draggable entry, TP, and SL lines on chart
- Real-time lot size calculation based on risk
- Input boxes for exact price/point entry
- Automatic order type detection (market/limit/stop)

✅ **Risk Management Panel**
- Three risk calculation modes:
  - **Currency**: Risk a fixed amount (e.g., $10)
  - **Percentage**: Risk a percentage of balance (e.g., 2%)
  - **Fixed Volume**: Use fixed lot size (e.g., 0.01)

✅ **VPS Compatible**
- Works on MT5 VPS without GUI
- All functionality available via input parameters

## How to Use

### 1. Enable Visual Trading

In EA settings:
- Set `Enable Visual Trading` = `true`
- Set `VPS Mode` = `false` (for desktop) or `true` (for VPS)

### 2. Using the Control Panel

The control panel appears on the left side of your chart with:

**Buttons:**
- **BUY**: Creates buy setup with entry, TP, and SL lines
- **SELL**: Creates sell setup with entry, TP, and SL lines
- **Close All**: Closes all positions opened by this EA
- **Clear Lines**: Removes all visual lines from chart
- **EXECUTE TRADE**: Executes the trade based on current line positions

**Risk Mode Selection:**
- **Currency ($)**: Enter risk amount in account currency
- **Percent (%)**: Enter risk as percentage of balance
- **Fixed Lot**: Enter fixed lot size directly

**Risk Input Box:**
- Enter your desired risk value based on selected mode
- Lot size updates automatically when you drag lines

### 3. Working with Visual Lines

#### Creating a Setup

1. Click **BUY** or **SELL** button
2. Three lines appear on chart:
   - **Entry Line** (Blue for Buy, Red for Sell)
   - **TP Line** (Green)
   - **SL Line** (Red)

#### Dragging Lines

- **Click and drag** any line to adjust its position
- Lot size **automatically recalculates** based on:
  - Selected risk mode
  - Risk amount
  - Stop loss distance

#### Input Boxes

Each line has an input box on the right side:
- **Enter exact price**: Type the price directly (e.g., `1.08500`)
- **Enter points**: Type `p50` or `P50` for 50 points from entry
  - For TP: `p100` means 100 points above entry (buy) or below (sell)
  - For SL: `p50` means 50 points below entry (buy) or above (sell)

#### Order Type Detection

The system automatically detects order type:
- **Market Order**: Entry line is at or very close to current price
- **Buy Limit**: Entry line is below current price (for buy)
- **Buy Stop**: Entry line is above current price (for buy)
- **Sell Limit**: Entry line is above current price (for sell)
- **Sell Stop**: Entry line is below current price (for sell)

### 4. Executing Trades

**Method 1: Button**
- Click **EXECUTE TRADE** button in panel

**Method 2: Keyboard**
- Press **Enter** key to execute trade
- Press **Escape** key to clear lines

### 5. Example Workflow

**Example: Buy Trade with 2% Risk**

1. Click **BUY** button
2. Entry line appears at current ASK price
3. TP line is 100 points above (default)
4. SL line is 50 points below (default)
5. Select **Percent (%)** mode
6. Enter `2.0` in risk input box
7. Drag SL line to desired position (e.g., 75 points)
8. Lot size automatically updates
9. Press **Enter** or click **EXECUTE TRADE**
10. Trade is executed with calculated lot size

**Example: Sell Trade with $10 Risk**

1. Click **SELL** button
2. Select **Currency ($)** mode
3. Enter `10` in risk input box
4. Drag entry line to desired limit price
5. Adjust TP and SL lines
6. Press **Enter** to execute

## Settings Explained

### Visual Trading Settings

- **Enable Visual Trading**: Turn visual trading on/off
- **VPS Mode**: Enable for VPS (disables GUI, uses input parameters)
- **Panel X/Y Position**: Control panel position on chart
- **Line Colors**: Customize colors for Buy/Sell/TP/SL lines
- **Line Width**: Thickness of visual lines
- **Line Style**: Solid, dashed, etc.

### Risk Management

The system respects these risk limits:
- **Max Daily Loss**: Stops trading if daily loss exceeds this %
- **Max Open Positions**: Limits number of concurrent positions
- **Risk Per Trade**: Default risk percentage (used if panel not available)

## VPS Mode

When `VPS Mode = true`:
- GUI panel is not displayed
- Visual lines are not shown
- All trading uses input parameters
- Risk calculation uses `InpRiskPercent` setting
- EA works normally for automated trading

## Tips & Best Practices

1. **Always check lot size** before executing
2. **Verify SL/TP distances** match your strategy
3. **Use input boxes** for precise price entry
4. **Test on demo** before live trading
5. **Monitor account info** panel for balance/equity updates

## Troubleshooting

**Lines not appearing?**
- Check `Enable Visual Trading` is `true`
- Check `VPS Mode` is `false`
- Ensure chart is not minimized

**Lot size not updating?**
- Make sure SL line is set (required for calculation)
- Check risk input value is valid
- Verify risk mode is selected

**Trade not executing?**
- Check if daily loss limit reached
- Verify max positions not exceeded
- Check account has sufficient margin
- Review logs for error messages

## Keyboard Shortcuts

- **Enter**: Execute trade
- **Escape**: Clear all visual lines

## Technical Details

### Lot Size Calculation

**Currency Mode:**
```
Lot Size = Risk Amount / (SL Points × Point Value)
```

**Percentage Mode:**
```
Risk Amount = Balance × (Risk % / 100)
Lot Size = Risk Amount / (SL Points × Point Value)
```

**Fixed Mode:**
```
Lot Size = Fixed Value (normalized to broker requirements)
```

### Order Type Logic

- If entry price = current price ± 10 points → Market Order
- If entry price > current price (Buy) → Buy Stop
- If entry price < current price (Buy) → Buy Limit
- If entry price < current price (Sell) → Sell Stop
- If entry price > current price (Sell) → Sell Limit

---

**Enjoy trading with the Visual Trading System!**
