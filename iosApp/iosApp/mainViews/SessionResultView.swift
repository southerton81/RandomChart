import Foundation
import SwiftUI

struct SessionResultView: View {
    @EnvironmentObject var positionsObservable: PositionsObservableObject
    @EnvironmentObject var chartObservable: ChartObservableObject
    @State var profitPct: String = ""
    @State var profitPctColor: Color = Color.black
    private let initChartCommand: InitChartCommand = InitChartCommand()
    
    var body: some View {
        VStack {
            Text(positionsObservable.endSessionCondition?.rawValue ?? "")
                .bold()
                .padding(20)
                .multilineTextAlignment(.center)
                .font(.custom("AmericanTypewriter", fixedSize: 26))
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .background(Color(.secondarySystemBackground))
                .edgesIgnoringSafeArea(.all)
            
            Text(decimalToString(self.positionsObservable.totalCap, 0) + "$").bold()
                
            Text(self.profitPct)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0)
                .background(Color(.secondarySystemBackground))
                .edgesIgnoringSafeArea(.all)
                .foregroundColor(self.profitPctColor)
            
            Button(action: {
                Task {
                    await initChartCommand.execute(positionsObservable, chartObservable, restoreState: false)
                }
            }) {
                Text("Start new chart")
            }.padding(15).foregroundColor(.white).buttonStyle(PlainButtonStyle()).background(Color.blue).clipShape(RoundedRectangle(cornerRadius:18)).frame(height: 100)
            
        }.background(Color(.secondarySystemBackground))
            .task {
                let profitPct = await positionsObservable.recalculateLastSessionProfitPct(chartObservable.currentPeriod())
                
                await MainActor.run {
                    self.profitPctColor = (profitPct.compare(NSDecimalNumber.zero) == ComparisonResult.orderedAscending) ? Color.red : Color.green
                    self.profitPctColor = (profitPct.compare(NSDecimalNumber.zero) == ComparisonResult.orderedSame) ? Color.black : self.profitPctColor
                    let minimumFracttionalDigits = (profitPct.compare(NSDecimalNumber.zero) == ComparisonResult.orderedSame) ? 1 : 2
                    self.profitPct = decimalToString(profitPct, minimumFracttionalDigits, showSign: true) + "%"
                }
            }
    }
}
