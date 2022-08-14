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
    
    private var chartLenScreen: Int32
    private var rand: Rand
    private let startPrice: Int64
    
    private var zoomToPeriod: PeriodDto?
    private var width: Float = 0
    private var height: Float = 0
    private var screenPeriods: Array<PeriodScreen> = Array()
    private var periods: Array<PeriodDto>
    private var seed: Int32
    
    init(_ chartLen: Int32 = 200, _ seed: Int32 = Int32(Int.random(in: 0..<Int(INT32_MAX))), _ chartLenScreen: Int32 = 100, _ startPrice: Int64 = 5000) {
        self.chartLenScreen = chartLenScreen
        self.rand = Rand(seed: seed)
        self.seed = seed
        
        self.startPrice = startPrice
        self.periods = PeriodsRandomDataSourceKt.getRandomAvailablePeriods(startPrice: startPrice, rand: rand, count: chartLen, indexFrom: 0, basePrice: startPrice)
    }
    
    func generatePeriodsRects(_ offset: Float, _ width: Float, _ height: Float) {
        screenPeriods = PeriodsConvertKt.convertToScreen(allPeriods: periods, periodsOnScreen: chartLenScreen, offset: offset, w: width, h: height)
          
        if (screenPeriods.count < chartLenScreen / 2) {
            offsetLimitRange = 0..<Int(offset)
        } else {
            offsetLimitRange = 0..<Int.max
        }
        
        convertToRects()
        
        self.width = width
        self.height = height
    }
    
    func zoom(_ offset: Float, _ width: Float, _ height: Float, _ zoomBy: Int32) -> CGFloat {
        chartLenScreen = min(Int32(width / 2), max(10, chartLenScreen - zoomBy))
        let period = zoomToPeriod ?? findCentralPeriod(width)
        let newOffset = PeriodsConvertKt.calculateOffsetForZoom(allPeriods: periods, periodsOnScreen: chartLenScreen, centerAroundPeriod: period, w: width)
        zoomToPeriod = period
        generatePeriodsRects(newOffset, width, height)
        return CGFloat(newOffset)
    }
    
    func endZoom() {
        zoomToPeriod = nil
    }
    
    func next(_ defaultOffset: CGFloat) -> CGFloat {
        if let lastClose = periods.last?.close {
            let nextPeriod = PeriodsRandomDataSourceKt.getRandomAvailablePeriods(startPrice: lastClose, rand: rand, count: 1, indexFrom: Int32(periods.count), basePrice: startPrice)[0]
            periods.append(nextPeriod)
            let newOffset = PeriodsConvertKt.calculateOffsetForZoom(allPeriods: periods, periodsOnScreen: chartLenScreen, centerAroundPeriod: nextPeriod, w: self.width)
            generatePeriodsRects(newOffset, self.width, self.height)
            
            description = "Close: $\(formatPrice(nextPeriod.close))"
            
            return CGFloat(newOffset)
        }
        return defaultOffset
    }
    
    func saveChartState(_ c: PersistentContainer) {
        let fetchRequest = NSFetchRequest<ChartState>(entityName: "ChartState")
        if let chartStates = try? c.context().fetch(fetchRequest) {
            let chartState = (chartStates.isEmpty) ? ChartState(context: c.context()) : chartStates[0]
            chartState.seed = self.seed
            chartState.chartLen = Int32(periods.count - 1)
            c.saveContext(c.context())
        }
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
            
            var s = String(periodDto.high)
            if (s.count > 2) {
                s.insert(".", at: s.index(s.endIndex, offsetBy: -2))
            }
            description = "High: $\(formatPrice(periodDto.high)) Low: $\(formatPrice(periodDto.low))" +
            " -- Open: $\(formatPrice(periodDto.open)) Close: $\(formatPrice(periodDto.close))"
        }
    }
    
    func lastPriceCents() -> Int64 { 
        return periods[periods.count - 1].close
    }
    
    func lastPeriodIndex() -> Int32 {
        return Int32(periods.count - 1)
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
