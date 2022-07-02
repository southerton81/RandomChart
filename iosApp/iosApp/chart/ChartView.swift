import SwiftUI 

var lastDrag: CGFloat? = nil
var lastMagnitude: CGFloat? = nil
var currentOffset: CGFloat = 0

struct ChartView: View {
    @ObservedObject var chartObservableObject: ChartObservableObject
    let positionsView: PositionsView
    
    init(_ positionsView: PositionsView, _ chartObservable: ChartObservableObject) {
        self.chartObservableObject = chartObservable
        self.positionsView = positionsView
    }
    
    var body: some View {
        VStack {
            Text(self.chartObservableObject.description).font(.system(size: 12))
            self.makeChart()
            positionsView
        }
        .background(Color.white)
    }
    
    func makeChart() -> some View {
        return GeometryReader { (geometry) in
            ZStack {
                Path { path in
                    self.chartObservableObject.allPeriods.forEach { rc in
                        let x = rc.minX + ((rc.maxX - rc.minX) / 2)
                        path.move(to: CGPoint(x: x, y: rc.minY))
                        path.addLine(to: CGPoint(x: x, y: rc.maxY))
                    }
                }.stroke(Color.black, lineWidth: 1)
                
                Path { path in
                    path.addRects(self.chartObservableObject.upPeriods)
                }.fill(Color.green)
                
                Path { path in
                    path.addRects(self.chartObservableObject.downPeriods)
                }.fill(Color.red)
                
                if (self.chartObservableObject.selectedIndex >= 0) {
                    Path { path in
                        let selected = self.chartObservableObject.allPeriods[self.chartObservableObject.selectedIndex]
                        path.addRect(selected)
                    }.stroke(Color.gray, lineWidth: 2)
                }
            }
            .onAppear(perform: {
                self.chartObservableObject.generatePeriodsRects(0, Float(geometry.size.width), Float(geometry.size.height))
                currentOffset = self.chartObservableObject.next(currentOffset)
            })
            .background(Color.white)
            .gesture(
                MagnificationGesture(minimumScaleDelta: 0.01)
                    .onChanged { action in
                        let difference = action.magnitude - (lastMagnitude ?? action.magnitude)
                        
                        if (difference != 0) {
                            let zoom: Int32 = difference > 0 ? 10 : -10
                            currentOffset = self.chartObservableObject.zoom(Float(currentOffset), Float(geometry.size.width), Float(geometry.size.height), zoom)
                        }
                        
                        lastMagnitude = action.magnitude
                        lastDrag = nil
                }
                .onEnded { action in
                    self.chartObservableObject.endZoom()
                    lastMagnitude = nil
                })
            .simultaneousGesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onEnded { action in
                        lastDrag = nil
                        let d = sqrt(pow(action.translation.height, 2) + pow(action.translation.width, 2))
                        if (d < 3) {
                            self.chartObservableObject.selectPeriod(x: Float(action.location.x))
                        }
                    }.onChanged { action in
                        self.chartObservableObject.endZoom()
                        currentOffset = max(CGFloat(self.chartObservableObject.offsetLimitRange.startIndex), currentOffset + (lastDrag ?? 0) - action.translation.width)
                        currentOffset = min(currentOffset, CGFloat(self.chartObservableObject.offsetLimitRange.endIndex))
                        lastDrag = action.translation.width
                        self.chartObservableObject.generatePeriodsRects(Float(currentOffset), Float(geometry.size.width), Float(geometry.size.height))
                    })
        }
    }
}
