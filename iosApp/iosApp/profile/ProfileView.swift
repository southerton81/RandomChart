import Foundation
import SwiftUI
import CoreData

struct ProfileView: View {
    @EnvironmentObject var profileObservable: ProfileObservableObject
    
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
                Text("Sessions History")
                Spacer()
                
                List(getPostitionsList(), id: \.self)
                { uiPosition in
                    HStack {
                        Text(uiPosition.titleText)
                        Spacer()
                        Text(uiPosition.tradeResultText).foregroundColor(uiPosition.tradeResultTextColor)
                    }
                }.overlay( Group {
                    if (self.positions.count < 2) {
                        ZStack() {
                            Color(.secondarySystemBackground).ignoresSafeArea()
                            Text("No history available yet...")
                        }
                    }
                })
                .listStyle(SidebarListStyle())
            }
        }
    }
    
    private func getPostitionsList() -> [UiPosition] {
        return self.positions
            .dropLast()
            .map({ (position) -> UiPosition in mapToUiPosition(position, 0)})
    }
}
