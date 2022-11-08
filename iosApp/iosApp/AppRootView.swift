import Foundation
import SwiftUI
 
struct AppRootView<ChartView: View>: View {
    
    private let mainTabView: MainTabView<ChartView>
    
    @StateObject var positionsObservable: PositionsObservableObject
    @StateObject var chartObservableObject: ChartObservableObject
    
    init(_ c: CoreDataInventory, _ mainTabView: MainTabView<ChartView>) {
        self.mainTabView = mainTabView
        self._positionsObservable = StateObject(wrappedValue: PositionsObservableObject(c))
        self._chartObservableObject = StateObject(wrappedValue: ChartObservableObject(c))
    }
    
    var body: some View {
        ZStack {
            if positionsObservable.endSessionCondition != nil {
                SessionResultView().environmentObject(positionsObservable).zIndex(2)
            }
            self.mainTabView.environmentObject(chartObservableObject).environmentObject(positionsObservable).zIndex(1)
        }.animation(.easeInOut)
    }
}

