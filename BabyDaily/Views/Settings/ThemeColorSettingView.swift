import SwiftUI

struct ThemeColorSettingView: View {
    // 使用Environment访问AppSettings
    @EnvironmentObject var appSettings: AppSettings
    // 使用本地状态立即更新UI，确保响应迅速
    @State private var selectedColor: ThemeColor
    
    init() {
        // 初始化时从AppSettings获取当前颜色
        _selectedColor = State(initialValue: AppSettings.shared.themeColor)
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 50), spacing: 12)], alignment: .leading, spacing: 24) {
                    ForEach(ThemeColor.allCases, id: \.self) { color in
                        Button(action: {
                            // 立即更新本地状态，确保UI瞬间响应
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                selectedColor = color
                            }
                            // 然后同步到AppSettings（后台操作，不阻塞UI）
                            appSettings.setThemeColor(color)
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(color.color)
                                    .frame(width: 50, height: 50)
                                
                                if selectedColor == color {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(.white)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("theme_color".localized)
            .navigationBarTitleDisplayMode(.inline)
            .edgesIgnoringSafeArea(.bottom)
            .toolbar(.hidden, for: .tabBar)
            .onAppear {
                // 视图出现时同步AppSettings的状态
                selectedColor = appSettings.themeColor
            }
            .onChange(of: appSettings.themeColor) { newColor in
                // 当AppSettings变化时（比如从其他地方修改），同步本地状态
                if selectedColor != newColor {
                    selectedColor = newColor
                }
            }
        }
    }
}
