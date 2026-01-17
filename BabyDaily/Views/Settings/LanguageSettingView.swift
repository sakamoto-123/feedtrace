import SwiftUI

struct LanguageSettingView: View {
    // 使用LanguageManager来管理语言设置
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {  
                List {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        HStack {
                            Text(language.displayName)
                            Spacer()
                            if languageManager.selectedLanguage == language {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            languageManager.switchLanguage(to: language)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                
                Spacer()
            }
            .navigationTitle("language_setting".localized)
            .navigationBarTitleDisplayMode(.inline)
            .edgesIgnoringSafeArea(.bottom)
            .toolbar(.hidden, for: .tabBar)
        }
    }
}