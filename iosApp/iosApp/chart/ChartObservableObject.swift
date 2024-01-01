import Foundation
import shared
import SwiftUI
import CoreData

class ChartObservableObject: ObservableObject {
    @Published var upPeriods = Array<CGRect>()
    @Published var downPeriods = Array<CGRect>()
    @Published var fullPeriodsDown = Array<CGRect>()
    @Published var fullPeriodsUp = Array<CGRect>()
    @Published var fullPeriods = Array<ChartPeriod>()
    @Published var selectedIndex = -1
    @Published var description = " "
    @Published var positionsDecoration = Array<Decoration>()
    
    var offsetLimitRange = 0..<Int.max
    
    private var chartLenScreen: Int32 = 0
    private var rand: Rand = Rand(seed: 0)
    private var startPrice: Int64 = 0
    private var zoomToPeriod: PeriodDto?
    private var width: Float = 0
    private var height: Float = 0
    private var screenPeriods: Array<PeriodScreen> = Array()
    private var periods: Array<PeriodDto> = Array()
    private var seed: Int32 = 0
    private let c: CoreDataInventory

    init(_ c: CoreDataInventory) {
        self.c = c
    }
    
    func setupChart(_ restoreState: Bool = true) async {
        if (restoreState) {
            let fetchRequest = NSFetchRequest<ChartState>(entityName: "ChartState")
            if let chartStates = try? c.viewContext.fetch(fetchRequest) {
                if (!chartStates.isEmpty) {
                    let chartState = chartStates[0]
                    await reset(chartState.chartLen, chartState.seed)
                    return
                }
            }
        }
        await reset()
    }
    
    func isChartEmpty() -> Bool {
        return screenPeriods.isEmpty
    }
    
    func setSize(_ width: Float, _ height: Float) {
        self.width = width
        self.height = height
    }
    
    private func generatePositionsDecoratations(_ positions: FetchedResults<Position>, _ convertToScreenResult: ConvertToScreenResult) {
        positionsDecoration.removeAll()
        do {
            try ObjC.catchException {
                positions.forEach({ position in
                    let startIndex = position.startPeriod
                    let endOrCurrentIndex = position.endPeriod == 0 ? currentPeriodIndex() : position.endPeriod
                    let screenStartIndex: Int = Int(startIndex) - Int(screenPeriods[0].periodDto.index)
                    let screenEndIndex: Int = Int(screenStartIndex) + Int(endOrCurrentIndex - startIndex)
                    let lastScreenIndex = screenPeriods.count - 1
                    
                    if screenEndIndex >= 0 && screenStartIndex <= lastScreenIndex {
                        var start: CGPoint
                        var end: CGPoint
                        let offset = screenPeriods[0].w / 2
                        
                        if screenStartIndex < 0 {
                            start = CGPoint(
                                x: Double(Float(screenStartIndex) * screenPeriods[0].w + offset),
                                y: Double(self.height) - (Double(periods[Int(startIndex)].close - convertToScreenResult.yMin)
                                                          * Double(convertToScreenResult.pixelPrice))
                            )
                        } else {
                            start = CGPoint(
                                x: Int(screenPeriods[screenStartIndex].x + offset),
                                y: Int(screenPeriods[screenStartIndex].c)
                            )
                        }
                        
                        if screenEndIndex > lastScreenIndex {
                            end = CGPoint(
                                x: Double(Float(screenEndIndex) * screenPeriods[0].w + offset),
                                y: Double(self.height) - (Double(periods[Int(endOrCurrentIndex)].close - convertToScreenResult.yMin)
                                                          * Double(convertToScreenResult.pixelPrice))
                            )
                        } else {
                            end = CGPoint(
                                x: Int(screenPeriods[screenEndIndex].x + offset),
                                y: Int(screenPeriods[screenEndIndex].c)
                            )
                        }
                        
                        if (start != end) {
                            positionsDecoration.append(
                                LineDecoration(start: start, end: end)
                            )
                        } else {
                            let period = periods[Int(startIndex)]
                            let offset = period.open < period.close ? -CGFloat(offset) : CGFloat(offset)
                            
                            positionsDecoration.append(
                                CircleDecoration(start: CGPoint(x: start.x, y: start.y + offset), end: CGPoint(x: end.x, y: end.y + offset), radius: offset > 0 ? offset - 2 : offset + 2)
                            )
                        }
                    }
                })
            }
        } catch {
            print("Error info: \(error)")
        }
    }
    
