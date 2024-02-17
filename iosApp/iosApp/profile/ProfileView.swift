import Foundation
import SwiftUI
import CoreData

struct ProfileView: View {
    @EnvironmentObject var profileObservable: ProfileObservableObject
    @EnvironmentObject var chartObservable: ChartObservableObject
    @EnvironmentObject var positionsObservable: PositionsObservableObject
    private let resetCommand: ResetCommand = ResetCommand()
    @State private var clicked = false
    
    @FetchRequest(fetchRequest: positionsRequest()) private var positions: FetchedResults<Position>
    static func positionsRequest() -> NSFetchRequest<Position> {
        let fetchPostitions = NSFetchRequest<Position>(entityName: "Position")
        fetchPostitions.sortDescriptors = [
            NSSortDescriptor(keyPath: \Position.closed, ascending: true),
            NSSortDescriptor(keyPath: \Position.creationDate, ascending: false)
        ]
        fetchPostitions.predicate = NSPredicate(format: "%K == -1", #keyPath(Position.startPeriod))
        return fetchPostitions
    } 
    
    var body: some View {
        ZStack(alignment: .center) {
            VStack(spacing: 0) {
                Spacer()
                Text(StringConstants.tradeResult)
                Spacer()
                
                if self.positions.count >= 2 {
                    captionedList
                } else {
                    list
                }
                Spacer()
                
                Button(action: {
                    clicked = true
                    resetCommand.execute(positionsObservable, chartObservable)
                }) {
                    Text("End current game").lineLimit(1).minimumScaleFactor(0.8)
                }.padding().foregroundColor(.white)
                    .font(.system(.body,design: .rounded).weight(.semibold))
                    .buttonStyle(PlainButtonStyle()).background(Color(UIColor.tintColor))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .disabled(clicked)
                Spacer()
                Text(StringConstants.version).font(.system(size: 10))
                Spacer()
            }
        }.onAppear {
            clicked = false
        }
    }
    
    var list: some View {
        List {
            ForEach(getPostitionsList(), id: \.self) { uiPosition in
                HStack {
                    HStack(spacing: 0) {
                        Group {
                            Text(uiPosition.titleText)
                            Text("$").foregroundColor(Color(UIColor.tertiaryLabel))
                        }
                    }
                    Spacer()
                    Text(uiPosition.tradeResultText).foregroundColor(uiPosition.tradeResultTextColor)
                }
            }
        }.overlay( Group {
            if (self.positions.count < 2) {
                ZStack() {
                    Color(.secondarySystemBackground).ignoresSafeArea()
                    Text(StringConstants.noHistory)
                }
            }
        })
    }
    
    var captionedList: some View {
        List {
            Section(header:  HStack {
                Text(StringConstants.capital)
                Spacer()
                Text(StringConstants.result)
            }) {
                ForEach(getPostitionsList(), id: \.self) { uiPosition in
                    HStack {
                        HStack(spacing: 0) {
                            Group {
                                Text(uiPosition.titleText)
                                Text("$").foregroundColor(Color(UIColor.tertiaryLabel))
                            }
                        }
                        Spacer()
                        Text(uiPosition.tradeResultText).foregroundColor(uiPosition.tradeResultTextColor)
                    }
                }
            }
        }
    }
    
    private func getPostitionsList() -> [UiPosition] {
        return self.positions
            .dropLast()
            .map({ (position) -> UiPosition in mapToUiClosedPosition(position) })
    }
}
