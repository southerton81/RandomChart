import Foundation
import SwiftUI

struct SessionResultView: View {
    @EnvironmentObject var positionsObservable: PositionsObservableObject
    @EnvironmentObject var chartObservable: ChartObservableObject
    @State var profit: String = ""
    
    var body: some View {
        VStack {
            Text(positionsObservable.endSessionCondition?.rawValue ?? "")
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .background(Color(.secondarySystemBackground))
                .edgesIgnoringSafeArea(.all)
            
            Text(self.profit)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .background(Color(.secondarySystemBackground))
                .edgesIgnoringSafeArea(.all)
            
            Button(action: {
                Task {
                   // await self.chartObservable.setupChart(false)
                }
            }) {
                Text("New Session")
            }.padding(10).foregroundColor(.white).buttonStyle(PlainButtonStyle()).background(Color.blue).clipShape(RoundedRectangle(cornerRadius:18))
            
        }.task {
            //await positionsObservable.closeAllPositions(chartObservable.currentPeriod(), chartObservable.currentPeriodIndex())
            let profitPct = await positionsObservable.recalculateTotalSessionProfitPct(chartObservable.currentPeriod())
            await positionsObservable.reduceSessionPositions(chartObservable.currentPeriod(), chartObservable.currentPeriodIndex())
            
            await MainActor.run {
                self.profit = decimalPriceToString(profitPct)
            }
        }
    }
}
