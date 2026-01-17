import SwiftUI

struct ThemeColorSettingView: View {
    // 使用主题管理器的单例实例
    @ObservedObject var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    ForEach(ThemeColor.allCases, id: \.self) { color in
                        Button(action: {
                            // 更新主题管理器中的主题颜色
                            themeManager.switchThemeColor(to: color)
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(color.color)
                                    .frame(height: 100)
                                
                                if themeManager.selectedThemeColor == color {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("主题颜色")
            .navigationBarTitleDisplayMode(.inline)
            .edgesIgnoringSafeArea(.bottom)
            .toolbar(.hidden, for: .tabBar)
        }
    }
}