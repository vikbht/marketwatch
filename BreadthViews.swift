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

// Vector sparkline chart with grids, dotted baseline, and left-aligned Y-axis ticks
struct BreadthSparklineChart: View {
    let points: [Double]
    let timestamps: [Date]
    let isBullish: Bool
    let yTicks: [String]
    let baselineYPercent: CGFloat? // optional baseline relative height (0.0 to 1.0)
    let fontSizeScale: Double
    
    private func getDayBreakIndices() -> [Int] {
        guard timestamps.count > 1 else { return [] }
        var indices: [Int] = []
        let calendar = Calendar.current
        for i in 1..<min(points.count, timestamps.count) {
            let prev = timestamps[i - 1]
            let curr = timestamps[i]
            if !calendar.isDate(prev, inSameDayAs: curr) {
                indices.append(i)
            }
        }
        return indices
    }
    
    private func formatDayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d" // e.g. "May 29"
        return "DAY BREAK - \(formatter.string(from: date).uppercased())"
    }
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            ZStack {
                // 3 Horizontal Grid lines (Top, Middle, Bottom)
                Path { path in
                    // Top line
                    path.move(to: CGPoint(x: 0, y: 4))
                    path.addLine(to: CGPoint(x: w, y: 4))
                    
                    // Middle line
                    path.move(to: CGPoint(x: 0, y: h / 2.0))
                    path.addLine(to: CGPoint(x: w, y: h / 2.0))
                    
                    // Bottom line
                    path.move(to: CGPoint(x: 0, y: h - 4))
                    path.addLine(to: CGPoint(x: w, y: h - 4))
                }
                .stroke(Color.white.opacity(0.06), style: StrokeStyle(lineWidth: 0.8, dash: [3, 3]))
                
                // Optional Baseline (e.g. 0% or 1.00)
                if let basePerc = baselineYPercent {
                    Path { path in
                        let y = h * basePerc
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: w, y: y))
                    }
                    .stroke(Color.white.opacity(0.18), style: StrokeStyle(lineWidth: 1.0, dash: [4, 2]))
                }
                
                // Y-axis ticks rendered on the left of the chart area
                VStack(alignment: .leading, spacing: 0) {
                    if yTicks.count >= 3 {
                        Text(yTicks[0])
                            .font(.system(size: 7 * fontSizeScale, weight: .bold, design: .monospaced))
                            .foregroundColor(MarketTheme.labelSecondary.opacity(0.8))
                        Spacer()
                        Text(yTicks[1])
                            .font(.system(size: 7 * fontSizeScale, weight: .bold, design: .monospaced))
                            .foregroundColor(MarketTheme.labelSecondary.opacity(0.8))
                        Spacer()
                        Text(yTicks[2])
                            .font(.system(size: 7 * fontSizeScale, weight: .bold, design: .monospaced))
                            .foregroundColor(MarketTheme.labelSecondary.opacity(0.8))
                    }
                }
                .frame(width: w, height: h, alignment: .topLeading)
                .padding(.leading, 2)
                .zIndex(1)
                
                // Day Breaks vertical dotted lines and tags
                let dayBreakIndices = getDayBreakIndices()
                ForEach(dayBreakIndices, id: \.self) { idx in
                    let x = w * CGFloat(idx) / CGFloat(max(1, points.count - 1))
                    
                    ZStack {
                        Path { path in
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: h))
                        }
                        .stroke(MarketTheme.amberText.opacity(0.35), style: StrokeStyle(lineWidth: 1.0, dash: [4, 4]))
                        
                        Text(formatDayLabel(timestamps[idx]))
                            .font(.system(size: 6.0 * fontSizeScale, weight: .bold, design: .rounded))
                            .foregroundColor(MarketTheme.amberText.opacity(0.8))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1.5)
                            .background(MarketTheme.background.opacity(0.85))
                            .cornerRadius(3)
                            .rotationEffect(.degrees(-90))
                            .position(x: x, y: h / 2.0)
                    }
                }
                
                if points.count > 1 {
                    let minVal = points.min() ?? 0.0
                    let maxVal = points.max() ?? 100.0
                    let spread = max(1.0, maxVal - minVal)
                    
                    let strokeColor = isBullish ? MarketTheme.greenText : MarketTheme.redText
                    
                    // Glassmorphism background fill under the trend line
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: h))
                        let firstY = h - CGFloat((points[0] - minVal) / spread) * h
                        path.addLine(to: CGPoint(x: 0, y: firstY))
                        
                        for i in 1..<points.count {
                            let x = w * CGFloat(i) / CGFloat(points.count - 1)
                            let y = h - CGFloat((points[i] - minVal) / spread) * h
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                        path.addLine(to: CGPoint(x: w, y: h))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [strokeColor.opacity(0.25), Color.clear]),
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    
                    // High-fidelity main sparkline path
                    Path { path in
                        let firstY = h - CGFloat((points[0] - minVal) / spread) * h
                        path.move(to: CGPoint(x: 0, y: firstY))
                        
                        for i in 1..<points.count {
                            let x = w * CGFloat(i) / CGFloat(points.count - 1)
                            let y = h - CGFloat((points[i] - minVal) / spread) * h
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    .stroke(
                        strokeColor,
                        style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round)
                    )
                    .shadow(color: strokeColor.opacity(0.25), radius: 3, x: 0, y: 1)
                }
            }
        }
    }
}

