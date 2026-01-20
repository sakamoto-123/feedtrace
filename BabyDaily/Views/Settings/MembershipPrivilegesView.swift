import SwiftUI

struct MembershipPrivilegesView: View {
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                // 会员状态
                VStack(alignment: .center, spacing: 12) {
                     Text("👑")
                        .font(.system(size: 50))
                        .fontWeight(.bold)
                    Text("current_free_user".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("upgrade_membership_prompt".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button(action: {
                        // 升级会员
                    }) {
                        Text("upgrade_now".localized)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 12)
                            .background(Color.accentColor)
                            .cornerRadius(24)
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color(.systemGray6))
                .cornerRadius(Constants.cornerRadius)
                .padding(.horizontal)
                
                // 特权列表
                Text("membership_privileges".localized)
                    .font(.headline)
                    .padding(.horizontal)
                
                List {
                    // 特权项
                    let privileges = [
                        (icon: "☁️", name: "icloud_sync_feature".localized, description: "data_stored_in_icloud".localized),
                        (icon: "🔄", name: "multi_device_sync".localized, description: "multi_device_sync_description".localized),
                        (icon: "🎨", name: "more_themes".localized, description: "unlock_more_themes_description".localized),
                        (icon: "🚫", name: "no_ads".localized, description: "no_ads_description".localized)
                    ]
                    
                    ForEach(privileges, id: \.name) { privilege in
                        HStack(spacing: 12) {
                            Text(privilege.icon)
                                .font(.title)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(privilege.name)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text(privilege.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                
                Spacer()
            }
            .navigationTitle("membership_privileges".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
        }
    }
}