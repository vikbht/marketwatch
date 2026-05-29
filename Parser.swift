import Foundation
import Combine

public struct MarketBreadthItem: Identifiable, Codable {
    public var id: String { title }
    public let title: String
    public let leftLabel: String
    public let leftValue: String
    public let rightLabel: String
    public let rightValue: String
    public let leftBarPercent: Double
    public let centerBarPercent: Double
    public let rightBarPercent: Double
    
    public init(
        title: String,
        leftLabel: String,
        leftValue: String,
        rightLabel: String,
        rightValue: String,
        leftBarPercent: Double,
        centerBarPercent: Double,
        rightBarPercent: Double
    ) {
        self.title = title
        self.leftLabel = leftLabel
        self.leftValue = leftValue
        self.rightLabel = rightLabel
        self.rightValue = rightValue
        self.leftBarPercent = leftBarPercent
        self.centerBarPercent = centerBarPercent
        self.rightBarPercent = rightBarPercent
    }
}

public struct MarketSentimentData: Identifiable, Codable {
    public var id: String { "sentiment" }
    public let bullPercent: Double
    public let bearPercent: Double
    public let trendPoints: [Double]
    public let weightPoints: [Double]
    public let lastUpdated: String
    
    public init(
        bullPercent: Double,
        bearPercent: Double,
        trendPoints: [Double],
        weightPoints: [Double],
        lastUpdated: String
    ) {
        self.bullPercent = bullPercent
        self.bearPercent = bearPercent
        self.trendPoints = trendPoints
        self.weightPoints = weightPoints
        self.lastUpdated = lastUpdated
    }
}

public struct MarketIndexData: Identifiable, Codable {
    public var id: String { symbol }
    public let symbol: String
    public let title: String
    public let currentPrice: Double
    public let previousClose: Double
    public let historyPoints: [Double]
    public let historyTimestamps: [Date]
    
    public var priceChangePercent: Double {
        guard previousClose > 0 else { return 0.0 }
        return ((currentPrice - previousClose) / previousClose) * 100.0
    }
    
    public init(symbol: String, title: String, currentPrice: Double, previousClose: Double, historyPoints: [Double], historyTimestamps: [Date]) {
        self.symbol = symbol
        self.title = title
        self.currentPrice = currentPrice
        self.previousClose = previousClose
        self.historyPoints = historyPoints
        self.historyTimestamps = historyTimestamps
    }
}

struct YahooChartJSON: Decodable {
    struct Chart: Decodable {
        struct Result: Decodable {
            struct Meta: Decodable {
                let symbol: String
                let regularMarketPrice: Double
                let chartPreviousClose: Double
            }
            struct Indicators: Decodable {
                struct Quote: Decodable {
                    let close: [Double?]
                }
                let quote: [Quote]
            }
            let meta: Meta
            let indicators: Indicators
            let timestamp: [Int]?
        }
        let result: [Result]?
    }
    let chart: Chart
}

struct FinvizSentimentJSON: Decodable {
    let refresh: Int?
    let enabled: Bool?
    let sum: [Double]?
    let weight: [Double]?
    let time: String?
    let visibleMinutes: Int?
}

public class MarketBreadthFetcher: ObservableObject {
    @Published public var items: [MarketBreadthItem] = []
    @Published public var sentiment: MarketSentimentData? = nil
    @Published public var isLoading: Bool = false
    @Published public var lastUpdated: Date? = nil
    @Published public var errorMessage: String? = nil
    @Published public var isPausedOutsideMarketHours: Bool = false
    
    // In-memory rolling sparkline history arrays
    @Published public var historyAdvancing: [Double] = []
    @Published public var historyNewHighs: [Double] = []
    @Published public var historySMA50: [Double] = []
    @Published public var historySMA200: [Double] = []
    @Published public var historyTimestamps: [Date] = []
    
