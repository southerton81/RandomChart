import SwiftUI 

var lastDrag: CGFloat? = nil
var lastMagnitude: CGFloat? = nil
var currentOffset: CGFloat = 0

struct ChartView: View {
    @EnvironmentObject var chartObservable: ChartObservableObject
    @EnvironmentObject var positionsObservable: PositionsObservableObject
    let positionsView: PositionsView
    private let resetCommand: ResetCommand = ResetCommand()
     
    init(_ positionsView: PositionsView) {
        self.positionsView = positionsView
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Text(self.chartObservable.description).font(.system(size: 12))
            chartView()
            positionsView
        }
        .background(Color.white)
    }
    
    func chartView() -> some View {
        return GeometryReader { (geometry) in
            ZStack {
                drawGrid(geometry.size.width, geometry.size.height).stroke(Color.gray, lineWidth: 0.2)
                
                Path { path in
                    chartObservable.allPeriods.forEach { rc in
                        let x = rc.minX + ((rc.maxX - rc.minX) / 2)
                        path.move(to: CGPoint(x: x, y: rc.minY))
                        path.addLine(to: CGPoint(x: x, y: rc.maxY))
                    }
                }.stroke(Color.black, lineWidth: 1)
                
                Path { path in
                    path.addRects(chartObservable.upPeriods)
                }.fill(Color.green)
                
                Path { path in
                    path.addRects(chartObservable.downPeriods)
                }.fill(Color.red)
                
                if (self.chartObservable.selectedIndex >= 0) {
                    Path { path in
                        let selected = chartObservable.allPeriods[self.chartObservable.selectedIndex]
                        path.addRect(selected)
                    }.stroke(Color.gray, lineWidth: 2)
                }
            }
            .background(Color.white)
            .gesture(
                MagnificationGesture(minimumScaleDelta: 0.01)
                    .onChanged { action in
                        let difference = action.magnitude - (lastMagnitude ?? action.magnitude)
                        
                        if (difference != 0) {
                            let zoom: Int32 = difference > 0 ? 10 : -10
                            currentOffset = self.chartObservable.zoom(Float(currentOffset), Float(geometry.size.width), Float(geometry.size.height), zoom)
                        }
                        
                        lastMagnitude = action.magnitude
                        lastDrag = nil
                }
                .onEnded { action in
                    self.chartObservable.endZoom()
                    lastMagnitude = nil
                })
            .simultaneousGesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onEnded { action in
                        lastDrag = nil
                        let d = sqrt(pow(action.translation.height, 2) + pow(action.translation.width, 2))
                        if (d < 3) {
                            self.chartObservable.selectPeriod(x: Float(action.location.x))
                        }
                    }.onChanged { action in
                        self.chartObservable.endZoom()
                        currentOffset = max(CGFloat(self.chartObservable.offsetLimitRange.startIndex), currentOffset + (lastDrag ?? 0) - action.translation.width)
                        currentOffset = min(currentOffset, CGFloat(self.chartObservable.offsetLimitRange.endIndex))
                        lastDrag = action.translation.width
                        self.chartObservable.generatePeriodsRects(Float(currentOffset))
                    })
            .task {
                if (self.chartObservable.isChartEmpty()) {
                    self.chartObservable.setSize(Float(geometry.size.width), Float(geometry.size.height))
                    await resetCommand.execute(positionsObservable, chartObservable)
                }
            }
        }
    }
    
    func drawGrid(_ w: CGFloat, _ h: CGFloat) -> Path {
        return Path { path in
            let shift = CGFloat(Int(currentOffset) % Int(w))
            let stepHor = w / 3
            let stepVer = h / 8
            
            for i in stride(from: stepHor, to: w * 2, by: stepHor) {
                path.move(to: CGPoint(x: i - shift, y: 0))
                path.addLine(to: CGPoint(x: i - shift, y: h))
            }
            
            for i in stride(from: stepVer, to: h, by: stepVer) {
                path.move(to: CGPoint(x: 0, y: i))
                path.addLine(to: CGPoint(x: w, y: i))
            }
        }
    }
}
