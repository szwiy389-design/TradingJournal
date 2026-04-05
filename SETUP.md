# Futures Trading Journal – iOS App

A native SwiftUI trading journal app for futures day traders.

## Requirements
- Xcode 15+
- iOS 17+ target (uses SwiftData)

## Xcode Setup

1. Open Xcode → **File → New → Project**
2. Choose **iOS → App**
3. Set:
   - Product Name: `TradingJournal`
   - Interface: `SwiftUI`
   - Language: `Swift`
   - Storage: **None** (SwiftData is added manually)
4. Click **Next** and save anywhere

5. Delete the auto-generated `ContentView.swift` (move to Trash)

6. In Finder, drag all files from this folder into your Xcode project:
   - `TradingJournalApp.swift`
   - `Models/Trade.swift`
   - `Models/DailyJournal.swift`
   - `Views/ContentView.swift`
   - `Views/Dashboard/DashboardView.swift`
   - `Views/Trades/TradeListView.swift`
   - `Views/Trades/TradeRowView.swift`
   - `Views/Trades/AddTradeView.swift`
   - `Views/Trades/TradeDetailView.swift`
   - `Views/Journal/JournalListView.swift`
   - `Views/Journal/DailyJournalView.swift`
   - `Views/Settings/SettingsView.swift`
   - `Helpers/StatsCalculator.swift`
   - `Extensions/Double+Extensions.swift`

   When prompted: check **Copy items if needed** and **Add to target**.

7. Build & run (Cmd+R) on Simulator or device.

## Features

### Dashboard
- Net P&L with period filter (Today / Week / Month / All Time)
- Win Rate, Profit Factor, Avg Win/Loss, Expectancy, Max Drawdown
- Equity curve chart
- Daily P&L bar chart
- Setup performance breakdown

### Trades
- Log trades with full details
- Instruments: ES, NQ, YM, RTY, CL, GC, SI, ZB, ZN, NG + Custom
- Auto P&L calculation using correct tick multipliers
- Trade grades (A+ → F), setups, emotions
- Stop loss / take profit / R:R ratio
- Duration tracking
- Grouped by date with daily P&L

### Journal
- Pre-market: market bias, key levels, trading plan
- Post-market: review, lessons learned
- Mental state slider
- Linked day trades summary

### Settings
- Default instrument / contracts / commission
- Account balance + return %
- Export all trades as CSV
- Delete all data

## Instrument Multipliers

| Symbol | Name             | Multiplier  |
|--------|------------------|-------------|
| ES     | E-mini S&P 500   | $50/point   |
| NQ     | E-mini Nasdaq    | $20/point   |
| YM     | E-mini Dow       | $5/point    |
| RTY    | E-mini Russell   | $10/point   |
| CL     | Crude Oil        | $1,000/pt   |
| GC     | Gold             | $100/point  |
| SI     | Silver           | $5,000/pt   |
| ZB     | 30yr T-Bond      | $1,000/pt   |
| ZN     | 10yr T-Note      | $1,000/pt   |
| NG     | Natural Gas      | $10,000/pt  |