    // Live index models (VIX & Put/Call Ratio)
    @Published public var vix: MarketIndexData? = nil
    @Published public var putCall: MarketIndexData? = nil
    
    private var cancellables = Set<AnyCancellable>()
    private let url = URL(string: "https://finviz.com/")!
    private let sentimentUrl = URL(string: "https://finviz.com/api/market_sentiment")!
    private let vixUrl = URL(string: "https://query1.finance.yahoo.com/v8/finance/chart/^VIX?interval=15m&range=1d")!
    private let putCallUrl = URL(string: "https://query1.finance.yahoo.com/v8/finance/chart/^CPCE?interval=15m&range=1d")!
    
    // Weighted Market Health Score computation (0 - 100%)
    public var marketHealthScore: Int {
        guard items.count >= 4 else { return 50 }
        
        let adv = items[0].leftBarPercent
        let nh = items[1].leftBarPercent
        let sma50 = items[2].leftBarPercent
        let sma200 = items[3].leftBarPercent
        
        let bull = (sentiment?.bullPercent ?? 0.64) * 100.0
        
        let score = 0.30 * adv + 0.15 * nh + 0.15 * sma50 + 0.15 * sma200 + 0.25 * bull
        return Int(round(score))
    }
    
    public init() {
        // Load initial offline/mock data to prevent empty states on boot
        self.items = getPlaceholderData()
        self.sentiment = getPlaceholderSentimentData()
        self.vix = getPlaceholderVixData()
        self.putCall = getPlaceholderPutCallData()
        self.initHistoryBuffers(adv: 58.6, nh: 62.5, s50: 55.4, s200: 51.2)
    }
    
    private func initHistoryBuffers(adv: Double, nh: Double, s50: Double, s200: Double) {
        self.historyAdvancing = generateStarterCurve(from: 50.0, to: adv, length: 40)
        self.historyNewHighs = generateStarterCurve(from: 50.0, to: nh, length: 40)
        self.historySMA50 = generateStarterCurve(from: 50.0, to: s50, length: 40)
        self.historySMA200 = generateStarterCurve(from: 50.0, to: s200, length: 40)
        
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now.addingTimeInterval(-86400)
        
        var dates: [Date] = []
        // First 20 represent yesterday's close
        for i in 0..<20 {
            dates.append(yesterday.addingTimeInterval(Double(20 - 1 - i) * -120.0))
        }
        // Last 20 represent today's trading
        for i in 0..<20 {
            dates.append(now.addingTimeInterval(Double(20 - 1 - i) * -120.0))
        }
        self.historyTimestamps = dates
    }
    
    private func generateStarterCurve(from: Double, to: Double, length: Int) -> [Double] {
        var arr: [Double] = []
        for i in 0..<length {
            let t = Double(i) / Double(length - 1)
            let noise = Double.random(in: -1.8...1.8)
            let val = from + (to - from) * t + noise
            arr.append(max(0, min(100, val)))
        }
        // 3-point moving average smoothing filter for an ultra-smooth organic financial curve
        var smoothed: [Double] = []
        for i in 0..<arr.count {
            if i == 0 || i == arr.count - 1 {
                smoothed.append(arr[i])
            } else {
                let avg = (arr[i-1] + arr[i] + arr[i+1]) / 3.0
                smoothed.append(avg)
            }
        }
        return smoothed
    }
    
    private func isMarketHours() -> Bool {
        var nycCalendar = Calendar.current
        guard let tz = TimeZone(identifier: "America/New_York") else {
            return true
        }
        nycCalendar.timeZone = tz
        
        let now = Date()
        let weekday = nycCalendar.component(.weekday, from: now)
        // Weekdays only (2 = Monday, 6 = Friday)
        guard weekday >= 2 && weekday <= 6 else {
            return false
        }
        
        let hour = nycCalendar.component(.hour, from: now)
        let minute = nycCalendar.component(.minute, from: now)
        
        let minutesFromMidnight = hour * 60 + minute
        let marketStart = 9 * 60 + 30  // 9:30 AM NY Time
        let marketEnd = 16 * 60        // 4:00 PM NY Time
        
        return minutesFromMidnight >= marketStart && minutesFromMidnight < marketEnd
    }
    
