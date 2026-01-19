import SwiftUI
import SwiftData

// iCloud状态枚举
enum iCloudStatus {
    case notLoggedIn      // 未登录iCloud
    case insufficientSpace // 存储空间不足
    case available         // 可用
}

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
    
    // 检查iCloud状态
    private func checkiCloudStatus() async -> iCloudStatus {
        // 检查是否登录iCloud
        guard let ubiquityContainerURL = FileManager.default.url(forUbiquityContainerIdentifier: nil) else {
            return .notLoggedIn
        }
        
        do {
            // 检查可用存储空间
            let resourceValues = try ubiquityContainerURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            if let availableCapacity = resourceValues.volumeAvailableCapacityForImportantUsage {
                // 检查可用空间是否大于100MB
                let requiredSpace: Int64 = 100 * 1024 * 1024 // 100MB
                return availableCapacity > requiredSpace ? .available : .insufficientSpace
            }
        } catch {
            print("Error checking iCloud storage: \(error)")
        }
        
        return .insufficientSpace
    }
    
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
                    HStack {
                        Image(systemName: "icloud")
                            .foregroundColor(Color.fromHex("#6cb09e"))
                        Text("iCloud云同步/备份".localized)
                        Spacer()
                        Toggle(isOn: Binding(
                            get: { isICloudSyncEnabled },
                            set: { newValue in
                                if newValue {
                                    // 当尝试开启时，检查iCloud状态
                                    Task {
                                        let status = await checkiCloudStatus()
                                        switch status {
                                        case .available:
                                            // iCloud可用，开启同步
                                            isICloudSyncEnabled = true
                                        case .notLoggedIn:
                                            // 未登录iCloud，显示提示
                                            alertTitle = "未登录iCloud"
                                            alertMessage = "您尚未登录iCloud，请先登录iCloud后再开启同步功能。"
                                            showAlert = true
                                        case .insufficientSpace:
                                            // 空间不足，显示提示
                                            alertTitle = "iCloud空间不足"
                                            alertMessage = "您的iCloud存储空间不足，无法开启同步功能。请清理iCloud空间后再尝试。"
                                            showAlert = true
                                        }
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
                    
                    // 手动同步按钮和状态显示
                    if isICloudSyncEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(Color.fromHex("#6cb09e"))
                                Text("手动同步".localized)
                                Spacer()
                                Button(action: {
                                    Task {
                                        await cloudSyncManager.syncData(modelContext: modelContext, isICloudSyncEnabled: isICloudSyncEnabled)
                                    }
                                }) {
                                    Text("立即同步".localized)
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
                                Image(systemName: "info.circle")
                                    .foregroundColor(cloudSyncManager.getSyncStatusColor())
                                Text(cloudSyncManager.getSyncStatusText())
                                    .font(.caption)
                                    .foregroundColor(cloudSyncManager.getSyncStatusColor())
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
                            Text("分享应用".localized)
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
            // 显示提示信息
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("确定"))
                )
            }
        }
    }
}
