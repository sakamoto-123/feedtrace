import SwiftUI
import UIKit

// MARK: - 多行文本输入视图（光标从顶部开始，自动调整高度）
struct MultilineTextView: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let minHeight: CGFloat
    let maxLines: Int
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = .systemFont(ofSize: 17)
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.maximumNumberOfLines = 0 // 设置为0表示不限制行数，由maxLines控制
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.isScrollEnabled = false // 禁用滚动，让高度自动增长
        
        // 设置占位符
        if text.isEmpty {
            textView.text = placeholder
            textView.textColor = .placeholderText
        } else {
            textView.text = text
            textView.textColor = .label
        }
        
        // 确保光标从顶部开始
        textView.contentInset = .zero
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        
        // 设置初始光标位置在顶部
        DispatchQueue.main.async {
            textView.selectedRange = NSRange(location: 0, length: 0)
            textView.scrollRangeToVisible(NSRange(location: 0, length: 0))
            // 更新高度
            context.coordinator.updateHeight(textView)
        }
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        // 更新文本内容
        if uiView.text != text && !context.coordinator.isEditing {
            if text.isEmpty {
                uiView.text = placeholder
                uiView.textColor = .placeholderText
            } else {
                uiView.text = text
                uiView.textColor = .label
            }
            // 文本内容变化时更新高度
            context.coordinator.updateHeight(uiView)
        }
        
        // 确保光标在顶部（当文本为空时）
        if text.isEmpty && !uiView.isFirstResponder {
            uiView.selectedRange = NSRange(location: 0, length: 0)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        let parent: MultilineTextView
        var isEditing = false
        var heightConstraint: NSLayoutConstraint?
        
        init(_ parent: MultilineTextView) {
            self.parent = parent
        }
        
        func updateHeight(_ textView: UITextView) {
            // 确保布局已更新
            textView.layoutIfNeeded()
            
            // 获取文本容器的宽度（考虑内边距）
            let fixedWidth = textView.bounds.width
            guard fixedWidth > 0 else {
                // 如果宽度还未确定，延迟更新
                DispatchQueue.main.async {
                    self.updateHeight(textView)
                }
                return
            }
            
            // 计算文本所需的高度
            let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: .greatestFiniteMagnitude))
            
            // 计算单行高度
            let font = textView.font ?? .systemFont(ofSize: 17)
            let lineHeight = font.lineHeight
            let padding = textView.textContainerInset.top + textView.textContainerInset.bottom
            let minHeight = parent.minHeight
            let maxHeight = lineHeight * CGFloat(parent.maxLines) + padding
            
            // 限制高度范围
            var calculatedHeight = max(newSize.height, minHeight)
            calculatedHeight = min(calculatedHeight, maxHeight)
            
            // 如果超过最大高度，启用滚动
            if calculatedHeight >= maxHeight {
                textView.isScrollEnabled = true
            } else {
                textView.isScrollEnabled = false
            }
            
            // 更新高度约束
            if heightConstraint == nil {
                heightConstraint = textView.heightAnchor.constraint(equalToConstant: calculatedHeight)
                heightConstraint?.priority = UILayoutPriority(999)
                heightConstraint?.isActive = true
            } else {
                // 只有当高度真正改变时才更新，避免不必要的布局
                if abs(heightConstraint?.constant ?? 0 - calculatedHeight) > 1 {
                    heightConstraint?.constant = calculatedHeight
                    // 触发布局更新
                    textView.superview?.setNeedsLayout()
                    textView.superview?.layoutIfNeeded()
                }
            }
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            isEditing = true
            if textView.text == parent.placeholder {
                textView.text = ""
                textView.textColor = .label
            }
            // 确保光标在顶部并滚动到顶部
            textView.selectedRange = NSRange(location: 0, length: 0)
            textView.scrollRangeToVisible(NSRange(location: 0, length: 0))
            updateHeight(textView)
        }
        
        func textViewDidChange(_ textView: UITextView) {
            if textView.text != parent.placeholder {
                parent.text = textView.text
            }
            // 内容变化时更新高度
            updateHeight(textView)
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            isEditing = false
            if textView.text.isEmpty {
                textView.text = parent.placeholder
                textView.textColor = .placeholderText
            }
            updateHeight(textView)
        }
    }
}
