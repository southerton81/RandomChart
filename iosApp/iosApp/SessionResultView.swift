import Foundation
import SwiftUI


struct SessionResultView: View {
    @EnvironmentObject var positionsObservable: PositionsObservableObject
    
    var body: some View {
        
        VStack {
            Text(positionsObservable.endSessionCondition?.rawValue ?? "")
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .background(Color(.secondarySystemBackground))
                .edgesIgnoringSafeArea(.all)
        } .onAppear(perform: {
           
            //positionsObservable.recalculateFunds()
            //chartObservableObject.reset()
        })
    }
}
