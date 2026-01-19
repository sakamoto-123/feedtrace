import SwiftUI

struct SettingsView: View {
    let baby: Baby
    @State private var showShareSheet = false
    
    private func shareApp() {
        let shareText = "推荐你使用 BabyDaily - 宝宝成长记录助手"
        if let url = URL(string: "https://apps.apple.com") {
            let activityVC = UIActivityViewController(activityItems: [shareText, url], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        }
    }
    
    private let privacyPolicyURL = URL(string: "https://example.com/privacy")!
    private let userAgreementURL = URL(string: "https://example.com/terms")!
    
    private func openPrivacyPolicy() {
        UIApplication.shared.open(privacyPolicyURL)
    }
    
    private func openUserAgreement() {
        UIApplication.shared.open(userAgreementURL)
    }
    
    private func openAppStoreReview() {
        // 替换为你的App ID
        let appID = "1234567890"
        let urlString = "itms-apps://apps.apple.com/app/id\(appID)?action=write-review"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // 宝宝信息
                Section {
                    HStack {
                        if let photoData = baby.photo, let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(.secondary, lineWidth: 2))
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.gray)
                                .overlay(Circle().stroke(.secondary, lineWidth: 2))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(baby.name)
                                .font(.headline)
                            Text("tap_to_edit_baby_info".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 12)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
                
                // 个性化设置
                Section("personalization_settings".localized) {
                    NavigationLink(destination: ThemeColorSettingView()) {
                        HStack {
                            Image(systemName: "paintpalette.fill")
                                .foregroundColor(Color.fromHex("#ad6598"))
                            Text("theme_color".localized)
                            Spacer()
                        }
                    }
                    
                    NavigationLink(destination: LanguageSettingView()) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundStyle(Color.fromHex("#55bb8a"))
                            Text("language_setting".localized)
                            Spacer()
                        }
                    }
                    
                    NavigationLink(destination: ModeSettingView()) {
                        HStack {
                            Image(systemName: "moon.fill")
                                .foregroundColor(Color.fromHex("#b7dbff"))
                            Text("mode_setting".localized)
                            Spacer()
                        }
                    }
                    
                    NavigationLink(destination: UnitSettingView()) {
                        HStack {
                            Image(systemName: "ruler.fill")
                                .foregroundColor(Color.fromHex("#ffbeba"))
                            Text("unit_setting".localized)
                            Spacer()
                        }
                    }
                }
                
                // 会员特权
                Section {
                    NavigationLink(destination: MembershipPrivilegesView()) {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                            Text("membership_privileges".localized)
                            Spacer()
                            Text("free".localized)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // 关于
                Section {
                    Button(action: shareApp) {
                        HStack {
                            Image(systemName: "square.and.arrow.up.circle.fill")
                                .foregroundColor(Color.fromHex("#ffc76b"))
                            Text("write_review".localized)
                                Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)

                    Button(action: openAppStoreReview) {
                        HStack {
                            Image(systemName: "questionmark.circle.fill")
                                .foregroundColor(Color.fromHex("#ff9066"))
                            Text("help_and_feedback".localized)
                                Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)                  
                }

                HStack(alignment: .center, spacing: 12) {
                    Spacer()
                     Button(action: openPrivacyPolicy) {
                        Text("privacy_policy".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: openUserAgreement) {
                        Text("user_agreement".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }.listRowBackground(Color.clear)
            }
            .navigationTitle("settings".localized)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}