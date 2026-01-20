import SwiftUI
import SwiftData

struct BabySwitcherView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var babies: [Baby]
    
    let currentBaby: Baby?
    let onSelectBaby: (Baby) -> Void
    let onAddBaby: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题和关闭按钮
            HStack {
                Text("选择宝宝".localized)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(.background)
            
            // 宝宝列表
            List {
                ForEach(babies) {
                    baby in
                    Button(action: {
                        onSelectBaby(baby)
                        dismiss()
                    }) {
                        HStack(spacing: 16) {
                            // 宝宝头像
                            if let photoData = baby.photo, let uiImage = UIImage(data: photoData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFill()                                    
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(AppSettings.shared.currentThemeColor)
                            }
                            
                            // 宝宝名称
                            Text(baby.name)
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            // 选中标记
                            if currentBaby?.id == baby.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppSettings.shared.currentThemeColor)
                                    .font(.system(size: 18, weight: .medium))
                            }
                        }
                        .padding(.vertical, 0)
                        .padding(.horizontal, 24)
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.plain)
            .padding(.horizontal, -16)
            
            // 新增宝宝按钮
            Button(action: {
                dismiss()
                onAddBaby()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("添加新的宝宝".localized)
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(AppSettings.shared.currentThemeColor)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 16)
                .padding(.top, 24)
                .background(.background)
                .overlay(
                    Divider()
                        .offset(y: -0.5)
                )
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// 添加本地化键
// "select_baby" = "选择宝宝";
