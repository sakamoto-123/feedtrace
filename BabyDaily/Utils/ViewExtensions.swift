import SwiftUI
import UIKit

// MARK: - 键盘完成按钮修饰符
struct KeyboardDoneButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("done".localized) {
                            // 关闭键盘
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    }
                }
            }
    }
}

// MARK: - View扩展
extension View {
    func keyboardDoneButton() -> some View {
        self.modifier(KeyboardDoneButtonModifier())
    }
}