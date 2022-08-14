import Foundation
import SwiftUI


struct SnackbarModifier: ViewModifier {
    @Binding var state: ErrorState
    
    @State var task: DispatchWorkItem?
    
    func body(content: Content) -> some View {
        ZStack {
            content
            snackbar
        }
    }
    
    private var snackbar: some View {
        VStack {
            Spacer(minLength: 50)
            
            if self.state.title != nil {
                VStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(state.title ?? "")
                                .font(Font.system(size: 15, weight: Font.Weight.light, design: Font.Design.default))
                        }
                        Spacer()
                    }
                    .foregroundColor(Color.white)
                    .padding(12)
                    .background(Color.red)
                    .cornerRadius(8)
                    .shadow(radius: 10)
                    Spacer()
                }
                .padding()
                .animation(.easeInOut(duration: 1.0))
                .transition(AnyTransition.move(edge: .top).combined(with: .opacity))
                .onTapGesture {
                    withAnimation {
                        self.state.title = nil
                    }
                }.onAppear {
                    let dispatchWorkItem = DispatchWorkItem {
                        withAnimation {
                            self.state.title = nil
                        }
                    }
                    self.task = dispatchWorkItem
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: dispatchWorkItem)
                }
                .onDisappear {
                    self.task?.cancel()
                }
            }
        }
    }
}

extension View {
    func snackbar(errorState: Binding<ErrorState>) -> some View {
        self.modifier(SnackbarModifier(state: errorState))
    }
}
