import SwiftUI

// Premium theme colors matching the visual mockup perfectly
struct MarketTheme {
    static let background = Color(red: 0.10, green: 0.11, blue: 0.14) // Sleek slate charcoal
    static let cardBackground = Color(red: 0.14, green: 0.16, blue: 0.20) // Rich dark card background
    static let border = Color(red: 0.18, green: 0.21, blue: 0.26) // Thin clean border
    static let greenText = Color(red: 0.22, green: 0.82, blue: 0.49) // Vibrant emerald green
    static let redText = Color(red: 0.95, green: 0.36, blue: 0.41) // Gorgeous coral red
    static let centerBar = Color(red: 0.28, green: 0.32, blue: 0.38) // Neutral grey
    static let labelSecondary = Color(red: 0.55, green: 0.58, blue: 0.64) // Premium secondary gray
    static let amberText = Color(red: 0.95, green: 0.60, blue: 0.15) // Standby gold/amber
}

// Compact horizontal breadth card representing a single progress-bar metric
struct SimpleBreadthCardView: View {
    let item: MarketBreadthItem
    let fontSizeScale: Double
    
    @State private var isHovered = false
    @State private var animateBar = false
    
    var body: some View {
        let greenColor = MarketTheme.greenText
        let redColor = MarketTheme.redText
        
        VStack(alignment: .leading, spacing: 6) {
            // 1. Top row: Left Label, optional Center Title, Right Label
            HStack {
                Text(item.leftLabel)
                    .font(.system(size: 11 * fontSizeScale, weight: .bold, design: .rounded))
                    .foregroundColor(greenColor)
                
                if item.title.contains("SMA50") || item.title.contains("SMA 50") {
                    Spacer()
                    Text("SMA50")
                        .font(.system(size: 10 * fontSizeScale, weight: .bold, design: .rounded))
                        .foregroundColor(MarketTheme.labelSecondary)
                    Spacer()
                } else if item.title.contains("SMA200") || item.title.contains("SMA 200") {
                    Spacer()
                    Text("SMA200")
                        .font(.system(size: 10 * fontSizeScale, weight: .bold, design: .rounded))
                        .foregroundColor(MarketTheme.labelSecondary)
                    Spacer()
                } else {
                    Spacer()
                }
                
                Text(item.rightLabel)
                    .font(.system(size: 11 * fontSizeScale, weight: .bold, design: .rounded))
                    .foregroundColor(redColor)
            }
            
            // 2. Second row: values (e.g. "40.9% (2284)" and "(3071) 54.9%")
            HStack {
                Text(item.leftValue)
                    .font(.system(size: 10.5 * fontSizeScale, weight: .semibold, design: .monospaced))
                    .foregroundColor(greenColor)
                Spacer()
                Text(item.rightValue)
                    .font(.system(size: 10.5 * fontSizeScale, weight: .semibold, design: .monospaced))
                    .foregroundColor(redColor)
            }
            
            // 3. Third row: Segmented horizontal capsule bar
            GeometryReader { geo in
                let totalWidth = geo.size.width
                let greenWidth = totalWidth * CGFloat(item.leftBarPercent / 100.0)
                let greyWidth = totalWidth * CGFloat(item.centerBarPercent / 100.0)
                let redWidth = totalWidth * CGFloat(item.rightBarPercent / 100.0)
                
                HStack(spacing: 0) {
                    if greenWidth > 0 {
                        Rectangle()
                            .fill(greenColor)
                            .frame(width: animateBar ? greenWidth : 0)
                    }
                    if greyWidth > 0 {
                        Rectangle()
                            .fill(MarketTheme.centerBar)
                            .frame(width: animateBar ? greyWidth : 0)
                    }
                    if redWidth > 0 {
                        Rectangle()
                            .fill(redColor)
                            .frame(width: animateBar ? redWidth : 0)
                    }
                }
                .clipShape(Capsule())
                .animation(.spring(response: 0.6, dampingFraction: 0.75, blendDuration: 0), value: animateBar)
            }
            .frame(height: 5)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .frame(height: 62)
        .background(MarketTheme.cardBackground)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isHovered ? greenColor.opacity(0.35) : MarketTheme.border, lineWidth: 1.0)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .shadow(color: isHovered ? greenColor.opacity(0.1) : Color.black.opacity(0.1), radius: isHovered ? 4 : 2)
        .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.6, blendDuration: 0), value: isHovered)
        .onAppear {
            self.animateBar = true
        }
        .onHover { hovering in
            self.isHovered = hovering
        }
    }
}

// Compact row grid responsive visual layout container
public struct BreadthDashboardView: View {
    @ObservedObject var fetcher: MarketBreadthFetcher
    @AppStorage("fontSizeScale") private var fontSizeScale: Double = 1.0
    @State private var showScreenshotToast = false
    
    var isWindowMode: Bool = false
    
