import SwiftUI

struct ModeSettingView: View {
    // 使用ThemeManager来管理主题
    @ObservedObject var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                List {
                    ForEach(ThemeMode.allCases, id: \.self) { mode in
                        HStack {
                            Text(mode.rawValue)
                            Spacer()
                            if themeManager.selectedThemeMode == mode {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            themeManager.switchTheme(to: mode)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                
                Spacer()
            }
            .navigationTitle("mode_setting".localized)
            .navigationBarTitleDisplayMode(.inline)
            .edgesIgnoringSafeArea(.bottom)
            .toolbar(.hidden, for: .tabBar)
        }
    }
}