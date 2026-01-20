import SwiftUI

struct ThemeColorSettingView: View {
    // 使用Environment访问AppSettings
    @EnvironmentObject var appSettings: AppSettings
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 50), spacing: 12)], alignment: .leading, spacing: 24) {
                    ForEach(ThemeColor.allCases, id: \.self) { color in
                        Button(action: {
                            // 直接更新AppSettings，使用单一数据源
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                appSettings.setThemeColor(color)
                            }
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(color.color)
                                    .frame(width: 50, height: 50)
                                
                                if appSettings.themeColor == color {
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
        }
    }
}
