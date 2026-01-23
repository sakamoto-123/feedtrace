import SwiftUI

struct LanguageSettingView: View {
    // 使用Environment访问AppSettings
    @EnvironmentObject var appSettings: AppSettings
    // 使用本地状态立即更新UI，确保响应迅速
    @State private var selectedLanguage: AppLanguage
    
    init() {
        // 初始化时从AppSettings获取当前语言
        _selectedLanguage = State(initialValue: AppSettings.shared.language)
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {  
                List {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        HStack {
                            Text(language.displayName)
                            Spacer()
                            if selectedLanguage == language {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                                    .transition(.opacity)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // 立即更新本地状态，确保UI瞬间响应
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                selectedLanguage = language
                            }
                            // 然后同步到AppSettings（后台操作，不阻塞UI）
                            appSettings.setLanguage(language)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                
                Spacer()
            }
            .navigationTitle("language_setting".localized)
            .navigationBarTitleDisplayMode(.inline)
            .edgesIgnoringSafeArea(.bottom)
             .animatedTabBarHidden()
            .onAppear {
                // 视图出现时同步AppSettings的状态
                selectedLanguage = appSettings.language
            }
            .onChange(of: appSettings.language) { newLanguage in
                // 当AppSettings变化时（比如从其他地方修改），同步本地状态
                if selectedLanguage != newLanguage {
                    selectedLanguage = newLanguage
                }
            }
        }
    }
}