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

// MARK: - TabBar 动画隐藏修饰符
struct AnimatedTabBarHiddenModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                // 使用动画隐藏 tabBar
                DispatchQueue.main.async {
                    if let tabBarController = findTabBarController() {
                        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseInOut], animations: {
                            tabBarController.tabBar.transform = CGAffineTransform(translationX: 0, y: tabBarController.tabBar.frame.height)
                        })
                    }
                }
            }
            .onDisappear {
                // 视图消失时，恢复显示 tabBar
                DispatchQueue.main.async {
                    if let tabBarController = findTabBarController() {
                        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseInOut], animations: {
                            tabBarController.tabBar.transform = .identity
                        })
                    }
                }
            }
    }
    
    private func findTabBarController() -> UITabBarController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        
        return window.rootViewController?.findTabBarController()
    }
}

// MARK: - UIViewController 扩展：查找 TabBarController
extension UIViewController {
    func findTabBarController() -> UITabBarController? {
        if let tabBarController = self as? UITabBarController {
            return tabBarController
        }
        
        for child in children {
            if let tabBarController = child.findTabBarController() {
                return tabBarController
            }
        }
        
        if let presented = presentedViewController {
            return presented.findTabBarController()
        }
        
        return nil
    }
}

// MARK: - View扩展
extension View {
    func keyboardDoneButton() -> some View {
        self.modifier(KeyboardDoneButtonModifier())
    }
    
    /// 使用动画隐藏 tabBar
    func animatedTabBarHidden() -> some View {
        self.modifier(AnimatedTabBarHiddenModifier())
    }
}