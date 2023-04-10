import Foundation
import SwiftUI

extension View { 
    func navigate<NewView: View>(to view: NewView, when binding: Binding<Bool>) -> some View {
        NavigationView {
            ZStack {
                self
                    .navigationBarTitle("")
                    .navigationBarHidden(true)

                NavigationLink(
                    destination: view
                        .navigationBarTitle("")
                        .navigationBarHidden(true),
                    isActive: binding
                ) {
                    EmptyView()
                }
            }
        }
        .navigationViewStyle(.stack)
    }
    
    func deferredRendering(seconds: Double) -> some View {
        modifier(DeferredViewModifier(threshold: seconds))
    }
}

struct DeferredViewModifier: ViewModifier {
   let threshold: Double
   func body(content: Content) -> some View {
       _content(content)
           .onAppear {
              DispatchQueue.main.asyncAfter(deadline: .now() + threshold) {
                  self.shouldRender = true
              }
           }
   }
   @ViewBuilder
   private func _content(_ content: Content) -> some View {
       if shouldRender {
           content
       } else {
           content.hidden()
       }
   }

   @State
   private var shouldRender = false
}
