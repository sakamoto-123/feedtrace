import SwiftUI

struct ThemeColorSettingView: View {
    // 使用主题管理器的单例实例
    @ObservedObject var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 50), spacing: 12)], alignment: .leading, spacing: 24) {
                    ForEach(ThemeColor.allCases, id: \.self) { color in
                        Button(action: {
                            // 更新主题管理器中的主题颜色
                            themeManager.switchThemeColor(to: color)
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(color.color)
                                    .frame(width: 50, height: 50)
                                
                                if themeManager.selectedThemeColor == color {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 22))
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
