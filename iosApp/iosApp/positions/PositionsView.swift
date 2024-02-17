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
    private let showPositionCommand: ShowPositionCommand
        
    @FetchRequest(fetchRequest: positionsRequest()) var positions: FetchedResults<Position>
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
        self.showPositionCommand = ShowPositionCommand()
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    
                    HStack {
                        Group {
                            Text(StringConstants.totalCapital)
                                .foregroundColor(Color(UIColor.secondaryLabel)).font(Font.callout.weight(.thin))
                            
                            Text(decimalToString(self.positionsObservable.totalCap, 0))
                                .foregroundColor(Color(UIColor.secondaryLabel))
                                .fontWeight(.heavy) +
                            Text("$")
                                .foregroundColor(Color(UIColor.secondaryLabel))
                            
                            Text(StringConstants.freeCapital)
                                .foregroundColor(Color(UIColor.secondaryLabel)).font(Font.callout.weight(.thin))
                            
                            Text(decimalToString(self.positionsObservable.freeFunds, 0))
                                .foregroundColor(Color(UIColor.secondaryLabel))
                                .fontWeight(.bold) +
                            Text("$")
                                .foregroundColor(Color(UIColor.secondaryLabel))
                        }
                    }
                    
                    HStack {
                        Group {
                            Text(StringConstants.pNl)
                                .foregroundColor(Color(UIColor.secondaryLabel)).font(Font.callout.weight(.thin))
                            Text(decimalToString(self.positionsObservable.currentSessionResultPct) + "%")
                                .foregroundColor(Color(UIColor.secondaryLabel)).fontWeight(.bold)
                        }
                    }
                    
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
                Text(StringConstants.positionSize).font(Font.callout.weight(.thin))
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
        List {
            if let openPositions = getOpenPositions() {
                Section(header:  HStack {
                    Text(StringConstants.openPositions)
                }) {
                    ForEach(openPositions, id: \.self) { uiPosition in
                        HStack {
                            Text(uiPosition.titleText).font(.system(.body,design: .rounded).weight(.medium))
                            Spacer()
                            TradeResult(uiPosition.positionValueText, uiPosition.tradeResultText, uiPosition.tradeResultTextColor)
                            Spacer()
                            Text(uiPosition.typeText).font(.system(.body,design: .rounded).weight(.light))
                            
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
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showPositionCommand.execute(self.chartObservable,
                                                        uiPosition.startPeriod,
                                                        uiPosition.endPeriod,
                                                        positions)
                        }
                    }
                }
            }
            
            if let closedPositions = getClosedPositions() {
                Section(header:  HStack {
                    Text(StringConstants.closedPositions)
                }) {
                    ForEach(closedPositions, id: \.self) { uiPosition in
                        HStack {
                            Text(uiPosition.titleText).font(.system(.body,design: .rounded).weight(.medium))
                            Spacer()
                            TradeResult(uiPosition.positionValueText, uiPosition.tradeResultText, uiPosition.tradeResultTextColor)
                            Spacer()
                            Text(uiPosition.typeText).font(.system(.body,design: .rounded).weight(.light))
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showPositionCommand.execute(self.chartObservable,
                                                        uiPosition.startPeriod,
                                                        uiPosition.endPeriod,
                                                        positions)
                
                        }
                    }
                }
            }
        }
    }
    
    
    struct TradeResult: View {
        var positionValueText: String = ""
        var tradeResultText: String = ""
        var tradeResultTextColor: Color = Color(UIColor.label)
        
        init(_ positionValueText: String, _ tradeResultText: String, _ tradeResultTextColor: Color) {
            self.positionValueText = positionValueText
            self.tradeResultText = tradeResultText
            self.tradeResultTextColor = tradeResultTextColor
        }
        
        var body: some View {
            VStack {
                Text(tradeResultText).foregroundColor(tradeResultTextColor).font(.system(.body,design: .rounded).weight(.medium))
                HStack(spacing: 0) {
                    Group {
                        Text(positionValueText).foregroundColor(Color(UIColor.secondaryLabel)).font(.footnote)
                        Text("$").foregroundColor(Color(UIColor.tertiaryLabel)).font(.footnote)
                    }
                }
            }
        }
    }
    
    private func getOpenPositions() -> Array<UiPosition>? {
        let openPositions = self.positions.filter({ !$0.closed })
        if (openPositions.isEmpty) {
            return nil
        }
        else {
            return openPositions.map({ (position) -> UiPosition in
                mapToUiPosition(position, self.chartObservable.currentPriceCents())
            })
        }
    }
    
    private func getClosedPositions() -> Array<UiPosition>? {
        let closedPositions = self.positions.filter({ $0.closed })
        if (closedPositions.isEmpty) {
            return nil
        }
        else {
            return closedPositions.map({ (position) -> UiPosition in
                mapToUiPosition(position, self.chartObservable.currentPriceCents())
            })
        }
    }
    
    var buttons: some View {
        HStack {
            Button(action: { self.bottomSheetShown = true }) {
                Text(StringConstants.sizeTitle + String(format: "%.0f", self.positionsObservable.positionSizePct) + "%").lineLimit(1).minimumScaleFactor(0.8)
            }.padding().foregroundColor(.white)
                .font(.system(.body,design: .rounded).weight(.medium))
                .buttonStyle(PlainButtonStyle()).background(Color(UIColor.tintColor)).clipShape(RoundedRectangle(cornerRadius: 20))
            
            Spacer()
            
            Button(action: {
                shortCommand.execute(positionsObservable, chartObservable)
            }) {
                Text(StringConstants.shortBtnTitle).lineLimit(1).minimumScaleFactor(0.8)
            }.padding().foregroundColor(.white)
                .font(.system(.body,design: .rounded).weight(.medium))
                .buttonStyle(PlainButtonStyle()).background(Color(UIColor.systemRed)).clipShape(RoundedRectangle(cornerRadius: 20))
                .disabled(!self.positionsObservable.canOpenNewPos || self.positionsObservable.calculating)
            
            Button(action: {
                longCommand.execute(positionsObservable, chartObservable)
            }) {
                Text(StringConstants.longBtnTitle).lineLimit(1).minimumScaleFactor(0.8)
            }.padding().foregroundColor(.white)
                .font(.system(.body,design: .rounded).weight(.medium))
                .buttonStyle(PlainButtonStyle()).background(Color(UIColor.systemGreen)).clipShape(RoundedRectangle(cornerRadius: 20))
                .disabled(!self.positionsObservable.canOpenNewPos || self.positionsObservable.calculating)
            
            Button(action: {
                nextCommand.execute(positionsObservable, chartObservable, positions)
            }) {
                Text(StringConstants.nextBtnTitle).lineLimit(1).minimumScaleFactor(0.8)
            }.padding().foregroundColor(.white)
                .font(.system(.body,design: .rounded).weight(.semibold))
                .buttonStyle(PlainButtonStyle()).background(Color(UIColor.tintColor)).clipShape(RoundedRectangle(cornerRadius: 20))
                .disabled(self.positionsObservable.calculating)
        }
        .padding([.leading, .trailing], 10)
        .disabled(self.positionsObservable.endSessionCondition != nil)
    }
}
