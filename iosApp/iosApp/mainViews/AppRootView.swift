import Foundation
import SwiftUI
import CoreData
 
struct AppRootView<ChartView: View, ProfileView: View>: View {
    private let mainTabView: MainTabView<ChartView, ProfileView>
    
    @StateObject var positionsObservable: PositionsObservableObject
    @StateObject var chartObservable: ChartObservableObject
    @StateObject var leadersObservable: LeadersObservableObject
    @StateObject var profileObservable: ProfileObservableObject
    
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
