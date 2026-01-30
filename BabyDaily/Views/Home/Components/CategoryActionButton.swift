import SwiftUI

// 快速操作按钮组件
struct CategoryActionButton: View {
    let icon: String
    let name: String
    let color: Color
    let category: String
    let baby: Baby
    let size: CGFloat = 60
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            NavigationLink(destination: RecordEditView(baby: baby, recordType: (category: category, subCategory: name, icon: icon))) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.5))
                        .frame(width: size, height: size)
                        .overlay(
                            Circle()
                                .stroke(color, lineWidth: 2)
                        )
                    
                    Text(icon)
                        .font(.system(size: 32))
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Text(name.localized)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }
}
