import SwiftUI
import SwiftData

struct SettingsView: View {
    let baby: Baby
    @State private var showShareSheet = false
    // iCloud同步开关状态
    @AppStorage("isICloudSyncEnabled") private var isICloudSyncEnabled = false
    // 提示信息状态
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    // 同步管理器
    @StateObject private var cloudSyncManager = CloudSyncManager.shared
    // 获取ModelContext
    @Environment(\.modelContext) private var modelContext
    
    private func shareApp() {
        let shareText = "share_app_text".localized
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
        let urlString = "itms-apps://apps.apple.com/app/id6757728747?action=write-review"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // 宝宝信息
            Section {
                NavigationLink(destination: BabyCreationView(isEditing: true, existingBaby: baby)) {
                    HStack {
                        if let photoData = baby.photo, let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
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
                    }
                }
            }

                // 会员特权
                Section {
                    NavigationLink(destination: MembershipPrivilegesView()) {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(Color.fromHex("#ffb658"))
                            Text("membership_privileges".localized)
                            Spacer()
                            Text("free".localized)
                                .foregroundColor(.secondary)
                        }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "icloud")
                                .foregroundColor(Color.fromHex("#6cb09e"))
                            Text("icloud_sync_backup".localized)
                            Spacer()
                            Toggle(isOn: Binding(
                                get: { isICloudSyncEnabled },
                                set: { newValue in
                                    if newValue {
                                        // 当尝试开启时，检查iCloud状态
                                        let status = cloudSyncManager.checkiCloudStatus()
                                        switch status {
                                        case .available:
                                            // iCloud可用，开启同步
                                            isICloudSyncEnabled = true
                                        case .notLoggedIn:
                                            // 未登录iCloud，显示提示
                                            alertTitle = "icloud_not_logged_in_title".localized
                                            alertMessage = "icloud_not_logged_in_message".localized
                                            showAlert = true
                                        case .insufficientSpace:
                                            // 空间不足，显示提示
                                            alertTitle = "icloud_insufficient_space_title".localized
                                            alertMessage = "icloud_insufficient_space_message".localized
                                            showAlert = true
                                        }
                                    } else {
                                        // 关闭时直接执行
                                        isICloudSyncEnabled = false
                                    }
                                }
                            )) {
                                Text("")
                            }
                            .toggleStyle(SwitchToggleStyle(tint: Color.fromHex("#6cb09e")))
                        }
                        
                        // 显示iCloud状态信息
                        if isICloudSyncEnabled {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.secondary)
                                Text(cloudSyncManager.icloudStatus.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                    }
                    
                    // 手动同步按钮和状态显示
                    if isICloudSyncEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(Color.fromHex("#6cb09e"))
                                Text("manual_sync".localized)
                                Spacer()
                                Button(action: {
                                        cloudSyncManager.syncData(modelContext: modelContext, isICloudSyncEnabled: isICloudSyncEnabled)
                                    }) {
                                    Text("sync_now".localized)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 4)
                                        .background(Color.fromHex("#6cb09e"))
                                        .foregroundColor(.white)
                                        .cornerRadius(16)
                                }
                            }
                            
                            // 同步状态显示
                            HStack {
                                Image(systemName: "cloud")
                                    .foregroundColor(cloudSyncManager.syncStatus.color)
                                Text(cloudSyncManager.syncStatus.description)
                                    .font(.caption)
                                    .foregroundColor(cloudSyncManager.syncStatus.color)
                                Spacer()
                            }
                        }
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
                
                // 关于
                Section {
                    Button(action: shareApp) {
                        HStack {
                            Image(systemName: "square.and.arrow.up.circle.fill")
                                .foregroundColor(Color.fromHex("#ffc76b"))
                            Text("share_app".localized)
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
                .padding(.top, -44)
            }
            .navigationTitle("settings".localized)
            .navigationBarTitleDisplayMode(.inline)
            // 显示提示信息
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("ok".localized))
                )
            }
        }
    }
}