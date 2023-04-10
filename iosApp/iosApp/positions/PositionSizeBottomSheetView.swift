import Foundation
import SwiftUI

struct PositionSizeBottomSheetView<Content: View>: View {
    @Binding var isOpen: Bool
    @Binding var isSliding: Bool
    
    let maxHeight: CGFloat
    let minHeight: CGFloat
    let content: Content
    
    @GestureState private var translation: CGFloat = 0
    
    private var offset: CGFloat {
        isOpen ? 0 : maxHeight - minHeight
    }
    
    private var indicator: some View {
        RoundedRectangle(cornerRadius: BottomSheetConstants.radius)
            .fill(Color.secondary)
            .frame(
                width: BottomSheetConstants.indicatorWidth,
                height: BottomSheetConstants.indicatorHeight
            ).onTapGesture {
                self.isOpen.toggle()
            }
    }
    
    init(isOpen: Binding<Bool>, isSliding: Binding<Bool>, maxHeight: CGFloat, @ViewBuilder content: () -> Content) {
        self.minHeight = 0
        self.maxHeight = maxHeight
        self.content = content()
        self._isOpen = isOpen
        self._isSliding = isSliding
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                self.indicator.padding()
                self.content
            }
            .frame(width: geometry.size.width, height: self.maxHeight, alignment: .top)
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(BottomSheetConstants.radius)
            .frame(height: geometry.size.height, alignment: .bottom)
            .offset(y: max(self.offset + self.translation, 0))
            .animation(.interactiveSpring())
            .padding(.bottom, -BottomSheetConstants.radius * 2)
            .simultaneousGesture(self.isSliding == true ? nil : DragGesture().updating(self.$translation) { value, state, _ in
                state = value.translation.height
            }.onEnded { value in
                let snapDistance = self.maxHeight * BottomSheetConstants.snapRatio
                guard abs(value.translation.height) > snapDistance else {
                    return
                }
                self.isOpen = value.translation.height < 0
            })
        }
    }
}

fileprivate enum BottomSheetConstants {
    static let radius: CGFloat = 16
    static let indicatorHeight: CGFloat = 4
    static let indicatorWidth: CGFloat = 60
    static let snapRatio: CGFloat = 0.25
}
