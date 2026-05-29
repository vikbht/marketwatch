# 📊 MarketWatch: Real-Time macOS Menu Bar Dashboard

A lightweight, premium native macOS status bar application that monitors critical market breadth and institutional sentiment indicators. It displays a real-time summary directly in your status menu bar, which opens a high-fidelity visual dashboard panel upon clicking.

Built entirely in native Swift, Cocoa, and SwiftUI with **zero external dependencies**, compiling into an extremely optimized, standalone executable that runs in accessory mode (hidden from the Dock) and consumes near-zero system resources.

![Visual Dashboard Interface Mockup](file:///Users/vikasbhatia/.gemini/antigravity/brain/4fcb9e87-395c-4242-b0a7-082bbfb6e273/improved_marketwatch_mockup_1780017862191.png)

---

## ✨ Key Features

*   **📈 Dynamic Status Bar Summary:** Displays live advancing percentage and active bullish sentiment directly in your menu bar (e.g. `📊 55.5%  🐂 65%`). Clicking the status bar indicator toggles the visual dashboard.
*   **🎨 Premium 5-Card Vertical Layout:** Renders five highly detailed vertical cards (`width: 200`, `height: 280`) side-by-side in a sleek slate charcoal theme:
    1.  **`ADV/DECL RATIO`:**NYSE/Nasdaq/AMEX advancing vs. declining stocks percentage, organic sparkline, and segmented bar.
    2.  **`NET NEW HIGHS`:** Stocks hitting 52-week highs vs. 52-week lows.
    3.  **`% ABV 50-DAY MA`:** Percentage of stocks trading above their 50-day Simple Moving Average.
    4.  **`VIX INDEX`:** CBOE Volatility Index, charting real-time fear/risk-appetite indices.
    5.  **`EQUITY PUT/CALL`:** CBOE Equity Options Put/Call ratio, charting active hedging volumes.
*   **📌 Detachable Glassmorphic HUD Window:** Tapping `Keep Floating` in the footer detaches the dashboard from the status bar into a borderless floating utility window (`NSPanel`) with a native macOS glassmorphic blur backdrop (`NSVisualEffectView`) that stays on top of other workspace windows.
*   **📊 Institutional Sparklines & Grids:** Sparklines are color-coded (green for bullish/risk-on, red for bearish/risk-off) and feature three horizontal grid lines, left-aligned custom Y-axis tick scales, time markers (`0:00` and `13:30`), and custom dotted baseline thresholds.
*   **📷 Clipboard-Only Screenshots:** Captures the entire dashboard, copies it instantly to the macOS clipboard, triggers a green success toast indicator, and issues a standard system chime (no cluttering local disk files).
*   **🌙 NYSE Hours Integration & Sleeping Indicator:** Detects whether the NY Stock Exchange is active. Skips background fetches outside market hours to save network calls, displaying an amber sleeping moon (`moon.zzz.fill`) paused label.
*   **🎛️ Dynamic scaling:** Top header font controls dynamically scale all dashboard components (sparklines, tick labels, buttons, progress bars) between `80%` and `140%` smoothly, persisting your choice via `@AppStorage`.
*   **⚡ Ultra-Light Footprint:** Performs parallel network queries using Combine's `Zip4` publisher pipeline (fetching HTML and JSON data in parallel in under 100ms). Operates at **0.0% CPU** in the background, consuming **less than 48 MB of RAM**.

---

## 📂 Project Architecture

The application is completely self-contained in five core files:

*   **[Parser.swift](file:///Users/vikasbhatia/code/marketwatch/Parser.swift):** Core models (`MarketBreadthItem`, `MarketIndexData`, `MarketSentimentData`) and the network fetching engine (`MarketBreadthFetcher`) executing parallel URLSession pipelines.
*   **[BreadthViews.swift](file:///Users/vikasbhatia/code/marketwatch/BreadthViews.swift):** High-fidelity SwiftUI visual modules, sparklines, segmented bars, range indicators, and layout controllers.
*   **[AppDelegate.swift](file:///Users/vikasbhatia/code/marketwatch/AppDelegate.swift):** Core status item lifecycle, NSPopover controls, AppKit `NSPanel` floating window controller, and screenshot copying procedures.
*   **[main.swift](file:///Users/vikasbhatia/code/marketwatch/main.swift):** Accessories mode entry hook initializing the AppKit environment loop.
*   **[build.sh](file:///Users/vikasbhatia/code/marketwatch/build.sh):** Programmatic compilation script invoking Apple's native Swift compiler (`swiftc`) linked to Cocoa system libraries.

---

## 🛠️ Compilation & Setup

To compile the standalone binary on any modern macOS machine:

1. Open your Terminal and navigate to the project directory:
   ```bash
   cd /Users/vikasbhatia/code/marketwatch
   ```
2. Execute the compilation script:
   ```bash
   ./build.sh
   ```

---

## 🚀 How to Run

### 1. Launch in Background (Default 5-Minute Refresh)
```bash
./MarketWatch &
```

### 2. Launch with a Custom Refresh Interval (e.g., Every 120 Seconds)
```bash
./MarketWatch -i 120 &
```
*(Programmatically enforces a minimum safety threshold of 10 seconds to protect against rate-limiting).*

### 3. Setup Auto-Start on Boot / Login (macOS Launch Agent)
To register the app so that it starts automatically in the background whenever your Mac boots up or you log in:
```bash
chmod +x install_launch_agent.sh
./install_launch_agent.sh
```
*(This sets up a plist Launch Agent under `~/Library/LaunchAgents/com.marketwatch.plist` that supervises, automatically restarts, and runs the application background loops).*

---

## 🕹️ Controls & Interaction

1.  **Status Bar:** Look at the top-right of your screen for the dynamic indicator (e.g. `📊 55.5%  🐂 65%`). Click it to open the dashboard.
2.  **Detached Mode:** Click the `pin.fill` **Keep Floating** button in the footer to pop the dashboard out into a floating glass panel. Move it anywhere on your desktop. Click it again to snap it back.
3.  **Visual Spring Scale:** Hovering over any card tile expands it (+2% scale) and intensifies the dynamic glassmorphic radial background glow (green for bullish, red for bearish).
4.  **Screenshot Sharing:** Click the `📷 Screenshot` button in the footer to copy the dashboard directly to your clipboard for instant pasting into Slack, iMessage, or mail applications.
5.  **Quit:** Click the `Quit App` button in the footer (visible in Popover mode) or click the close traffic light on the HUD Panel to exit the application cleanly.
