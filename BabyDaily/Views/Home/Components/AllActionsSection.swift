import SwiftUI

// 所有操作区域组件
struct AllActionsSection: View {
    let allActions: [(category: String, actions: [(icon: String, name: String, color: Color)])]
    let baby: Baby
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("all_actions".localized)
                .font(.headline)
            
            ForEach(Array(allActions.enumerated()), id: \.element.category) { index, categoryItem in
                VStack(alignment: .leading, spacing: 16) {
                    Text(categoryItem.category.localized)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 75), spacing: 12)], spacing: 20) {
                        ForEach(categoryItem.actions, id: \.name) { action in
                            CategoryActionButton(
                                icon: action.icon,
                                name: action.name,
                                color: action.color,
                                category: categoryItem.category,
                                baby: baby
                            )
                            .frame(maxHeight: .infinity, alignment: .top)
                        }
                    }

                    if index != allActions.count - 1 {
                        Divider()
                            .background(Color(.systemGray6))
                            .padding(.vertical, 8)
                    }
                }
            }
        }
        .padding()
        .background(Color.themeCardBackground(for: colorScheme))
        .cornerRadius(12)
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
}
