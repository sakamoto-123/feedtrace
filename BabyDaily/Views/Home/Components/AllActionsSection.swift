import SwiftUI

// 所有操作区域组件
struct AllActionsSection: View {
    let allActions: [(category: String, actions: [(icon: String, name: String, color: Color)])]
    let baby: Baby
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Text("all_actions".localized)
            //     .font(.headline)
            
            ForEach(Array(allActions.enumerated()), id: \.element.category) { index, categoryItem in
                VStack(alignment: .leading, spacing: 12) {
                    Text(categoryItem.category.localized)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 60), spacing: 12)], spacing: 20) {
                        ForEach(categoryItem.actions, id: \.name) { action in
                            CategoryActionButton(
                                icon: action.icon,
                                name: action.name,
                                color: action.color,
                                category: categoryItem.category,
                                baby: baby,
                                size: 44,
                                presentAsSheet: true
                            )
                            .frame(maxHeight: .infinity, alignment: .top)
                        }
                    }

                    if index != allActions.count - 1 {
                        GeometryReader { geometry in
                            Path { path in
                                path.move(to: CGPoint(x: 0, y: 0))
                                path.addLine(to: CGPoint(x: geometry.size.width, y: 0))
                            }
                            .stroke(Color.accentColor.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                        }
                        .frame(height: 1)  // 限制高度，避免 GeometryReader 占满剩余空间导致 item 间留白
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .padding()
        .background(Color.themeCardBackground(for: colorScheme))
        .cornerRadius(Constants.cornerRadius)
        .padding(.horizontal, 12)
        // .padding(.top, 16)
    }
}
