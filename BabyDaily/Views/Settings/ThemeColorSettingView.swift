import SwiftUI

struct ThemeColorSettingView: View {
    // 使用Environment访问AppSettings
    @EnvironmentObject var appSettings: AppSettings
    @StateObject private var membershipManager = MembershipManager.shared
    @State private var showingMembershipView = false
    
    // 前6个颜色是免费的（索引0-5）
    private let freeColorCount = 12
    
    // 判断颜色是否需要会员
    private func isColorPremium(_ color: ThemeColor) -> Bool {
        guard let index = ThemeColor.allCases.firstIndex(of: color) else {
            return false
        }
        return index >= freeColorCount
    }
    
    // 判断颜色是否可用（免费或会员已购买）
    private func isColorAvailable(_ color: ThemeColor) -> Bool {
        if !isColorPremium(color) {
            return true // 免费颜色总是可用
        }
        return membershipManager.isPremiumMember // 会员颜色需要会员身份
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 50), spacing: 12)], alignment: .leading, spacing: 24) {
                    ForEach(Array(ThemeColor.allCases.enumerated()), id: \.element) { index, color in
                        let isPremium = isColorPremium(color)
                        let isAvailable = isColorAvailable(color)
                        
                        Button(action: {
                            if isAvailable {
                                // 直接更新AppSettings，使用单一数据源
                                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                    appSettings.setThemeColor(color)
                                }
                            } else {
                                // 非会员点击会员颜色，弹出会员页面
                                showingMembershipView = true
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
                                } else if isPremium && !isAvailable {
                                    // 非会员的会员颜色显示锁图标
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white)
                                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
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
            .sheet(isPresented: $showingMembershipView) {
                MembershipPrivilegesView()
            }
        }
    }
}
