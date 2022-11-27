import SwiftUI
import CoreData

struct PositionsView: View {
    @EnvironmentObject var positionsObservable: PositionsObservableObject
    @EnvironmentObject var chartObservable: ChartObservableObject
    @State private var bottomSheetShown = false
    @State private var isSliding = false // Prevent BottomSheetView drag gesture from interacting with the Slider
    @State var positionSizePct: Double = 0
    @State private var positionSizePctRange: ClosedRange<Double> = 1...100
    private let nextCommand: NextCommand
    private let longCommand: LongCommand
    private let shortCommand: ShortCommand
    private let closeCommand: ClosePositionCommand

    @FetchRequest(fetchRequest: positionsRequest()) private var positions: FetchedResults<Position>

    static func positionsRequest() -> NSFetchRequest<Position> {
        let fetchPostitions = NSFetchRequest<Position>(entityName: "Position")
        fetchPostitions.sortDescriptors = [
            NSSortDescriptor(keyPath: \Position.closed, ascending: true),
            NSSortDescriptor(keyPath: \Position.endPeriod, ascending: false),
            NSSortDescriptor(keyPath: \Position.creationDate, ascending: false)
        ]
        fetchPostitions.predicate = NSPredicate(format: "%K != -1", #keyPath(Position.startPeriod))
        return fetchPostitions
    }
    
    init() {
        self.nextCommand = NextCommand()
        self.longCommand = LongCommand()
        self.shortCommand = ShortCommand()
        self.closeCommand = ClosePositionCommand()
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    Text("Total " + decimalPriceToString(self.positionsObservable.totalCap, 0) +
                         "$ Free " + decimalPriceToString(self.positionsObservable.freeFunds, 0) + "$")
                        .font(.footnote)
                    positionsList.animation(nil)
                    buttons.background(Color(.secondarySystemBackground)).edgesIgnoringSafeArea(.all).animation(nil)
                    Spacer(minLength: 10)
                }
                .background(Color(.secondarySystemBackground))
                .onChange(of: self.positionSizePct) { _ in
                    self.positionsObservable.recalculatePositionSize(self.positionSizePct)
                }
                .onAppear {
                    self.positionSizePct = self.positionsObservable.positionSizePct
                }
            }
            
            BottomSheetView(
                isOpen: self.$bottomSheetShown,
                isSliding: self.$isSliding,
                maxHeight: geometry.size.height * 0.5
            ) {
                Text("Position size: " + String(format: "%.0f", self.positionsObservable.positionSizePct) + "%")
                Text(decimalPriceToString(self.positionsObservable.positionSize, 0) + "$")
                Slider(value: self.$positionSizePct, in: self.positionSizePctRange, step: 1) { _ in
                    self.isSliding = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.isSliding = false
                    }
                }.padding()
            }
        }
    }
    
    var positionsList: some View {
        List(self.positions
            .map({ (position) -> UiPosition in mapToUiPosition(position, self.chartObservable.currentPriceCents())}), id: \.self)
        { uiPosition in
            HStack {
                Text(uiPosition.titleText)
                Spacer()
                Text(uiPosition.tradeResultText).foregroundColor(uiPosition.tradeResultTextColor)
                Spacer()
                Text(uiPosition.typeText)
              
                if (uiPosition.action != nil) {
                    Spacer()
                    Button(action: {
                        closeCommand.execute(positionsObservable, chartObservable, uiPosition.id)
                    }) {
                        Text(uiPosition.action?.caption ?? "")
                    }.padding(10).foregroundColor(.white).buttonStyle(PlainButtonStyle()).background(Color.blue).clipShape(RoundedRectangle(cornerRadius:18))
                         .disabled(self.positionsObservable.calculating)
                }
            }
        }.listStyle(SidebarListStyle())
    }
    
    var buttons: some View {
        HStack {
            Button(action: { self.bottomSheetShown = true }) {
                Text("Size: " + String(format: "%.0f", self.positionsObservable.positionSizePct) + "%")
            }.padding().foregroundColor(.white).buttonStyle(PlainButtonStyle()).background(Color.orange).clipShape(RoundedRectangle(cornerRadius: 20))
            
            Spacer()
            
            Button(action: {
                shortCommand.execute(positionsObservable, chartObservable)
            }) {
                Text("Short")
            }.padding().foregroundColor(.white).buttonStyle(PlainButtonStyle()) .background(Color.red).clipShape(RoundedRectangle(cornerRadius: 20))
                .disabled(!self.positionsObservable.canOpenNewPos || self.positionsObservable.calculating)
            
            Button(action: {
                longCommand.execute(positionsObservable, chartObservable)
            }) {
                Text("Long")
            }.padding().foregroundColor(.white).buttonStyle(PlainButtonStyle()).background(Color.green).clipShape(RoundedRectangle(cornerRadius: 20))
                .disabled(!self.positionsObservable.canOpenNewPos || self.positionsObservable.calculating)
            
            Button(action: {
                nextCommand.execute(positionsObservable, chartObservable)
            }) {
                Text("Next")
            }.padding().foregroundColor(.white).buttonStyle(PlainButtonStyle()).background(Color("NextButtonBckgndColor")).clipShape(RoundedRectangle(cornerRadius: 20))
                .disabled(self.positionsObservable.calculating)
        }
        .padding([.leading, .trailing], 10)
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
            RoundedRectangle(cornerRadius: BottomSheetConstants.radius)
                .fill(Color.secondary)
                .frame(
                    width: BottomSheetConstants.indicatorWidth,
                    height: BottomSheetConstants.indicatorHeight
                ).onTapGesture {
                    self.isOpen.toggle()
                }
        }
        
        init(isOpen: Binding<Bool>, isSliding: Binding<Bool>, maxHeight: CGFloat, @ViewBuilder content: () -> Content) {
            self.minHeight = 0
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
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(BottomSheetConstants.radius)
                .frame(height: geometry.size.height, alignment: .bottom)
                .offset(y: max(self.offset + self.translation, 0))
                .animation(.interactiveSpring())
                .padding(.bottom, -BottomSheetConstants.radius * 2)
                .simultaneousGesture(self.isSliding == true ? nil :
                                        DragGesture().updating(self.$translation) { value, state, _ in
                    state = value.translation.height
                }.onEnded { value in
                    let snapDistance = self.maxHeight * BottomSheetConstants.snapRatio
                    guard abs(value.translation.height) > snapDistance else {
                        return
                    }
                    self.isOpen = value.translation.height < 0
                })
            }
        }
    }
    
    fileprivate enum BottomSheetConstants {
        static let radius: CGFloat = 16
        static let indicatorHeight: CGFloat = 4
        static let indicatorWidth: CGFloat = 60
        static let snapRatio: CGFloat = 0.25
    }
}
