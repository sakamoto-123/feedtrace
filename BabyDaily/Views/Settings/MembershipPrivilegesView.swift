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
                    Text("当前为免费用户")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("升级会员享受更多特权")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button(action: {
                        // 升级会员
                    }) {
                        Text("立即升级")
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
                Text("会员特权")
                    .font(.headline)
                    .padding(.horizontal)
                
                List {
                    // 特权项
                    let privileges = [
                        (icon: "☁️", name: "iCloud云同步同步", description: "数据存储在 iCloud"),
                        (icon: "🔄", name: "多设备同步", description: "支持多设备数据同步"),
                        (icon: "🎨", name: "更多主题", description: "解锁更多主题颜色和样式"),
                        (icon: "🚫", name: "无广告", description: "使用过程中无任何广告干扰")
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
            .navigationTitle("会员特权")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
        }
    }
}