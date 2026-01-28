import SwiftUI
import CoreData

struct BabySwitcherView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Baby.createdAt, ascending: true)],
        animation: .default)
    private var babies: FetchedResults<Baby>
    
    let currentBaby: Baby?
    let onSelectBaby: (Baby) -> Void
    let onAddBaby: () -> Void
    
    // 删除相关状态 - 只存储要删除的宝宝ID，不存储实例
    @State private var showingDeleteConfirm = false
    @State private var babyToDeleteId: UUID?
    @State private var showingDeleteError = false
    @State private var deleteErrorMessage = ""
    
    // 编辑相关状态
    struct BabyEditConfig: Identifiable {
        let id: UUID
    }
    @State private var editConfig: BabyEditConfig?
    
    // 计算属性：从当前有效的 babies 数组中获取要删除的宝宝实例
    private var babyToDelete: Baby? {
        guard let id = babyToDeleteId else { return nil }
        return babies.first(where: { $0.id == id })
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题和关闭按钮
            HStack {
                Text("select_baby".localized)
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
                        .padding(.leading, 24)
                        .padding(.trailing, 8)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            // 编辑宝宝信息
                            editConfig = BabyEditConfig(id: baby.id)
                        } label: {
                            Image(systemName: "square.and.pencil")
                        }
                        .tint(.accentColor)
                        Button(role: .destructive) {
                            // 删除宝宝
                            babyToDeleteId = baby.id
                            showingDeleteConfirm = true
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
            .padding(.leading, -16)
            
            // 新增宝宝按钮
            Button(action: {
                dismiss()
                onAddBaby()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    Text("add_new_baby".localized)
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
        .confirmationDialog("confirm_delete_baby_title".localized, isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
            Button("delete".localized, role: .destructive) {
                if let baby = babyToDelete {
                    deleteBaby(baby)
                }
            }
            Button("cancel".localized, role: .cancel) {
                babyToDeleteId = nil
            }
        } message: {
            if let baby = babyToDelete {
                Text(String(format: "confirm_delete_baby_message".localized, baby.name))
            }
        }
        
        // 删除错误提示
        .alert("delete_baby_failed_title".localized, isPresented: $showingDeleteError) {
            Button("ok".localized) {}
        } message: {
            Text(deleteErrorMessage)
        }
        // 编辑页面以 sheet 形式弹出
        .sheet(item: $editConfig) { config in
            if let baby = babies.first(where: { $0.id == config.id }) {
                BabyCreationView(isEditing: true, existingBaby: baby, isFirstCreation: false)
            }
        }
    }
    
    // MARK: - 删除相关方法
    
    /// 删除宝宝及相关记录
    private func deleteBaby(_ baby: Baby) {
        do {
            // 从当前有效的 babies 数组中查找要删除的宝宝
            // baby 参数来自计算属性，总是有效的实例
            let babyId = baby.id
            
            // 1. 删除与该宝宝关联的所有记录
            // Core Data 配置了 Cascade 删除规则，删除 Baby 会自动删除 Records
            // 无需手动删除记录
            
            // 2. 删除宝宝对象
            viewContext.delete(baby)
            
            // 3. 保存更改
            try viewContext.save()
            
            // 4. 如果删除的是当前选中的宝宝，关闭视图
            if babyId == currentBaby?.id {
                dismiss()
            }
        } catch {
            // 处理删除错误
            deleteErrorMessage = String(format: "delete_baby_failed_message".localized, error.localizedDescription)
            showingDeleteError = true
        }
        
        // 重置状态
        babyToDeleteId = nil
        showingDeleteConfirm = false
    }
}

// 添加本地化键
// "select_baby" = "选择宝宝";
