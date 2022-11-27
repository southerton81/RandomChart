import Foundation
import SwiftUI
 
struct AppRootView<ChartView: View>: View {
    private let mainTabView: MainTabView<ChartView>
    
    @StateObject var positionsObservable: PositionsObservableObject
    @StateObject var chartObservable: ChartObservableObject
    
    init(_ c: CoreDataInventory, _ mainTabView: MainTabView<ChartView>) {
        self.mainTabView = mainTabView
        self._positionsObservable = StateObject(wrappedValue: PositionsObservableObject(c))
        self._chartObservable = StateObject(wrappedValue: ChartObservableObject(c))
    }
    
    var body: some View {
        ZStack {
            if positionsObservable.endSessionCondition != nil {
                SessionResultView().environmentObject(chartObservable).environmentObject(positionsObservable).zIndex(2)
            }
            self.mainTabView.environmentObject(chartObservable).environmentObject(positionsObservable).zIndex(1)
        }
        .animation(.easeInOut)
    }
}

