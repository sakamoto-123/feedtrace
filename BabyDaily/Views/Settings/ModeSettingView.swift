import SwiftUI

struct ModeSettingView: View {
    // 使用Environment访问AppSettings
    @EnvironmentObject var appSettings: AppSettings
    // 使用本地状态立即更新UI，确保响应迅速
    @State private var selectedMode: ThemeMode
    
    init() {
        // 初始化时从AppSettings获取当前模式
        _selectedMode = State(initialValue: AppSettings.shared.themeMode)
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                List {
                    ForEach(ThemeMode.allCases, id: \.self) { mode in
                        HStack {
                            Text(mode.localizedName)
                            Spacer()
                            if selectedMode == mode {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                                    .transition(.opacity)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // 立即更新本地状态，确保UI瞬间响应
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                selectedMode = mode
                            }
                            // 然后同步到AppSettings（后台操作，不阻塞UI）
                            appSettings.setThemeMode(mode)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                
                Spacer()
            }
            .navigationTitle("mode_setting".localized)
            .navigationBarTitleDisplayMode(.inline)
            .edgesIgnoringSafeArea(.bottom)
             .animatedTabBarHidden()
            .onAppear {
                // 视图出现时同步AppSettings的状态
                selectedMode = appSettings.themeMode
            }
            .onChange(of: appSettings.themeMode) { newMode in
                // 当AppSettings变化时（比如从其他地方修改），同步本地状态
                if selectedMode != newMode {
                    selectedMode = newMode
                }
            }
        }
    }
}