// Vertical, narrow, and tall Breadth Card matching the screenshot perfectly
struct BreadthCardView: View {
    let title: String
    let item: MarketBreadthItem
    let historyPoints: [Double]
    let timestamps: [Date]
    let fontSizeScale: Double
    let yTicks: [String]
    let baselineYPercent: CGFloat?
    
    @State private var isHovered = false
    @State private var animateBar = false
    
    private func formatTime(_ date: Date?) -> String {
        guard let d = date else { return "--:--" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: d)
    }
    
    var body: some View {
        let isBullish = item.leftBarPercent >= item.rightBarPercent
        let glowColor = isBullish ? MarketTheme.greenText : MarketTheme.redText
        
        // Split title into two lines to match screenshot layout
        let titleComponents = title.components(separatedBy: " ")
        let line1 = titleComponents.first ?? title
        let line2 = titleComponents.dropFirst().joined(separator: " ")
        
        // Calculate dynamic delta from history
        let delta: Double = {
            guard historyPoints.count >= 2 else { return 0.0 }
            let last = historyPoints.last ?? 0.0
            let prev = historyPoints[historyPoints.count - 2]
            return last - prev
        }()
        
        VStack(alignment: .leading, spacing: 10) {
            // 1. Header Row (Title on Left, Values on Right)
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(line1)
                        .font(.system(size: 10 * fontSizeScale, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                    if !line2.isEmpty {
                        Text(line2)
                            .font(.system(size: 10 * fontSizeScale, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 1) {
                    Text("\(String(format: "%.1f", item.leftBarPercent))%")
                        .font(.system(size: 11 * fontSizeScale, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Text(delta >= 0.0 ? "+\(String(format: "%.1f", delta))%" : "\(String(format: "%.1f", delta))%")
                        .font(.system(size: 9.5 * fontSizeScale, weight: .bold, design: .rounded))
                        .foregroundColor(delta >= 0.0 ? MarketTheme.greenText : MarketTheme.redText)
                }
            }
            .frame(height: 30)
            .padding(.horizontal, 2)
            
            // 2. Sparkline Area with overlay Status Pill
            ZStack(alignment: .topLeading) {
                VStack(spacing: 4) {
                    BreadthSparklineChart(
                        points: historyPoints,
                        timestamps: timestamps,
                        isBullish: isBullish,
                        yTicks: yTicks,
                        baselineYPercent: baselineYPercent,
                        fontSizeScale: fontSizeScale
                    )
                    .frame(height: 120)
                    
                    // Time axis tick labels at the bottom of the chart
                    HStack {
                        Text(formatTime(timestamps.first))
                            .font(.system(size: 7 * fontSizeScale, weight: .bold, design: .monospaced))
                            .foregroundColor(MarketTheme.labelSecondary.opacity(0.5))
                        Spacer()
                        Text(formatTime(timestamps.last))
                            .font(.system(size: 7 * fontSizeScale, weight: .bold, design: .monospaced))
                            .foregroundColor(MarketTheme.labelSecondary.opacity(0.5))
                    }
                    .padding(.horizontal, 2)
                }
                
                // Bullish/Bearish small pill overlay
                Text(isBullish ? "Bullish" : "Bearish")
                    .font(.system(size: 7.5 * fontSizeScale, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(isBullish ? Color(red: 0.11, green: 0.38, blue: 0.22).opacity(0.85) : Color(red: 0.58, green: 0.16, blue: 0.18).opacity(0.85))
                    )
                    .offset(x: 45, y: 15)
            }
            
            Spacer().frame(height: 1)
            
            // 3. Segmented Capsule Progress Bar
            GeometryReader { geo in
                let totalWidth = geo.size.width
                let greenWidth = totalWidth * CGFloat(item.leftBarPercent / 100.0)
                let greyWidth = totalWidth * CGFloat(item.centerBarPercent / 100.0)
                let redWidth = totalWidth * CGFloat(item.rightBarPercent / 100.0)
                
                HStack(spacing: 0) {
                    if greenWidth > 0 {
                        Rectangle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [MarketTheme.greenText.opacity(0.85), MarketTheme.greenText]),
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(width: animateBar ? greenWidth : 0)
                    }
                    if greyWidth > 0 {
                        Rectangle()
                            .fill(MarketTheme.centerBar)
                            .frame(width: animateBar ? greyWidth : 0)
                    }
                    if redWidth > 0 {
                        Rectangle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [MarketTheme.redText, MarketTheme.redText.opacity(0.85)]),
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(width: animateBar ? redWidth : 0)
                }
            }
                .clipShape(Capsule())
                .animation(.spring(response: 0.6, dampingFraction: 0.75, blendDuration: 0), value: animateBar)
        }
            .frame(height: 6)
            .shadow(color: glowColor.opacity(0.2), radius: 2)
            
            // 4. Centered Bottom Bold Title
            HStack {
                Spacer()
                Text(title)
                    .font(.system(size: 9.5 * fontSizeScale, weight: .black, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                Spacer()
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .frame(width: 200, height: 280)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(MarketTheme.cardBackground)
                    .shadow(color: isHovered ? glowColor.opacity(0.12) : Color.black.opacity(0.15), radius: isHovered ? 8 : 4)
                
                // Subtle dynamic radial glow in bottom corner
                RadialGradient(
                    gradient: Gradient(colors: [glowColor.opacity(isHovered ? 0.15 : 0.06), Color.clear]),
                    center: .bottomLeading,
                    startRadius: 0,
                    endRadius: 110
                )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHovered ? glowColor.opacity(0.4) : MarketTheme.border, lineWidth: 1.0)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.6, blendDuration: 0), value: isHovered)
        .onAppear {
            self.animateBar = true
        }
        .onHover { hovering in
            self.isHovered = hovering
        }
    }
}

// Custom Index Card representing Volatility (VIX) and Put/Call Ratio in high fidelity
struct IndexCardView: View {
    let index: MarketIndexData
    let fontSizeScale: Double
    let yTicks: [String]
    let baselineYPercent: CGFloat?
    
    @State private var isHovered = false
    @State private var animateBar = false
    
    private func formatTime(_ date: Date?) -> String {
        guard let d = date else { return "--:--" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: d)
    }
    
    var body: some View {
        // VIX rising is bearish (red), falling is bullish (green). Same for Put/Call.
        let isBullish = index.priceChangePercent <= 0.0
        let glowColor = isBullish ? MarketTheme.greenText : MarketTheme.redText
        
        let titleComponents = index.title.components(separatedBy: " ")
        let line1 = titleComponents.first ?? index.title
        let line2 = titleComponents.dropFirst().joined(separator: " ")
        
        let delta = index.priceChangePercent
        
        VStack(alignment: .leading, spacing: 10) {
            // 1. Header Row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(line1)
                        .font(.system(size: 10 * fontSizeScale, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                    if !line2.isEmpty {
                        Text(line2)
                            .font(.system(size: 10 * fontSizeScale, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 1) {
                    Text(String(format: "%.2f", index.currentPrice))
                        .font(.system(size: 11 * fontSizeScale, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Text(delta >= 0.0 ? "+\(String(format: "%.1f", delta))%" : "\(String(format: "%.1f", delta))%")
                        .font(.system(size: 9.5 * fontSizeScale, weight: .bold, design: .rounded))
                        .foregroundColor(isBullish ? MarketTheme.greenText : MarketTheme.redText)
                }
            }
            .frame(height: 30)
            .padding(.horizontal, 2)
            
            // 2. Sparkline Area
            ZStack(alignment: .topLeading) {
                VStack(spacing: 4) {
                    BreadthSparklineChart(
                        points: index.historyPoints,
                        timestamps: index.historyTimestamps,
                        isBullish: isBullish,
                        yTicks: yTicks,
                        baselineYPercent: baselineYPercent,
                        fontSizeScale: fontSizeScale
                    )
                    .frame(height: 120)
                    
                    HStack {
                        Text(formatTime(index.historyTimestamps.first))
                            .font(.system(size: 7 * fontSizeScale, weight: .bold, design: .monospaced))
                            .foregroundColor(MarketTheme.labelSecondary.opacity(0.5))
                        Spacer()
                        Text(formatTime(index.historyTimestamps.last))
                            .font(.system(size: 7 * fontSizeScale, weight: .bold, design: .monospaced))
                            .foregroundColor(MarketTheme.labelSecondary.opacity(0.5))
                    }
                    .padding(.horizontal, 2)
                }
                
                // Status Pill (Risk-On / Risk-Off based on sentiment directional change)
                Text(isBullish ? "Risk-On" : "Risk-Off")
                    .font(.system(size: 7.5 * fontSizeScale, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(isBullish ? Color(red: 0.11, green: 0.38, blue: 0.22).opacity(0.85) : Color(red: 0.58, green: 0.16, blue: 0.18).opacity(0.85))
                    )
                    .offset(x: 45, y: 15)
            }
            
            Spacer().frame(height: 1)
            
            // 3. Capsule bar displaying relative index position inside standard ranges
            GeometryReader { geo in
                let totalWidth = geo.size.width
                let progress: CGFloat = {
                    if index.symbol == "^VIX" {
                        // VIX standard range: 10 to 30
                        return max(0, min(1.0, CGFloat((index.currentPrice - 10.0) / 20.0)))
                    } else {
                        // Put/Call ratio standard range: 0.4 to 1.2
                        return max(0, min(1.0, CGFloat((index.currentPrice - 0.4) / 0.8)))
                    }
                }()
                
                let fillWidth = totalWidth * progress
                
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [glowColor.opacity(0.85), glowColor]),
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: animateBar ? fillWidth : 0)
                    
                    Rectangle()
                        .fill(MarketTheme.centerBar)
                        .frame(width: totalWidth - (animateBar ? fillWidth : 0))
                }
                .clipShape(Capsule())
                .animation(.spring(response: 0.6, dampingFraction: 0.75, blendDuration: 0), value: animateBar)
            }
            .frame(height: 6)
            .shadow(color: glowColor.opacity(0.2), radius: 2)
            
            // 4. Centered Bottom Title
            HStack {
                Spacer()
                Text(index.title)
                    .font(.system(size: 9.5 * fontSizeScale, weight: .black, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                Spacer()
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .frame(width: 200, height: 280)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(MarketTheme.cardBackground)
                    .shadow(color: isHovered ? glowColor.opacity(0.12) : Color.black.opacity(0.15), radius: isHovered ? 8 : 4)
                
                RadialGradient(
                    gradient: Gradient(colors: [glowColor.opacity(isHovered ? 0.15 : 0.06), Color.clear]),
                    center: .bottomLeading,
                    startRadius: 0,
                    endRadius: 110
                )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHovered ? glowColor.opacity(0.4) : MarketTheme.border, lineWidth: 1.0)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.6, blendDuration: 0), value: isHovered)
        .onAppear {
            self.animateBar = true
        }
        .onHover { hovering in
            self.isHovered = hovering
        }
    }
}

// Sentiment specific line chart with vertical grid lines and custom gradients
struct SentimentLineChart: View {
    let points: [Double]
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let midY = h / 2.0
            
            let maxVal = points.map { abs($0) }.max() ?? 1.0
            let limit = max(maxVal, 4.0)
            
            // Grid X coordinates: Mon (15%), Tue (50%), Wed (85%)
            let gridX1 = w * 0.15
            let gridX2 = w * 0.50
            let gridX3 = w * 0.85
            
            ZStack {
                // Background grid lines (Vertical)
                Path { path in
                    path.move(to: CGPoint(x: gridX1, y: 0))
                    path.addLine(to: CGPoint(x: gridX1, y: h))
                    
                    path.move(to: CGPoint(x: gridX2, y: 0))
                    path.addLine(to: CGPoint(x: gridX2, y: h))
                    
                    path.move(to: CGPoint(x: gridX3, y: 0))
                    path.addLine(to: CGPoint(x: gridX3, y: h))
                }
                .stroke(style: StrokeStyle(lineWidth: 0.5, lineCap: .round, dash: [2, 2]))
                .foregroundColor(Color.white.opacity(0.08))
                
                // Horizontal neutral baseline
                Path { path in
                    path.move(to: CGPoint(x: 0, y: midY))
                    path.addLine(to: CGPoint(x: w, y: midY))
                }
                .stroke(style: StrokeStyle(lineWidth: 1.0, lineCap: .round, dash: [3, 2]))
                .foregroundColor(Color.white.opacity(0.18))
                
                if points.count > 1 {
                    // Draw Green Fill and Line (Above Baseline)
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: midY))
                        for i in 0..<points.count {
                            let x = w * CGFloat(i) / CGFloat(points.count - 1)
                            let val = points[i]
                            let clampedVal = max(0, val)
                            let y = midY - CGFloat(clampedVal / limit) * midY
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                        path.addLine(to: CGPoint(x: w, y: midY))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [MarketTheme.greenText.opacity(0.25), Color.clear]),
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    
                    Path { path in
                        let firstVal = max(0, points[0])
                        path.move(to: CGPoint(x: 0, y: midY - CGFloat(firstVal / limit) * midY))
                        for i in 1..<points.count {
                            let x = w * CGFloat(i) / CGFloat(points.count - 1)
                            let val = points[i]
                            let clampedVal = max(0, val)
                            let y = midY - CGFloat(clampedVal / limit) * midY
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    .stroke(MarketTheme.greenText, lineWidth: 2.0)
                    
                    // Draw Red Fill and Line (Below Baseline)
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: midY))
                        for i in 0..<points.count {
                            let x = w * CGFloat(i) / CGFloat(points.count - 1)
                            let val = points[i]
                            let clampedVal = min(0, val)
                            let y = midY - CGFloat(clampedVal / limit) * midY
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                        path.addLine(to: CGPoint(x: w, y: midY))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [MarketTheme.redText.opacity(0.25), Color.clear]),
                            startPoint: .bottom, endPoint: .top
                        )
                    )
                    
                    Path { path in
                        let firstVal = min(0, points[0])
                        path.move(to: CGPoint(x: 0, y: midY - CGFloat(firstVal / limit) * midY))
                        for i in 1..<points.count {
                            let x = w * CGFloat(i) / CGFloat(points.count - 1)
                            let val = points[i]
                            let clampedVal = min(0, val)
                            let y = midY - CGFloat(clampedVal / limit) * midY
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    .stroke(MarketTheme.redText, lineWidth: 2.0)
                }
            }
        }
    }
}

// Sentiment Specific Time axis labels (Mon, Tue, Wed)
struct SentimentTimeAxisLabelsView: View {
    let width: CGFloat
    let fontSizeScale: Double
    
    var body: some View {
        HStack(spacing: 0) {
            Text("Mon")
                .font(.system(size: 7 * fontSizeScale, weight: .bold, design: .rounded))
                .foregroundColor(MarketTheme.labelSecondary.opacity(0.5))
            Spacer()
            Text("Tue")
                .font(.system(size: 7 * fontSizeScale, weight: .bold, design: .rounded))
                .foregroundColor(MarketTheme.labelSecondary.opacity(0.5))
            Spacer()
            Text("Wed")
                .font(.system(size: 7 * fontSizeScale, weight: .bold, design: .rounded))
                .foregroundColor(MarketTheme.labelSecondary.opacity(0.5))
        }
        .frame(width: width, height: 10)
    }
}

// Sentiment Card perfectly mimicking Card 5 from the screenshot design
struct MarketSentimentCardView: View {
    let sentiment: MarketSentimentData
    let fontSizeScale: Double
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 1. Header
            HStack {
                Text("SENTIMENT")
                    .font(.system(size: 10 * fontSizeScale, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
            }
            .frame(height: 30)
            
            // 2. Middle Row (Chart on Left, Vertical Sentiment indicators on Right)
            HStack(alignment: .top, spacing: 4) {
                VStack(spacing: 4) {
                    SentimentLineChart(points: sentiment.trendPoints)
                        .frame(width: 90, height: 120)
                    
                    SentimentTimeAxisLabelsView(width: 90, fontSizeScale: fontSizeScale)
                }
                .frame(width: 90)
                
                Spacer().frame(width: 2)
                
                VStack(alignment: .center, spacing: 6) {
                    let bullPercentInt = Int(round(sentiment.bullPercent * 100))
                    let bearPercentInt = Int(round(sentiment.bearPercent * 100))
                    
                    Spacer().frame(height: 8)
                    
                    // 1. BULL Pill
                    Text("\(bullPercentInt)% BULL")
                        .font(.system(size: 9 * fontSizeScale, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: 72)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(red: 0.11, green: 0.38, blue: 0.22)) // Forest green
                        )
                        .shadow(color: MarketTheme.greenText.opacity(0.2), radius: 2)
                    
                    // 2. Neutral Text
                    Text("Neutral 12%")
                        .font(.system(size: 8 * fontSizeScale, weight: .bold, design: .rounded))
                        .foregroundColor(MarketTheme.labelSecondary.opacity(0.9))
                    
                    // 3. BEAR Pill
                    Text("\(bearPercentInt)% BEAR")
                        .font(.system(size: 9 * fontSizeScale, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: 72)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(red: 0.58, green: 0.16, blue: 0.18)) // Crimson red
                        )
                        .shadow(color: MarketTheme.redText.opacity(0.2), radius: 2)
                }
                .frame(width: 80, alignment: .center)
            }
            
            Spacer().frame(height: 1)
            
            // 3. Capsule bar matching the other cards
            GeometryReader { geo in
                let totalWidth = geo.size.width
                let greenWidth = totalWidth * CGFloat(sentiment.bullPercent)
                let greyWidth = totalWidth * 0.12
                let redWidth = totalWidth * CGFloat(sentiment.bearPercent) - (totalWidth * 0.12)
                
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(MarketTheme.greenText)
                        .frame(width: max(0, greenWidth))
                    Rectangle()
                        .fill(MarketTheme.centerBar)
                        .frame(width: max(0, greyWidth))
                    Rectangle()
                        .fill(MarketTheme.redText)
                        .frame(width: max(0, redWidth))
                }
                .clipShape(Capsule())
            }
            .frame(height: 6)
            
            // 4. Centered Bottom Title
            HStack {
                Spacer()
                Text("SENTIMENT (AAII)")
                    .font(.system(size: 9.5 * fontSizeScale, weight: .black, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                Spacer()
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .frame(width: 200, height: 280)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(MarketTheme.cardBackground)
                    .shadow(color: isHovered ? MarketTheme.greenText.opacity(0.12) : Color.black.opacity(0.15), radius: isHovered ? 8 : 4)
                
                RadialGradient(
                    gradient: Gradient(colors: [MarketTheme.greenText.opacity(isHovered ? 0.15 : 0.06), Color.clear]),
                    center: .bottomLeading,
                    startRadius: 0,
                    endRadius: 110
                )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHovered ? MarketTheme.greenText.opacity(0.4) : MarketTheme.border, lineWidth: 1.0)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.6, blendDuration: 0), value: isHovered)
        .onHover { hovering in
            self.isHovered = hovering
        }
    }
}

// Compact 2-Row Grid responsive visual layout container
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
        VStack(spacing: 12) {
            // Header Bar (Large, clean header with control adjustments on the right)
            HStack {
                Text("MARKET BREADTH & SENTIMENT")
                    .font(.system(size: 20, weight: .bold, design: .default))
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
            
            // Horizontal row of 5 premium visual cards
            HStack(spacing: 12) {
                if fetcher.items.count >= 3 {
                    ForEach(0..<3, id: \.self) { idx in
                        let item = fetcher.items[idx]
                        let title: String = {
                            switch idx {
                            case 0: return "ADV/DECL RATIO"
                            case 1: return "NET NEW HIGHS"
                            case 2: return "% ABV 50-DAY MA"
                            default: return item.title.uppercased()
                            }
                        }()
                        let historyPoints: [Double] = {
                            switch idx {
                            case 0: return fetcher.historyAdvancing
                            case 1: return fetcher.historyNewHighs
                            case 2: return fetcher.historySMA50
                            default: return []
                            }
                        }()
                        let yTicks: [String] = {
                            switch idx {
                            case 0: return ["1.30", "1.00", "1.00"]
                            case 1: return ["3,000", "2,000", "1,000"]
                            case 2: return ["0%", "-15%", "-35%"]
                            default: return ["100%", "50%", "0%"]
                            }
                        }()
                        let basePerc: CGFloat? = {
                            switch idx {
                            case 0: return 0.5
                            case 2: return 0.2
                            default: return nil
                            }
                        }()
                        
                        BreadthCardView(
                            title: title,
                            item: item,
                            historyPoints: historyPoints,
                            timestamps: fetcher.historyTimestamps,
                            fontSizeScale: fontSizeScale,
                            yTicks: yTicks,
                            baselineYPercent: basePerc
                        )
                    }
                } else {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: 280)
                }
                
                // VIX Index Card
                if let vix = fetcher.vix {
                    IndexCardView(
                        index: vix,
                        fontSizeScale: fontSizeScale,
                        yTicks: ["30.00", "20.00", "10.00"],
                        baselineYPercent: 0.5
                    )
                } else {
                    ProgressView().frame(width: 200, height: 280)
                }
                
                // Put/Call Ratio Card
                if let pc = fetcher.putCall {
                    IndexCardView(
                        index: pc,
                        fontSizeScale: fontSizeScale,
                        yTicks: ["1.00", "0.80", "0.60"],
                        baselineYPercent: 0.5
                    )
                } else {
                    ProgressView().frame(width: 200, height: 280)
                }
            }
            
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
                
                // Quit App Button (Hidden in floating window mode, as you have native close control)
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
        .padding(16)
        .frame(width: 1080, height: 390)
        .background(MarketTheme.background)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}