    public func fetch() {
        // Always fetch on first boot (when lastUpdated is nil) so we show latest closing stats
        let isFirstFetch = (lastUpdated == nil)
        let marketOpen = isMarketHours()
        
        if !isFirstFetch && !marketOpen {
            DispatchQueue.main.async {
                self.isPausedOutsideMarketHours = true
                self.isLoading = false
            }
            print("Background fetch skipped: US stock market is currently closed.")
            return
        }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
            self.isPausedOutsideMarketHours = false
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        var sentimentRequest = URLRequest(url: sentimentUrl)
        sentimentRequest.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        sentimentRequest.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        var vixRequest = URLRequest(url: vixUrl)
        vixRequest.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        vixRequest.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        var putCallRequest = URLRequest(url: putCallUrl)
        putCallRequest.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        putCallRequest.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        let htmlPublisher = URLSession.shared.dataTaskPublisher(for: request)
            .map { $0.data }
            .map { String(data: $0, encoding: .utf8) ?? "" }
            .catch { _ in Just("") }
        
        let sentimentPublisher = URLSession.shared.dataTaskPublisher(for: sentimentRequest)
            .map { $0.data }
            .map { data -> FinvizSentimentJSON? in
                try? JSONDecoder().decode(FinvizSentimentJSON.self, from: data)
            }
            .catch { _ in Just(nil) }
            
        let vixPublisher = URLSession.shared.dataTaskPublisher(for: vixRequest)
            .map { $0.data }
            .map { data -> YahooChartJSON? in
                try? JSONDecoder().decode(YahooChartJSON.self, from: data)
            }
            .catch { _ in Just(nil) }
            
        let putCallPublisher = URLSession.shared.dataTaskPublisher(for: putCallRequest)
            .map { $0.data }
            .map { data -> YahooChartJSON? in
                try? JSONDecoder().decode(YahooChartJSON.self, from: data)
            }
            .catch { _ in Just(nil) }
        
        Publishers.Zip4(htmlPublisher, sentimentPublisher, vixPublisher, putCallPublisher)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                self.isLoading = false
                if case .failure(let error) = completion {
                    self.errorMessage = error.localizedDescription
                }
            }, receiveValue: { html, sentimentJSON, vixJSON, putCallJSON in
                // 1. Process HTML Breadth Items
                let parsedItems = self.parseHTML(html)
                if !parsedItems.isEmpty {
                    self.items = parsedItems
                    self.errorMessage = nil
                    
                    // 1b. Record in-memory sparkline history
                    if parsedItems.count >= 4 {
                        let adv = parsedItems[0].leftBarPercent
                        let nh = parsedItems[1].leftBarPercent
                        let s50 = parsedItems[2].leftBarPercent
                        let s200 = parsedItems[3].leftBarPercent
                        
                        if self.historyAdvancing.isEmpty {
                            self.initHistoryBuffers(adv: adv, nh: nh, s50: s50, s200: s200)
                        } else {
                            self.historyAdvancing.append(adv)
                            self.historyNewHighs.append(nh)
                            self.historySMA50.append(s50)
                            self.historySMA200.append(s200)
                            self.historyTimestamps.append(Date())
                            
                            if self.historyAdvancing.count > 40 { self.historyAdvancing.removeFirst() }
                            if self.historyNewHighs.count > 40 { self.historyNewHighs.removeFirst() }
                            if self.historySMA50.count > 40 { self.historySMA50.removeFirst() }
                            if self.historySMA200.count > 40 { self.historySMA200.removeFirst() }
                            if self.historyTimestamps.count > 40 { self.historyTimestamps.removeFirst() }
                        }
                    }
                } else if self.items.isEmpty {
                    self.errorMessage = "Failed to parse data from website."
                }
                
                // 2. Process Sentiment JSON
                if let json = sentimentJSON,
                   let sum = json.sum, !sum.isEmpty,
                   let weight = json.weight, !weight.isEmpty {
                    
                    let latestSum = sum.last ?? 0.0
                    let latestWeight = weight.last ?? 1.0
                    
                    let bull = latestWeight > 0 ? (latestWeight + latestSum) / (2.0 * latestWeight) : 0.5
                    let bear = latestWeight > 0 ? (latestWeight - latestSum) / (2.0 * latestWeight) : 0.5
                    
                    self.sentiment = MarketSentimentData(
                        bullPercent: bull,
                        bearPercent: bear,
                        trendPoints: sum,
                        weightPoints: weight,
                        lastUpdated: json.time ?? ""
                    )
                } else {
                    if self.sentiment == nil {
                        self.sentiment = self.getPlaceholderSentimentData()
                    }
                }
                
                // 3. Process VIX
                if let vixData = self.parseYahooJSON(vixJSON, symbol: "^VIX", title: "VIX INDEX") {
                    self.vix = vixData
                } else if self.vix == nil {
                    self.vix = self.getPlaceholderVixData()
                }
                
                // 4. Process Put/Call
                if let pcData = self.parseYahooJSON(putCallJSON, symbol: "^CPCE", title: "EQUITY PUT/CALL") {
                    self.putCall = pcData
                } else if self.putCall == nil {
                    self.putCall = self.getPlaceholderPutCallData()
                }
                
                self.lastUpdated = Date()
                self.isPausedOutsideMarketHours = !self.isMarketHours()
            })
            .store(in: &cancellables)
    }
    
    private func parseYahooJSON(_ json: YahooChartJSON?, symbol: String, title: String) -> MarketIndexData? {
        guard let result = json?.chart.result?.first else { return nil }
        let current = result.meta.regularMarketPrice
        let prevClose = result.meta.chartPreviousClose
        
        var points: [Double] = []
        if let quotes = result.indicators.quote.first {
            points = quotes.close.compactMap { $0 }
        }
        
        var dates: [Date] = []
        if let epochs = result.timestamp {
            dates = epochs.map { Date(timeIntervalSince1970: TimeInterval($0)) }
        }
        
        if points.isEmpty {
            points = [prevClose, current]
        }
        if dates.isEmpty {
            dates = [Date().addingTimeInterval(-120), Date()]
        }
        
        if points.count > 40 {
            points = Array(points.suffix(40))
        }
        if dates.count > 40 {
            dates = Array(dates.suffix(40))
        }
        
        return MarketIndexData(
            symbol: symbol,
            title: title,
            currentPrice: current,
            previousClose: prevClose,
            historyPoints: points,
            historyTimestamps: dates
        )
    }
    
    private func parseHTML(_ html: String) -> [MarketBreadthItem] {
        var parsed: [MarketBreadthItem] = []
        
        let pattern = #"(?s)<div class="market-stats"[^>]*data-boxover-html="Total &lt;b&gt;([^&]+)&lt;/b&gt;[^"]*".*?<div class="market-stats_labels">\s*<div class="market-stats_labels_left"><p>([^<]+)</p><p>([^<]+)</p></div>\s*(?:([^\s<][^<]*)?)\s*<div class="market-stats_labels_right"><p>([^<]+)</p><p>([^<]+)</p></div>.*?<div class="market-stats_bar">\s*<div class="market-stats_bar_left-bar" style="width:\s*([0-9.]+)%"></div>\s*<div class="market-stats_bar_center-bar" style="width:\s*([0-9.]+)%"></div>\s*<div class="market-stats_bar_right-bar" style="width:\s*([0-9.]+)%"></div>"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return []
        }
        
        let nsString = html as NSString
        let matches = regex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))
        
        for match in matches {
            if match.numberOfRanges >= 10 {
                let rawTitle = nsString.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
                let leftLabel = nsString.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespacesAndNewlines)
                let leftValue = nsString.substring(with: match.range(at: 3)).trimmingCharacters(in: .whitespacesAndNewlines)
                
                var middleLabel = ""
                let midRange = match.range(at: 4)
                if midRange.location != NSNotFound {
                    middleLabel = nsString.substring(with: midRange).trimmingCharacters(in: .whitespacesAndNewlines)
                }
                
                let rightLabel = nsString.substring(with: match.range(at: 5)).trimmingCharacters(in: .whitespacesAndNewlines)
                let rightValue = nsString.substring(with: match.range(at: 6)).trimmingCharacters(in: .whitespacesAndNewlines)
                
                let leftBar = Double(nsString.substring(with: match.range(at: 7))) ?? 0.0
                let centerBar = Double(nsString.substring(with: match.range(at: 8))) ?? 0.0
                let rightBar = Double(nsString.substring(with: match.range(at: 9))) ?? 0.0
                
                let displayTitle = middleLabel.isEmpty ? rawTitle : middleLabel
                
                let item = MarketBreadthItem(
                    title: displayTitle,
                    leftLabel: leftLabel,
                    leftValue: leftValue,
                    rightLabel: rightLabel,
                    rightValue: rightValue,
                    leftBarPercent: leftBar,
                    centerBarPercent: centerBar,
                    rightBarPercent: rightBar
                )
                parsed.append(item)
            }
        }
        
        return parsed
    }
    
    private func getPlaceholderData() -> [MarketBreadthItem] {
        return [
            MarketBreadthItem(title: "Advancing / Declining", leftLabel: "Advancing", leftValue: "58.6% (3211)", rightLabel: "Declining", rightValue: "(2269) 41.4%", leftBarPercent: 58.6, centerBarPercent: 0.0, rightBarPercent: 41.4),
            MarketBreadthItem(title: "New High / New Low", leftLabel: "New High", leftValue: "62.5% (214)", rightLabel: "New Low", rightValue: "(128) 37.5%", leftBarPercent: 62.5, centerBarPercent: 0.0, rightBarPercent: 37.5),
            MarketBreadthItem(title: "SMA50", leftLabel: "Above", leftValue: "55.4% (3084)", rightLabel: "Below", rightValue: "(2484) 44.6%", leftBarPercent: 55.4, centerBarPercent: 0.0, rightBarPercent: 44.6),
            MarketBreadthItem(title: "SMA200", leftLabel: "Above", leftValue: "51.2% (2854)", rightLabel: "Below", rightValue: "(2719) 48.8%", leftBarPercent: 51.2, centerBarPercent: 0.0, rightBarPercent: 48.8)
        ]
    }
    
    private func getPlaceholderSentimentData() -> MarketSentimentData {
        return MarketSentimentData(
            bullPercent: 0.64,
            bearPercent: 0.36,
            trendPoints: [2.0, 5.6, 11.4, 4.8, 3.0, 6.2, -2.2, 0.4, -3.2, -2.8, 2.6, 0.0, 0.8, 6.0, 1.4, 7.4, 10.0, 11.2, 12.8, 15.4, 11.2, 9.2, 9.6, 3.0, 4.0, 2.6, 3.4, 3.2, 10.6, 15.8, 10.0, 11.6, 11.6, 13.0, 14.8, 8.0, 7.4, 13.2, 9.0, 7.0, 1.0, -1.8, 1.2, 4.2, 6.6, 4.6, 3.0, 5.2, 6.4, 6.6, 6.0, 0.0, 0.8, 1.0, -2.4, -1.8, 1.0, 4.6, 4.8, 5.0, 3.4, -2.2, 0.4, -1.8, 1.6, 2.6, 5.4, 3.8, 6.8, 11.6, 8.6, 5.8, 6.6, 5.8, 2.4, 0.6, 6.0, 6.2, 6.6, 7.0, 12.8, 10.8, 5.6, 7.2, 5.4, 0.8, 2.2, 3.6, 2.2, 0.6, 0.4, 0.8, 4.4, 2.6, 2.0, -0.8, -1.2, -2.4, -1.6, 2.0, 3.0, 1.4, 1.0, 4.4, 3.0, -0.8, 4.2, 7.0, 7.0, 11.4, 6.6, 6.6, 4.0, 1.2, 1.0, -0.2, 1.4, 1.2, 4.0, 7.0, 9.4, 5.8, 9.8, 10.6, 5.2, 9.0, 10.4, 8.8, 9.0, 5.4],
            weightPoints: [10.0, 16.0, 23.4, 29.6, 31.4, 30.2, 28.2, 33.2, 34.4, 37.6, 33.0, 28.8, 22.8, 22.8, 23.4, 27.0, 28.8, 28.0, 31.6, 33.4, 35.6, 32.4, 33.6, 33.0, 30.8, 28.2, 28.6, 27.6, 30.2, 30.6, 30.8, 33.6, 28.8, 30.6, 32.4, 28.8, 25.8, 28.0, 26.2, 24.2, 24.2, 21.0, 21.2, 23.0, 26.6, 23.4, 21.8, 20.0, 23.6, 25.8, 23.2, 21.6, 28.0, 25.8, 22.4, 23.0, 25.0, 24.2, 23.6, 23.0, 23.0, 21.0, 18.8, 22.2, 26.0, 27.0, 25.8, 25.4, 22.4, 23.2, 19.4, 20.6, 18.6, 20.2, 18.4, 17.4, 23.2, 22.2, 19.0, 20.6, 23.6, 21.6, 22.8, 25.6, 26.2, 27.6, 25.0, 22.4, 22.2, 21.4, 20.0, 22.4, 23.2, 24.6, 24.8, 22.8, 20.8, 20.4, 19.2, 17.6, 20.6, 25.0, 23.4, 24.0, 22.2, 29.2, 33.0, 27.4, 20.2, 20.2, 17.8, 18.2, 20.8, 21.6, 19.4, 17.8, 19.4, 18.8, 15.6, 16.2, 16.6, 17.8, 22.2, 21.8, 20.8, 25.8, 23.6, 23.6, 23.0, 18.2],
            lastUpdated: "Placeholder"
        )
    }
    
    private func getPlaceholderVixData() -> MarketIndexData {
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now.addingTimeInterval(-86400)
        var dates: [Date] = []
        for i in 0..<5 { dates.append(yesterday.addingTimeInterval(Double(5 - 1 - i) * -120.0)) }
        for i in 0..<6 { dates.append(now.addingTimeInterval(Double(6 - 1 - i) * -120.0)) }
        
        return MarketIndexData(
            symbol: "^VIX",
            title: "VIX INDEX",
            currentPrice: 14.52,
            previousClose: 13.88,
            historyPoints: [13.88, 13.92, 14.05, 14.12, 14.28, 14.18, 14.32, 14.22, 14.40, 14.36, 14.52],
            historyTimestamps: dates
        )
    }
    
    private func getPlaceholderPutCallData() -> MarketIndexData {
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now.addingTimeInterval(-86400)
        var dates: [Date] = []
        for i in 0..<5 { dates.append(yesterday.addingTimeInterval(Double(5 - 1 - i) * -120.0)) }
        for i in 0..<6 { dates.append(now.addingTimeInterval(Double(6 - 1 - i) * -120.0)) }
        
        return MarketIndexData(
            symbol: "^CPCE",
            title: "EQUITY PUT/CALL",
            currentPrice: 0.62,
            previousClose: 0.65,
            historyPoints: [0.65, 0.64, 0.62, 0.60, 0.61, 0.63, 0.65, 0.67, 0.64, 0.63, 0.62],
            historyTimestamps: dates
        )
    }
}