    func generatePeriodsRects(_ offset: Float, _ positions: FetchedResults<Position>) {
        let convertToScreenResult = PeriodsConvertKt.convertToScreen(allPeriods: periods,
                                                                     periodsOnScreen: chartLenScreen,
                                                                     offset: offset,
                                                                     w: self.width,
                                                                     h: self.height)
        
        screenPeriods = convertToScreenResult.screenPeriods
        if (screenPeriods.count < chartLenScreen / 2) {
            offsetLimitRange = 0..<Int(offset)
        } else {
            offsetLimitRange = 0..<Int.max
        }
        
        convertScreenPeriodsToRects()
     
        generatePositionsDecoratations(positions, convertToScreenResult)
    }
    
    func zoomToPosition(_ startIndex: Int32,  _ endIndex: Int32, _ positions: FetchedResults<Position>) -> CGFloat? {
        let endOrCurrentIndex = endIndex == 0 ? currentPeriodIndex() : endIndex
        
        chartLenScreen = (endOrCurrentIndex + 4) - (startIndex - 4)
        let centerPeriodIndex: Int = (Int)(startIndex - 4 + (chartLenScreen / 2))
        if let centerPeriod = periods[safe: centerPeriodIndex] {
            let newOffset = PeriodsConvertKt.calculateOffsetForZoom(
                allPeriods: periods,
                periodsOnScreen: chartLenScreen,
                centerAroundPeriod: centerPeriod,
                w: self.width)
            generatePeriodsRects(newOffset, positions)
            return CGFloat(newOffset)
        } else {
            return nil
        }
    }
    
    func zoom(_ width: Float, _ zoomBy: Int32, _ positions: FetchedResults<Position>) -> CGFloat {
        chartLenScreen = min(Int32(width / 2), max(10, chartLenScreen - zoomBy))
        let centerPeriod = zoomToPeriod ?? findCentralPeriod(width)
        let newOffset = PeriodsConvertKt.calculateOffsetForZoom(allPeriods: periods, periodsOnScreen: chartLenScreen, centerAroundPeriod: centerPeriod, w: width)
        zoomToPeriod = centerPeriod
        generatePeriodsRects(newOffset, positions)
        return CGFloat(newOffset)
    }
    
    func endZoom() {
        zoomToPeriod = nil
    }
    
    func next(_ positions: FetchedResults<Position>) -> CGFloat {
        let lastClose = periods.last!.close
        let nextPeriod = PeriodsRandomDataSourceKt.getRandomAvailablePeriods(startPrice: lastClose, rand: rand, count: 1, indexFrom: Int32(periods.count), basePrice:
                                                                                startPrice)[0]
        periods.append(nextPeriod)
        let newOffset = PeriodsConvertKt.calculateOffsetForZoom(allPeriods: periods, periodsOnScreen: chartLenScreen, centerAroundPeriod: nextPeriod, w: self.width)
        generatePeriodsRects(newOffset, positions)
        description = "Current close: \(int64PriceToString(nextPeriod.close))"
        return CGFloat(newOffset)
    }
    
    func saveChartState() async {
        await c.performWrite(block: { c in
            do {
                let fetchRequest = NSFetchRequest<ChartState>(entityName: "ChartState")
                let chartStates = try fetchRequest.execute()
                let chartState = (chartStates.isEmpty) ? ChartState(context: c) : chartStates[0]
                chartState.seed = self.seed
                chartState.chartLen = Int32(self.periods.count - 1)
            } catch let error {
                print(error.localizedDescription)
            }
        })
    }
    
