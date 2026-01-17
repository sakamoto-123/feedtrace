import SwiftUI

struct MembershipPrivilegesView: View {
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                // 会员状态
                VStack(alignment: .center, spacing: 12) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.yellow)
                    
                    Text("当前为免费用户")
                        .font(.title)
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
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                            .background(.blue)
                            .cornerRadius(24)
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // 特权列表
                Text("会员特权")
                    .font(.headline)
                    .padding(.horizontal)
                
                List {
                    // 特权项
                    let privileges = [
                        (icon: "📸", name: "无限照片存储", description: "支持上传无限量宝宝照片和视频"),
                        (icon: "📊", name: "专业成长分析", description: "获得专业的宝宝成长数据分析报告"),
                        (icon: "📝", name: "智能记录模板", description: "使用更多智能记录模板"),
                        (icon: "🔄", name: "多设备同步", description: "支持多设备数据同步"),
                        (icon: "🎨", name: "更多主题", description: "解锁更多主题颜色和样式"),
                        (icon: "💌", name: "成长周报", description: "每周收到宝宝成长周报"),
                        (icon: "🔒", name: "数据加密", description: "享受高级数据加密保护"),
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