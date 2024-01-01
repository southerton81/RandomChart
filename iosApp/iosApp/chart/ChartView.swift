import SwiftUI
import CoreData

struct ChartView: View {
    @EnvironmentObject var chartObservable: ChartObservableObject
    @EnvironmentObject var positionsObservable: PositionsObservableObject
    let positionsView: PositionsView = PositionsView()
    private let initChartCommand: InitChartCommand = InitChartCommand()
    @FetchRequest(fetchRequest: positionsRequest()) var positions: FetchedResults<Position>
    
    static func positionsRequest() -> NSFetchRequest<Position> {
        let fetchPostitions = NSFetchRequest<Position>(entityName: "Position")
        fetchPostitions.sortDescriptors = []
        fetchPostitions.predicate = NSPredicate(format: "%K != -1", #keyPath(Position.startPeriod))
        return fetchPostitions
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Text(self.chartObservable.description).font(.footnote)
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.systemBackground))
            chartView()
            positionsView
        }
        .background(Color.white)
    }
    
    func chartView() -> some View {
        return GeometryReader { (geometry) in
            ZStack {
                drawGrid(geometry.size.width, geometry.size.height).stroke(Color(UIColor.systemGray), lineWidth: 0.2)
                
                Path { path in
                    chartObservable.fullPeriodsDown.forEach { rc in
                        let x = rc.minX + ((rc.maxX - rc.minX) / 2)
                        path.move(to: CGPoint(x: x, y: rc.minY))
                        path.addLine(to: CGPoint(x: x, y: rc.maxY))
                    }
                }.stroke(Color(UIColor.systemRed), lineWidth: 1)
                
                Path { path in
                    chartObservable.fullPeriodsUp.forEach { rc in
                        let x = rc.minX + ((rc.maxX - rc.minX) / 2)
                        path.move(to: CGPoint(x: x, y: rc.minY))
                        path.addLine(to: CGPoint(x: x, y: rc.maxY))
                    }
                }.stroke(Color(UIColor.systemGreen), lineWidth: 1)
                
                Path { path in
                    path.addRects(chartObservable.upPeriods)
                }.fill(Color(UIColor.systemGreen))
                
                Path { path in
                    path.addRects(chartObservable.downPeriods)
                }.fill(Color(UIColor.systemRed))
                
                Path { path in
                    self.chartObservable.positionsDecoration.forEach { lineDecoration in
                        lineDecoration.toPath(&path)
                    }
                }.stroke(Color(UIColor.secondaryLabel), lineWidth: 3)
                
                if (self.chartObservable.selectedIndex >= 0) {
                    Path { path in
                        let selected = chartObservable.fullPeriods[self.chartObservable.selectedIndex].fullRect
                        path.addRect(selected)
                    }.stroke(Color(UIColor.systemGray), lineWidth: 2)
                }
            }
            .background(Color(UIColor.systemBackground))
            .gesture(
                MagnificationGesture(minimumScaleDelta: 0.01)
                    .onChanged { action in
                        let difference = action.magnitude - (ChartUiState.shared.lastMagnitude ?? action.magnitude)
                        
                        if (difference != 0) {
                            let zoom: Int32 = difference > 0 ? 2 : -2
                            ChartUiState.shared.currentOffset = self.chartObservable.zoom(Float(geometry.size.width), zoom, positions)
                        }
                        
                        ChartUiState.shared.lastMagnitude = action.magnitude
                        ChartUiState.shared.lastDrag = nil
                }
                .onEnded { action in
                    self.chartObservable.endZoom()
                    ChartUiState.shared.lastMagnitude = nil
                })
            .simultaneousGesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onEnded { action in
                        ChartUiState.shared.lastDrag = nil
                        let d = sqrt(pow(action.translation.height, 2) + pow(action.translation.width, 2))
                        if (d < 3) {
                            self.chartObservable.selectPeriod(x: Float(action.location.x))
                        }
                    }.onChanged { action in
                        self.chartObservable.endZoom()
                        ChartUiState.shared.currentOffset = max(CGFloat(self.chartObservable.offsetLimitRange.startIndex),
                                                                ChartUiState.shared.currentOffset + (ChartUiState.shared.lastDrag ?? 0) - action.translation.width)
                        ChartUiState.shared.currentOffset = min(ChartUiState.shared.currentOffset, CGFloat(self.chartObservable.offsetLimitRange.endIndex))
                        ChartUiState.shared.lastDrag = action.translation.width
                        self.chartObservable.generatePeriodsRects(Float(ChartUiState.shared.currentOffset), positions)
                    })
            .task {
                if (self.chartObservable.isChartEmpty()) {
                    self.chartObservable.setSize(Float(geometry.size.width), Float(geometry.size.height))
                    await initChartCommand.execute(
                        positionsObservable,
                        chartObservable,
                        positions,
                        restoreState: true)
                }
            }
        }
    }
    
    func drawGrid(_ w: CGFloat, _ h: CGFloat) -> Path {
        return Path { path in
            let shift = CGFloat(Int(ChartUiState.shared.currentOffset) % Int(w))
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
