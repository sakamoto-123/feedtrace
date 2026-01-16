import SwiftUI

struct LanguageSettingView: View {
    // 使用LanguageManager来管理语言设置
    @ObservedObject var languageManager = LanguageManager.shared
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("select_language".localized)
                    .font(.headline)
                    .padding(.horizontal)
                
                List {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        HStack {
                            Text(language.localizedName)
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
        }
    }
}