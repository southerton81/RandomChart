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
                    Text("Total capital " + decimalToString(self.positionsObservable.totalCap, 0) +
                         "$   Free funds " + decimalToString(self.positionsObservable.freeFunds, 0) + "$")
                        .font(.footnote)
                    
                    if (!self.positions.isEmpty) {
                        positionsList.animation(nil)
                    } else {
                        Color.clear
                    }
                    
                    buttons.background(Color(.systemBackground)).edgesIgnoringSafeArea(.all).animation(nil)
                    Spacer(minLength: 10)
                }
                .onChange(of: self.positionSizePct) { _ in
                    self.positionsObservable.recalculatePositionSize(self.positionSizePct)
                }
                .onAppear {
                    self.positionSizePct = self.positionsObservable.positionSizePct
                }
            }.background(Color(.systemBackground))
            
            PositionSizeBottomSheetView(
                isOpen: self.$bottomSheetShown,
                isSliding: self.$isSliding,
                maxHeight: geometry.size.height * 0.5
            ) {
                Text("Position size (percent from total capital)").font(Font.callout.weight(.thin))
                Text(String(format: "%.0f", self.positionsObservable.positionSizePct) + "%").font(Font.headline.weight(.black))
                Text(decimalToString(self.positionsObservable.positionSize, 0) + "$").font(Font.callout.weight(.thin))
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
                    }.padding(10).foregroundColor(.white).buttonStyle(PlainButtonStyle()).background(Color(UIColor.tintColor)).clipShape(RoundedRectangle(cornerRadius:18))
                         .disabled(self.positionsObservable.calculating)
                }
            }
        }.listStyle(SidebarListStyle())
    }
    
    var buttons: some View {
        HStack {
            Button(action: { self.bottomSheetShown = true }) {
                Text("Size: " + String(format: "%.0f", self.positionsObservable.positionSizePct) + "%")
            }.padding().foregroundColor(.white).buttonStyle(PlainButtonStyle()).background(Color(UIColor.systemIndigo)).clipShape(RoundedRectangle(cornerRadius: 20))
            
            Spacer()
            
            Button(action: {
                shortCommand.execute(positionsObservable, chartObservable)
            }) {
                Text("Short")
            }.padding().foregroundColor(.white).buttonStyle(PlainButtonStyle()) .background(Color(UIColor.systemRed)).clipShape(RoundedRectangle(cornerRadius: 20))
                .disabled(!self.positionsObservable.canOpenNewPos || self.positionsObservable.calculating)
            
            Button(action: {
                longCommand.execute(positionsObservable, chartObservable)
            }) {
                Text("Long")
            }.padding().foregroundColor(.white).buttonStyle(PlainButtonStyle()).background(Color(UIColor.systemGreen)).clipShape(RoundedRectangle(cornerRadius: 20))
                .disabled(!self.positionsObservable.canOpenNewPos || self.positionsObservable.calculating)
            
            Button(action: {
                nextCommand.execute(positionsObservable, chartObservable)
            }) {
                Text("Next")
            }.padding().foregroundColor(.white).buttonStyle(PlainButtonStyle()).background(Color(UIColor.tintColor)).clipShape(RoundedRectangle(cornerRadius: 20))
                .disabled(self.positionsObservable.calculating)
        }
        .padding([.leading, .trailing], 10)
        .disabled(self.positionsObservable.endSessionCondition != nil)
    }
}
