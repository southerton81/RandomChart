import Foundation
import SwiftUI
import CoreData
 
struct AppRootView<ChartView: View, ProfileView: View>: View {
    private let mainTabView: MainTabView<ChartView, ProfileView>
    
    @StateObject var positionsObservable: PositionsObservableObject
    @StateObject var chartObservable: ChartObservableObject
    @StateObject var leadersObservable: LeadersObservableObject
    @StateObject var profileObservable: ProfileObservableObject
    
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
    
    init(_ c: CoreDataInventory, _ mainTabView: MainTabView<ChartView, ProfileView>) {
        self.mainTabView = mainTabView
        self._positionsObservable = StateObject(wrappedValue: PositionsObservableObject(c))
        self._chartObservable = StateObject(wrappedValue: ChartObservableObject(c))
        self._leadersObservable = StateObject(wrappedValue: LeadersObservableObject(c))
        self._profileObservable = StateObject(wrappedValue: ProfileObservableObject(c))
    }
    
    var body: some View {
        ZStack {
            if positionsObservable.endSessionCondition != nil {
                SessionResultView()
                    .environmentObject(chartObservable)
                    .environmentObject(positionsObservable)
                    .zIndex(2)
                    .deferredRendering(seconds: 1.0)
            }
            self.mainTabView
                .environmentObject(chartObservable)
                .environmentObject(positionsObservable)
                .environmentObject(leadersObservable)
                .environmentObject(profileObservable)
                .zIndex(1)
        }
        .animation(.easeInOut)
    }
}
