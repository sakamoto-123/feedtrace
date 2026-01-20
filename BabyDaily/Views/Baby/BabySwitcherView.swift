import SwiftUI
import SwiftData

struct BabySwitcherView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var babies: [Baby]
    @Query private var allRecords: [Record]
    
    let currentBaby: Baby?
    let onSelectBaby: (Baby) -> Void
    let onAddBaby: () -> Void
    
    // 删除相关状态 - 只存储要删除的宝宝ID，不存储实例
    @State private var showingDeleteConfirm = false
    @State private var babyToDeleteId: UUID?
    @State private var showingDeleteError = false
    @State private var deleteErrorMessage = ""
    
    // 计算属性：从当前有效的 babies 数组中获取要删除的宝宝实例
    private var babyToDelete: Baby? {
        guard let id = babyToDeleteId else { return nil }
        return babies.first(where: { $0.id == id })
    }
    
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
                .onDelete(perform: confirmDelete)
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
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        
        // 删除确认对话框
        .confirmationDialog("确认删除宝宝", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
            Button("删除", role: .destructive) {
                if let baby = babyToDelete {
                    deleteBaby(baby)
                }
            }
            Button("取消", role: .cancel) {
                babyToDeleteId = nil
            }
        } message: {
            if let baby = babyToDelete {
                Text("确定要删除宝宝 \(baby.name) 吗？此操作不可恢复，所有相关记录也将被删除。")
            }
        }
        
        // 删除错误提示
        .alert("删除失败", isPresented: $showingDeleteError) {
            Button("确定") {}
        } message: {
            Text(deleteErrorMessage)
        }
    }
    
    // MARK: - 删除相关方法
    
    /// 确认删除宝宝
    private func confirmDelete(at offsets: IndexSet) {
        guard let index = offsets.first, index < babies.count else { return }
        // 只存储ID，不存储实例
        babyToDeleteId = babies[index].id
        showingDeleteConfirm = true
    }
    
    /// 删除宝宝及相关记录
    private func deleteBaby(_ baby: Baby) {
        do {
            // 从当前有效的 babies 数组中查找要删除的宝宝
            // baby 参数来自计算属性，总是有效的实例
            let babyId = baby.id
            
            // 1. 删除与该宝宝关联的所有记录
            let babyRecords = allRecords.filter { $0.babyId == babyId }
            for record in babyRecords {
                modelContext.delete(record)
            }
            
            // 2. 删除宝宝对象
            modelContext.delete(baby)
            
            // 3. 保存更改
            try modelContext.save()
            
            // 4. 如果删除的是当前选中的宝宝，关闭视图
            if babyId == currentBaby?.id {
                dismiss()
            }
        } catch {
            // 处理删除错误
            deleteErrorMessage = "删除宝宝失败：\(error.localizedDescription)"
            showingDeleteError = true
        }
        
        // 重置状态
        babyToDeleteId = nil
        showingDeleteConfirm = false
    }
}

// 添加本地化键
// "select_baby" = "选择宝宝";
