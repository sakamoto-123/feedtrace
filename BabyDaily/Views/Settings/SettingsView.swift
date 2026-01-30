import SwiftUI
import CoreData

struct SettingsView: View {
    let baby: Baby
    // iCloud同步开关状态
    @AppStorage("isICloudSyncEnabled") private var isICloudSyncEnabled = false
    // 提示信息状态
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    // 会员管理器
    @StateObject private var membershipManager = MembershipManager.shared
    // 导航到会员特权页面
    @State private var showMembershipPrivileges = false
    // 导航到编辑宝宝页面
    @State private var showEditBaby = false
    // 导航到新增宝宝页面
    @State private var showAddBaby = false
    // 导航到家庭协作页面
    @State private var showFamilyCollaboration = false
    
    private func shareApp() {
        let shareText = "share_app_text".localized
        if let url = URL(string: "https://apps.apple.com/cn/app/id6758009379") {
            let activityVC = UIActivityViewController(activityItems: [shareText, url], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        }
    }
    
    private let privacyPolicyURL = URL(string: "https://my.feishu.cn/wiki/N6xkwhXXPikVDrk075tcsNpgn2q")!
    private let userAgreementURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    
    private func openPrivacyPolicy() {
        UIApplication.shared.open(privacyPolicyURL)
    }
    
    private func openUserAgreement() {
        UIApplication.shared.open(userAgreementURL)
    }
    
    private func openAppStoreReview() {
        // 替换为你的App ID
        let urlString = "itms-apps://apps.apple.com/app/id6758009379?action=write-review"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    var body: some View {
        List {
                // 宝宝信息
                Section {
                    HStack(spacing: 4)  {
                        if let photoData = baby.photo, let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 46, height: 46)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 46, height: 46)
                                .foregroundColor(.accentColor)
                        }
                        
                        HStack(alignment: .center, spacing: 8) {
                            Text(baby.name)
                                .font(.headline)
                            
                            Button(action: {
                                showEditBaby = true
                            }) {
                                Image(systemName: "square.and.pencil")
                                    .font(.system(size: 18))
                                    .foregroundColor(.accentColor)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.leading, 12)
                        
                        Spacer()
                        
                        Button(action: {
                            // 检查是否是会员
                            if membershipManager.isFeatureAvailable(.multipleBabies) {
                                // 会员，跳转到新增宝宝页面
                                showAddBaby = true
                            } else {
                                // 非会员，跳转到会员特权页面
                                showMembershipPrivileges = true
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // 点击行的其他区域（非按钮区域）跳转到编辑页面
                        showEditBaby = true
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
                }
                
                // 会员特权
                Section {
                    NavigationLink(destination: MembershipPrivilegesView()) {
                        HStack {
                            Text("👑")
                            Text("membership_privileges".localized)
                            Spacer()
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
                                        // 检查是否是会员
                                        if !membershipManager.isFeatureAvailable(.iCloudSync) {
                                            // 非会员，跳转到会员特权页面
                                            showMembershipPrivileges = true
                                            return
                                        }
                                        
                                        // 会员用户，检查iCloud状态
                                        Task {
                                            let isAvailable = await ShareManager.shared.checkiCloudAvailability()
                                            if isAvailable {
                                                isICloudSyncEnabled = true
                                            } else {
                                                alertTitle = "icloud_not_logged_in_title".localized
                                                alertMessage = "icloud_not_logged_in_message".localized
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
                            .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                        }
                    }
                    // 家庭协作入口 (仅在 iCloud 开启时显示)
                    Button(action: {
                        // 1. 检查是否是会员
                        if !membershipManager.isFeatureAvailable(.familySharing) {
                            showMembershipPrivileges = true
                            return
                        }
                        
                        // 2. 检查 iCloud 是否开启
                        if !isICloudSyncEnabled {
                            alertTitle = "icloud_not_logged_in_title".localized
                            alertMessage = "icloud_not_logged_in_message".localized
                            showAlert = true
                            return
                        }
                        
                        // 3. 跳转
                        showFamilyCollaboration = true
                    }) {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(.accentColor)
                            Text("family_collaboration".localized)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                
                // 个性化设置
                Section {
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
                }
                .listRowBackground(Color.clear)
                .offset(y: -10)
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(24)
            .padding(.top, -20)
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
            // 导航到会员特权页面
            .navigationDestination(isPresented: $showMembershipPrivileges) {
                MembershipPrivilegesView()
            }
            // 导航到编辑宝宝页面
            .navigationDestination(isPresented: $showEditBaby) {
                BabyCreationView(isEditing: true, existingBaby: baby)
            }
            // 导航到新增宝宝页面
            .navigationDestination(isPresented: $showAddBaby) {
                BabyCreationView(isEditing: false, isFirstCreation: false)
            }
            // 导航到家庭协作页面
            .navigationDestination(isPresented: $showFamilyCollaboration) {
                FamilyCollaborationView()
            }
    }
}
