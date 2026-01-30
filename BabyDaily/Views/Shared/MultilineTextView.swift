import SwiftUI
import UIKit

// MARK: - 自定义 UITextView 包装器（限制水平扩展）
class BoundedTextView: UIView {
    let textView: UITextView
    
    init(textView: UITextView) {
        self.textView = textView
        super.init(frame: .zero)
        addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: topAnchor),
            textView.leadingAnchor.constraint(equalTo: leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        // 限制水平方向，只返回垂直方向的大小
        // 使用 noIntrinsicMetric 告诉布局系统不要依赖内在宽度
        let width = bounds.width > 0 ? bounds.width : 100 // 使用一个默认值，避免计算错误
        let textSize = textView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: UIView.noIntrinsicMetric, height: textSize.height)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // 当布局改变时，更新内在内容大小
        invalidateIntrinsicContentSize()
    }
    
    override func setNeedsLayout() {
        super.setNeedsLayout()
        invalidateIntrinsicContentSize()
    }
}

// MARK: - 多行文本输入视图（光标从顶部开始，自动调整高度）
struct MultilineTextView: View {
    @Binding var text: String
    let placeholder: String
    let minHeight: CGFloat
    let maxLines: Int
    
    @State private var textViewHeight: CGFloat
    
    init(text: Binding<String>, placeholder: String, minHeight: CGFloat, maxLines: Int) {
        self._text = text
        self.placeholder = placeholder
        self.minHeight = minHeight
        self.maxLines = maxLines
        self._textViewHeight = State(initialValue: minHeight)
    }
    
    var body: some View {
        TextViewWrapper(
            text: $text,
            placeholder: placeholder,
            minHeight: minHeight,
            maxLines: maxLines,
            height: $textViewHeight
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: textViewHeight)
    }
}

// MARK: - UITextView 包装器
private struct TextViewWrapper: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let minHeight: CGFloat
    let maxLines: Int
    @Binding var height: CGFloat
    
    func makeUIView(context: Context) -> BoundedTextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = .systemFont(ofSize: 14)
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.maximumNumberOfLines = 0
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
        
        // 创建包装视图
        let boundedTextView = BoundedTextView(textView: textView)
        context.coordinator.textView = textView
        
        // 设置初始光标位置在顶部
        DispatchQueue.main.async {
            textView.selectedRange = NSRange(location: 0, length: 0)
            textView.scrollRangeToVisible(NSRange(location: 0, length: 0))
            context.coordinator.updateHeight(textView)
        }
        
        return boundedTextView
    }
    
    func updateUIView(_ uiView: BoundedTextView, context: Context) {
        let textView = uiView.textView
        
        // 更新文本内容
        if textView.text != text && !context.coordinator.isEditing {
            if text.isEmpty {
                textView.text = placeholder
                textView.textColor = .placeholderText
            } else {
                textView.text = text
                textView.textColor = .label
            }
            // 文本内容变化时更新高度
            DispatchQueue.main.async {
                context.coordinator.updateHeight(textView)
            }
        }
        
        // 确保光标在顶部（当文本为空时）
        if text.isEmpty && !textView.isFirstResponder {
            textView.selectedRange = NSRange(location: 0, length: 0)
        }
        
        // 更新包装视图的布局
        uiView.invalidateIntrinsicContentSize()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        let parent: TextViewWrapper
        var isEditing = false
        weak var textView: UITextView?
        
        init(_ parent: TextViewWrapper) {
            self.parent = parent
        }
        
        func updateHeight(_ textView: UITextView) {
            // 确保布局已更新
            textView.layoutIfNeeded()
            
            // 获取文本容器的宽度
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
            let font = textView.font ?? .systemFont(ofSize: 14)
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
            
            // 更新高度绑定
            if abs(parent.height - calculatedHeight) > 1 {
                DispatchQueue.main.async {
                    self.parent.height = calculatedHeight
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
