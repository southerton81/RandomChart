import SwiftUI
import CoreData 

extension Position: Identifiable {} // Position entity already have 'id' field required by Identifiable, just conform to this protocol to be able to use it in SwiftUi List()

private let posObservableObject = PositionsObservableObject()

struct PositionsView: View {
    let container: PersistentContainer
    @ObservedObject var positionsObservableObject = posObservableObject
    @ObservedObject var chartObservableObject: ChartObservableObject
    @State private var bottomSheetShown = false
    @State private var isSliding = false
    @State private var positionSizePct: Double = 20
    private var positionSizePctRange: ClosedRange<Double> = 1...100
    
    @FetchRequest(
        entity: Position.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Position.closed, ascending: true),
            NSSortDescriptor(keyPath: \Position.endPeriod, ascending: false)
        ]
    )
    var positions: FetchedResults<Position>
    
    init(_ c: PersistentContainer, _ chartObservable: ChartObservableObject) {
        self.container = c
        self.chartObservableObject = chartObservable
    }
    
    var body: some View {
        
        GeometryReader { geometry in
            
            ZStack {
                
                VStack {
                    Text("Total " + decimalToString(self.positionsObservableObject.totalCap, 0) + "$ Free " + decimalToString(self.positionsObservableObject.freeFunds, 0) + "$")
                        .font(.footnote)
                    
                    List(self.positions
                        .filter({ position in position.startPeriod > 0})
                        .map({ (position) -> UiPosition in
                            return mapToUiPosition(position, self.chartObservableObject.lastPriceCents())
                        }), id: \.self)
                    { uiPosition in
                        Group() {
                            if (uiPosition.action != nil) {
                                HStack {
                                    Text(uiPosition.titleText)
                                    Spacer()
                                    Text(uiPosition.tradeResultText).foregroundColor(uiPosition.tradeResultTextColor)
                                    Spacer()
                                    Text(uiPosition.typeText)
                                    Spacer()
                                    Button(action: {
                                        self.positionsObservableObject.close(self.container, uiPosition.corePosition, self.chartObservableObject.lastPriceCents(),
                                                                             Int32(self.chartObservableObject.lastPeriodIndex()))
                                    }) {
                                        Text(uiPosition.action?.caption ?? "")
                                    }.padding(10).foregroundColor(.white).background(Color.blue).clipShape(RoundedRectangle(cornerRadius: 18)).buttonStyle(PlainButtonStyle())
                                }
                            } else {
                                Text(uiPosition.titleText)
                                Spacer()
                                Text(uiPosition.tradeResultText).foregroundColor(uiPosition.tradeResultTextColor)
                                Spacer()
                                Text(uiPosition.typeText)
                            }
                        }
                    }
                    
                    HStack {
                        Button(action: {
                            self.bottomSheetShown = true
                        }) {
                            Text("Size: " + String(format: "%.0f", self.positionSizePct) + "%")
                        }.padding().foregroundColor(.white).background(Color.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        
                        Spacer()
                        
                        Button(action: {
                            self.positionsObservableObject.openNewPosition(self.container, self.chartObservableObject.lastPriceCents(),
                                                                           self.chartObservableObject.lastPeriodIndex(),
                                                                           isLongPosition: false)
                        }) {
                            Text("Short")
                        }.padding().foregroundColor(.white)
                            .background(self.positionsObservableObject.canOpenNewPos ? Color.red : Color.gray)
                            .clipShape(RoundedRectangle(cornerRadius: 20)).disabled(!self.positionsObservableObject.canOpenNewPos)
                        
                        Button(action: {
                            self.positionsObservableObject.openNewPosition(self.container, self.chartObservableObject.lastPriceCents(),
                                                                           self.chartObservableObject.lastPeriodIndex(),
                                                                           isLongPosition: true)
                        }) {
                            Text("Long")
                        }.padding().foregroundColor(.white)
                            .background(self.positionsObservableObject.canOpenNewPos ? Color.green : Color.gray)
                            .clipShape(RoundedRectangle(cornerRadius: 20)).disabled(!self.positionsObservableObject.canOpenNewPos)
                        
                        Button(action: {
                            currentOffset = self.chartObservableObject.next(currentOffset)
                            self.positionsObservableObject.recalculatePositionSize(self.positionSizePct)
                            self.positionsObservableObject.recalculateFunds(self.container, self.chartObservableObject.lastPriceCents())
                            self.chartObservableObject.saveChartState(self.container)
                        }) {
                            Text("Next")
                        }.padding().foregroundColor(.white).background(Color.blue).clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .padding([.leading, .trailing], 10)
                    .onAppear(perform: {
                        self.positionsObservableObject.recalculateFunds(self.container, self.chartObservableObject.lastPriceCents())
                        self.positionsObservableObject.recalculatePositionSize(self.positionSizePct)
                    })
                    
                    Spacer(minLength: 10)
                }
            }
            
            BottomSheetView(
                isOpen: self.$bottomSheetShown,
                isSliding: self.$isSliding,
                maxHeight: geometry.size.height * 0.5
            ) {
                Text("Position size: " + String(format: "%.0f", self.positionSizePct) + "%")
                Text(decimalToString(self.positionsObservableObject.recalculatePositionSize(self.positionSizePct), 0) + "$")
                Slider(value: self.$positionSizePct, in: self.positionSizePctRange, step: 1) { _ in
                    self.isSliding = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.isSliding = false
                    }
                }.padding()
           }
        }.edgesIgnoringSafeArea(.all)
    }
}

struct BottomSheetView<Content: View>: View {
    @Binding var isOpen: Bool
    @Binding var isSliding: Bool
    
    let maxHeight: CGFloat
    let minHeight: CGFloat
    let content: Content
    
    @GestureState private var translation: CGFloat = 0
    
    private var offset: CGFloat {
        isOpen ? 0 : maxHeight - minHeight
    }
    
    private var indicator: some View {
        RoundedRectangle(cornerRadius: Constants.radius)
            .fill(Color.secondary)
            .frame(
                width: Constants.indicatorWidth,
                height: Constants.indicatorHeight
        ).onTapGesture {
            self.isOpen.toggle()
        }
    }
    
    init(isOpen: Binding<Bool>, isSliding: Binding<Bool>, maxHeight: CGFloat, @ViewBuilder content: () -> Content) {
        self.minHeight = maxHeight * Constants.minHeightRatio
        self.maxHeight = maxHeight
        self.content = content()
        self._isOpen = isOpen
        self._isSliding = isSliding
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                self.indicator.padding()
                self.content
            }
            .frame(width: geometry.size.width, height: self.maxHeight, alignment: .top)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(Constants.radius)
            .frame(height: geometry.size.height, alignment: .bottom)
            .offset(y: max(self.offset + self.translation, 0))
            .animation(.interactiveSpring())
            .padding(.bottom, -Constants.radius * 2)
            .simultaneousGesture(self.isSliding == true ? nil :
                DragGesture().updating(self.$translation) { value, state, _ in
                    state = value.translation.height
                }.onEnded { value in
                    let snapDistance = self.maxHeight * Constants.snapRatio
                    guard abs(value.translation.height) > snapDistance else {
                        return
                    }
                    self.isOpen = value.translation.height < 0
                }
            )
        }
    }
}

fileprivate enum Constants {
    static let radius: CGFloat = 8
    static let indicatorHeight: CGFloat = 8
    static let indicatorWidth: CGFloat = 60
    static let snapRatio: CGFloat = 0.25
    static let minHeightRatio: CGFloat = 0.0
}
