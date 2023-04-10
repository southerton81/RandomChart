import Foundation
import shared
import SwiftUI
import CoreData

class ChartObservableObject: ObservableObject {
    @Published var upPeriods = Array<CGRect>()
    @Published var downPeriods = Array<CGRect>()
    @Published var allPeriods = Array<CGRect>()
    @Published var selectedIndex = -1
    @Published var description = " "
    
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
    
    func generatePeriodsRects(_ offset: Float) {
        screenPeriods = PeriodsConvertKt.convertToScreen(allPeriods: periods, periodsOnScreen: chartLenScreen,
                                                         offset: offset, w: self.width, h: self.height)
        
        if (screenPeriods.count < chartLenScreen / 2) {
            offsetLimitRange = 0..<Int(offset)
        } else {
            offsetLimitRange = 0..<Int.max
        }
        
        convertToRects()
    }
    
    func zoom(_ offset: Float, _ width: Float, _ height: Float, _ zoomBy: Int32) -> CGFloat {
        chartLenScreen = min(Int32(width / 2), max(10, chartLenScreen - zoomBy))
        let period = zoomToPeriod ?? findCentralPeriod(width)
        let newOffset = PeriodsConvertKt.calculateOffsetForZoom(allPeriods: periods, periodsOnScreen: chartLenScreen, centerAroundPeriod: period, w: width)
        zoomToPeriod = period
        generatePeriodsRects(newOffset)
        return CGFloat(newOffset)
    }
    
    func endZoom() {
        zoomToPeriod = nil
    }
    
    func next() -> CGFloat {
        let lastClose = periods.last!.close
        let nextPeriod = PeriodsRandomDataSourceKt.getRandomAvailablePeriods(startPrice: lastClose, rand: rand, count: 1, indexFrom: Int32(periods.count), basePrice:
                                                                                startPrice)[0]
        periods.append(nextPeriod)
        let newOffset = PeriodsConvertKt.calculateOffsetForZoom(allPeriods: periods, periodsOnScreen: chartLenScreen, centerAroundPeriod: nextPeriod, w: self.width)
        generatePeriodsRects(newOffset)
        description = "Close: $\(int64PriceToString(nextPeriod.close))"
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
            description = "High: $\(int64PriceToString(periodDto.high)) Low: $\(int64PriceToString(periodDto.low))" +
            " -- Open: $\(int64PriceToString(periodDto.open)) Close: $\(int64PriceToString(periodDto.close))"
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
    
    private func convertToRects() {
        self.upPeriods.removeAll()
        self.downPeriods.removeAll()
        self.allPeriods.removeAll()
        self.selectedIndex = -1
        
        for screenPeriod in screenPeriods {
            let y: Int32 = (screenPeriod.o < screenPeriod.c) ? screenPeriod.o : screenPeriod.c
            let h: Int32 = max(1, abs(screenPeriod.c - screenPeriod.o))
            let rc = CGRect(x: CGFloat(screenPeriod.x + 1), y: CGFloat(y), width: CGFloat(screenPeriod.w - 2), height: CGFloat(h))
            
            if (screenPeriod.o <= screenPeriod.c) {
                self.downPeriods.append(rc)
            } else {
                self.upPeriods.append(rc)
            }
            
            self.allPeriods.append(CGRect(x: CGFloat(screenPeriod.x), y: CGFloat(screenPeriod.y), width: CGFloat(screenPeriod.w), height: CGFloat(screenPeriod.h)))
        }
    }
}