    public init(fetcher: MarketBreadthFetcher, isWindowMode: Bool = false) {
        self.fetcher = fetcher
        self.isWindowMode = isWindowMode
    }
    
    public var body: some View {
        VStack(spacing: 10) {
            // Header Bar (Large, clean header with control adjustments on the right)
            HStack {
                Text("MARKET BREADTH")
                    .font(.system(size: 16, weight: .bold, design: .default))
                    .foregroundColor(.white)
                    .tracking(0.5)
                
                Spacer()
                
                // Font Size Adjuster Control Group
                HStack(spacing: 4) {
                    Button(action: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            fontSizeScale = max(0.8, fontSizeScale - 0.1)
                        }
                    }) {
                        Image(systemName: "textformat.size.smaller")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(MarketTheme.labelSecondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Decrease Font Size")
                    
                    Text("\(Int(fontSizeScale * 100))%")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(MarketTheme.labelSecondary.opacity(0.8))
                        .frame(width: 32)
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            fontSizeScale = min(1.4, fontSizeScale + 0.1)
                        }
                    }) {
                        Image(systemName: "textformat.size.larger")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(MarketTheme.labelSecondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Increase Font Size")
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(MarketTheme.cardBackground.opacity(0.6))
                )
                .padding(.trailing, 6)
                
                if fetcher.isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 14, height: 14)
                } else {
                    Button(action: {
                        fetcher.fetch()
                    }) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(MarketTheme.labelSecondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Last updated timestamp
                if let lastUpdated = fetcher.lastUpdated {
                    Text(formatTime(lastUpdated))
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(MarketTheme.labelSecondary)
                }
            }
            .padding(.horizontal, 4)
            
            // Row 1: Horizontal row of 4 horizontal cards side-by-side
            HStack(spacing: 12) {
                if fetcher.items.count >= 4 {
                    ForEach(0..<4, id: \.self) { idx in
                        SimpleBreadthCardView(
                            item: fetcher.items[idx],
                            fontSizeScale: fontSizeScale
                        )
                    }
                } else {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: 62)
                }
            }
            
            // Row 2: Finviz S&P 500 Sector Heatmap Card (Spanning full width)
            VStack(alignment: .leading, spacing: 6) {
                Text("S&P 500 SECTOR HEATMAP")
                    .font(.system(size: 11 * fontSizeScale, weight: .bold, design: .rounded))
                    .foregroundColor(MarketTheme.labelSecondary)
                    .padding(.horizontal, 4)
                    .padding(.top, 2)
                
                FinvizMapView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .cornerRadius(4)
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .frame(height: 680)
            .background(MarketTheme.cardBackground)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(MarketTheme.border, lineWidth: 1.0)
            )
            
            // Subtle footer / status message
            HStack {
                if showScreenshotToast {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(MarketTheme.greenText)
                        Text("Screenshot copied to clipboard!")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(MarketTheme.greenText)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else if fetcher.isPausedOutsideMarketHours {
                    HStack(spacing: 4) {
                        Image(systemName: "moon.zzz.fill")
                            .foregroundColor(MarketTheme.amberText)
                        Text("Paused (Outside NY Market Hours)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(MarketTheme.amberText)
                    }
                } else if let errMsg = fetcher.errorMessage {
                    Text("⚠️ \(errMsg)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(MarketTheme.redText)
                } else {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(MarketTheme.greenText)
                            .frame(width: 6, height: 6)
                        Text("Active • Source: finviz.com (Real-Time)")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(MarketTheme.greenText.opacity(0.85))
                    }
                }
                Spacer()
                
                // Keep Floating Pin Button
                Button(action: {
                    NotificationCenter.default.post(name: Notification.Name("ToggleHUDWindow"), object: nil)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isWindowMode ? "pin.slash.fill" : "pin.fill")
                            .font(.system(size: 9))
                        Text(isWindowMode ? "Unpin Window" : "Keep Floating")
                    }
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(MarketTheme.amberText.opacity(0.9))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(MarketTheme.amberText.opacity(0.35), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.trailing, 4)
                
                // Screenshot Button
                Button(action: {
                    NotificationCenter.default.post(name: Notification.Name("TakeScreenshot"), object: nil)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        self.showScreenshotToast = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            self.showScreenshotToast = false
                        }
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 9))
                        Text("Screenshot")
                    }
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(MarketTheme.greenText.opacity(0.9))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(MarketTheme.greenText.opacity(0.35), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.trailing, 4)
                
                // Quit App Button (Hidden in floating window mode)
                if !isWindowMode {
                    Button(action: {
                        NSApplication.shared.terminate(nil)
                    }) {
                        Text("Quit App")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(MarketTheme.redText.opacity(0.85))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(MarketTheme.redText.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(12)
        .frame(width: 1200, height: 860)
        .background(MarketTheme.background)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}
