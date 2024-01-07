import Foundation
import SwiftUI
import CoreData

struct SessionResultView: View {
    @Binding var tabSelection: Int
    @EnvironmentObject var positionsObservable: PositionsObservableObject
    @EnvironmentObject var chartObservable: ChartObservableObject
    @State var profitPct: String = ""
    @State var profitPctColor: Color = Color.black
    private let initChartCommand: InitChartCommand = InitChartCommand()
    
    @FetchRequest(fetchRequest: positionsRequest()) var positions: FetchedResults<Position>
  
    static func positionsRequest() -> NSFetchRequest<Position> {
        let fetchPostitions = NSFetchRequest<Position>(entityName: "Position")
        fetchPostitions.sortDescriptors = []
        fetchPostitions.predicate = NSPredicate(format: "%K != -1", #keyPath(Position.startPeriod))
        return fetchPostitions
    }
    
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
                    self.tabSelection = 1
                    await initChartCommand.execute(
                        positionsObservable,
                        chartObservable,
                        positions,
                        restoreState: false)
                }
            }) {
                Text(StringConstants.newChart)
            }.padding(15).foregroundColor(.white).buttonStyle(PlainButtonStyle()).background(Color.blue).clipShape(RoundedRectangle(cornerRadius:18)).frame(height: 100)
            
        }.background(Color(.secondarySystemBackground))
            .task {
                let profitPct = await positionsObservable.recalculateLastSessionProfitPct(chartObservable.currentPeriod())
                
                await MainActor.run {
                    self.profitPctColor = (profitPct.compare(NSDecimalNumber.zero) == ComparisonResult.orderedAscending) ? Color.red : Color.green
                    self.profitPctColor = (profitPct.compare(NSDecimalNumber.zero) == ComparisonResult.orderedSame) ? Color.gray : self.profitPctColor
                    let minimumFracttionalDigits = (profitPct.compare(NSDecimalNumber.zero) == ComparisonResult.orderedSame) ? 1 : 2
                    self.profitPct = decimalToString(profitPct, minimumFracttionalDigits, showSign: true) + "%"
                }
            }
    }
}