    func selectPeriod(x: Float) {
        let minX = self.screenPeriods.first?.x ?? 0
        let width = self.screenPeriods.first?.w ?? 0
        
        if (width <= 0) {
            selectedIndex = -1
            return
        }
        
        let newSelectedIndex = Int((x - minX) / width)
        if (newSelectedIndex < self.screenPeriods.count) {
            selectedIndex = newSelectedIndex
            let periodDto = self.screenPeriods[selectedIndex].periodDto
            description = "O: \(int64PriceToString(periodDto.open)) H: \(int64PriceToString(periodDto.high)) L: \(int64PriceToString(periodDto.low))" +
            " C: \(int64PriceToString(periodDto.close))"
        }
    }
    
    func currentPriceCents() -> Int64 {
        return periods.last?.close ?? 0
    }
    
    func currentPeriod() -> Period {
        let period = periods[periods.count - 1]
        return Period(index: Int64(periods.count - 1), high: period.high, low: period.low, open: period.open, close: period.close)
    }
    
    func currentPeriodIndex() -> Int32 {
        return Int32(periods.count - 1)
    }
    
    private func reset(_ chartLen: Int32 = 100, _ seed: Int32 = Int32(Int.random(in: 0..<Int(INT32_MAX))), _ chartLenScreen: Int32 = 75, _ startPrice: Int64 = 5000) async {
        await MainActor.run {
            self.seed = seed
            self.chartLenScreen = chartLenScreen
            self.rand = Rand(seed: seed)
            self.startPrice = startPrice
            self.periods = PeriodsRandomDataSourceKt.getRandomAvailablePeriods(startPrice: startPrice, rand: rand, count: chartLen, indexFrom: 0, basePrice: startPrice)
        }
    }
    
    private func findCentralPeriod(_ width: Float) -> PeriodDto {
        let xCenter = width / 2
        return screenPeriods.first(where: { p in return (xCenter >= p.x && xCenter <= (p.x + p.w)) })?.periodDto ?? screenPeriods[screenPeriods.count - 1].periodDto
    }
    
    private func convertScreenPeriodsToRects() {
        self.upPeriods.removeAll()
        self.downPeriods.removeAll()
        self.fullPeriodsUp.removeAll()
        self.fullPeriodsDown.removeAll()
        self.fullPeriods.removeAll()
        self.selectedIndex = -1
        
        for screenPeriod in screenPeriods {
            let y: Int32 = (screenPeriod.o < screenPeriod.c) ? screenPeriod.o : screenPeriod.c
            let h: Int32 = max(1, abs(screenPeriod.c - screenPeriod.o))
            let bodyRc = CGRect(x: CGFloat(screenPeriod.x + 1), y: CGFloat(y), width: CGFloat(screenPeriod.w - 2), height: CGFloat(h))
            
            if (screenPeriod.o <= screenPeriod.c) {
                self.downPeriods.append(bodyRc)
            } else {
                self.upPeriods.append(bodyRc)
            }
            
            if (screenPeriod.o <= screenPeriod.c) {
                self.fullPeriodsDown.append(CGRect(x: CGFloat(screenPeriod.x), y: CGFloat(screenPeriod.y), width: CGFloat(screenPeriod.w), height: CGFloat(screenPeriod.h)))
            } else {
                self.fullPeriodsUp.append(CGRect(x: CGFloat(screenPeriod.x), y: CGFloat(screenPeriod.y), width: CGFloat(screenPeriod.w), height: CGFloat(screenPeriod.h)))
            }
             
            self.fullPeriods.append(ChartPeriod(
                index: screenPeriod.periodDto.index,
                fullRect: CGRect(x: CGFloat(screenPeriod.x), y: CGFloat(screenPeriod.y), width: CGFloat(screenPeriod.w), height: CGFloat(screenPeriod.h)),
                bodyRect: bodyRc))
        }
    }
}
