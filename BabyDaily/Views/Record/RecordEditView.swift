import SwiftUI
import SwiftData
import UIKit

// MARK: - 记录类型选择器组件
struct RecordTypeSelector: View {
    @Binding var selectedRecordType: (category: String, subCategory: String, icon: String)?
    let initialRecordType: (category: String, subCategory: String, icon: String)?
    
    // 获取当前选中的记录类型
    private var currentSelectedType: (category: String, subCategory: String, icon: String)? {
        return selectedRecordType ?? initialRecordType
    }
    
    // 子视图：单个操作按钮
    private struct ActionButton: View {
        let category: String
        let action: (icon: String, name: String, color: Color)
        let isSelected: Bool
        let onTap: () -> Void
        
        var body: some View {
            Button {
                onTap()
            } label: {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(isSelected ? action.color.opacity(0.8) : Color.gray.opacity(0.1))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Circle()
                                    .stroke(isSelected ? action.color : Color.gray.opacity(0.2), lineWidth: 2)
                            )
                        
                        Text(action.icon)
                            .font(.system(size: 24))
                    }
                    
                    Text(action.name.localized)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isSelected ? action.color : .secondary)
                }
            }
            .id("\(category)\(action.name)")
        }
    }
    
    var body: some View {
        
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // 将所有分类下的记录类型合并到一个列表
                    ForEach(Constants.allCategorys.sorted(by: { $0.key < $1.key }), id: \.key) { category, actions in
                        ForEach(actions, id: \.name) { action in
                            ActionButton(
                                category: category,
                                action: action,
                                isSelected: currentSelectedType?.subCategory == action.name,
                                onTap: {
                                    // 选择或重新选择记录类型
                                    selectedRecordType = (category: category, subCategory: action.name, icon: action.icon)
                                }
                            )
                        }
                    }
                }
                .padding(.vertical, 8)
                .onAppear {
                    // 当视图出现时，滚动到初始记录类型位置
                    if let scrollType = selectedRecordType ?? initialRecordType {
                        let scrollId = "\(scrollType.category)\(scrollType.subCategory)"
                        // 延迟0.1秒执行滚动，确保视图完全布局完成
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation {
                                proxy.scrollTo(scrollId, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
        
        
    }
}

// MARK: - 时间选择组件
struct RecordTimeSelector: View {
    @Binding var startTimestamp: Date
    @Binding var endTimestamp: Date?
    @Binding var showEndTimePicker: Bool
    
    // 控制日期选择sheet的显示状态
    @State private var showStartTimeSheet = false
    @State private var showEndTimeSheet = false
    
    
    var body: some View {
        Section {
            // 开始时间
            VStack(alignment: .leading, spacing: 12) {
                Text("start_time".localized)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                
                Text(formatDateTime(startTimestamp, dateStyle: .long, timeStyle: .shortened))
                    .font(.title)
                    .foregroundColor(.primary)
            }
            .padding(.vertical, 8)
            
            // 结束时间
            if showEndTimePicker {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("end_time".localized)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Button {
                        showEndTimeSheet.toggle()
                    } label: {
                        Text(formatDateTime(startTimestamp, dateStyle: .long, timeStyle: .shortened))
                            .font(.title)
                            .foregroundColor(.primary)
                    }
                    
                    
                }
                .padding(.vertical, 8)
            }
            
            // 添加/移除结束时间按钮
            Button {
                if showEndTimePicker {
                    showEndTimePicker = false
                    endTimestamp = nil
                } else {
                    showEndTimePicker = true
                    endTimestamp = Date()
                }
            } label: {
                HStack {
                    Spacer()
                    Image(systemName: showEndTimePicker ? "minus.circle.fill" : "plus.circle.fill")
                        .foregroundColor(.blue)
                    Text(showEndTimePicker ? "移除结束时间" : "添加结束时间")
                        .foregroundColor(.blue)
                    Spacer()
                }
                .padding(.vertical, 8)
            }
        }
        // 开始时间选择 - 使用 sheet + presentation detents 控制高度
        .sheet(isPresented: $showStartTimeSheet) {
            DatePickerSheet(
                title: "选择开始时间",
                date: $startTimestamp,
                isPresented: $showStartTimeSheet,
                displayedComponents: [.date]
            )
            .presentationDetents([.height(460)])
            .presentationDragIndicator(.visible)
        }
        // 结束时间选择 - 使用 sheet + presentation detents 控制高度
        .sheet(isPresented: $showEndTimeSheet) {
            DatePickerSheet(
                title: "选择结束时间",
                optionalDate: $endTimestamp,
                isPresented: $showEndTimeSheet,
                displayedComponents: [.hourAndMinute]
            )
            .presentationDetents([.height(400)])
            .presentationDragIndicator(.visible)
        }
        
    }
}

// MARK: - 信息模块组件
struct RecordInfoSection: View {
    // 绑定参数
    @Binding var name: String
    @Binding var breastType: String
    @Binding var value: String
    @Binding var unit: String
    @Binding var dayOrNight: String
    @Binding var acceptance: String
    @Binding var excrementStatus: String
    
    // 计算属性，决定显示哪些字段
    let needsName: Bool
    let needsBreastType: Bool
    let needsValue: Bool
    let needsDayOrNight: Bool
    let needsAcceptance: Bool
    let needsExcrementStatus: Bool
    
    // 单位选项
    private let unitOptions: [String] = ["ml", "g", "kg", "cm", "degree", "tablet", "piece"]
    
    var body: some View {
        
        // 名称输入
        if needsName {
            TextField("name".localized, text: $name)
        }
        
        // 喂养侧选择
        if needsBreastType {
            Picker("breast_side".localized, selection: $breastType) {
                Text("both_sides".localized).tag("BOTH")
                Text("left_side".localized).tag("LEFT")
                Text("right_side".localized).tag("RIGHT")
            }
            .pickerStyle(.segmented)
        }
        
        // 用量输入
        if needsValue {
            HStack {
                TextField("amount".localized, text: $value)
                    .keyboardType(.decimalPad)
                
                Picker("", selection: $unit) {
                    ForEach(unitOptions, id: \.self) {
                        Text($0.localized)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 80)
            }
        }
        // 白天/黑夜选择
        
        if needsDayOrNight {
            Picker("day_night".localized, selection: $dayOrNight) {
                Text("daytime".localized).tag("DAY")
                Text("night".localized).tag("NIGHT")
            }
            .pickerStyle(.segmented)
        }
        
        // 接受程度选择
        if needsAcceptance {
            Picker("acceptance_level".localized, selection: $acceptance) {
                Text("like".localized).tag("LIKE")
                Text("neutral".localized).tag("NEUTRAL")
                Text("dislike".localized).tag("DISLIKE")
                Text("allergy".localized).tag("ALLERGY")
            }
            .pickerStyle(.segmented)
        }
        
        // 排泄物类型选择
        if needsExcrementStatus {
            Picker("excrement_type".localized, selection: $excrementStatus) {
                Text("urine".localized).tag("URINE")
                Text("stool".localized).tag("STOOL")
                Text("mixed".localized).tag("MIXED")
            }
            .pickerStyle(.segmented)
        }
    }
    
}

// MARK: - 补充信息组件
struct RecordAdditionalInfoSection: View {
    // 绑定参数
    @Binding var remark: String
    @Binding var photos: [Data]
    @Binding var tempImages: [Image]
    @Binding var tempImageDatas: [Data]
    
    var body: some View {
        
        // 备注
        TextField("remark".localized, text: $remark, axis: .vertical)
            .lineLimit(3, reservesSpace: true)
        
        // 照片
        VStack(alignment: .leading, spacing: 8) {
            Text("photos".localized)
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.fixed(80)), GridItem(.fixed(80)), GridItem(.fixed(80)), GridItem(.fixed(80))], spacing: 12) {
                ForEach(photos.indices, id: \.self) { index in
                    let photoData = photos[index]
                    if let uiImage = UIImage(data: photoData) {
                        ZStack(alignment: .topLeading) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            Button(action: {
                                // 删除照片
                                photos.remove(at: index)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .background(Color.white)
                                    .clipShape(Circle())
                            }
                            .offset(x: -4, y: -4)
                            .zIndex(1)
                        }
                    }
                }
                
                // 添加照片按钮
                ImagePickerMenu(
                    images: $tempImages,
                    imageDatas: $tempImageDatas,
                    allowsMultipleSelection: true,
                    allowsEditing: false
                )
            }
        }
    }
    
}

// MARK: - 主编辑视图
struct RecordEditView: View {
    let baby: Baby
    let recordType: (category: String, subCategory: String, icon: String)?
    let existingRecord: Record?
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // 基本信息
    @State private var startTimestamp: Date = Date()
    @State private var endTimestamp: Date? = nil
    @State private var showEndTimePicker: Bool = false
    @State private var name: String = ""
    @State private var value: String = ""
    @State private var unit: String = "ml"
    @State private var remark: String = ""
    @State private var photos: [Data] = []
    
    // 图片选择器
    @State private var showingImagePicker = false
    @State private var tempImages: [Image] = []
    @State private var tempImageDatas: [Data] = []
    
    // 类型特定信息
    @State private var breastType: String = "BOTH" // LEFT/RIGHT/BOTH
    @State private var dayOrNight: String = "DAY" // DAY/NIGHT
    @State private var acceptance: String = "NEUTRAL" // LIKE/NEUTRAL/DISLIKE/ALLERGY
    @State private var excrementStatus: String = "URINE" // URINE/STOOL/MIXED
    
    // 错误信息
    @State private var errorMessage: String? = nil
    @State private var showingErrorAlert = false
    
    // 当前选择的记录类型（用于支持选择和重新选择）
    @State private var selectedRecordType: (category: String, subCategory: String, icon: String)?
    
    // 获取当前有效的记录类型
    private var currentRecordType: (category: String, subCategory: String, icon: String)? {
        return selectedRecordType ?? recordType
    }
    
    // 是否需要结束时间
    private var needsEndTime: Bool {
        guard let subCategory = currentRecordType?.subCategory ?? existingRecord?.subCategory else {
            return false
        }
        return subCategory == "nursing" || subCategory == "sleep"
    }
    
    // 是否需要名称
    private var needsName: Bool {
        guard let subCategory = currentRecordType?.subCategory ?? existingRecord?.subCategory else {
            return false
        }
        return subCategory == "medical_visit" || subCategory == "medication" || subCategory == "supplement" || subCategory == "vaccination"
    }
    
    // 是否需要喂养侧
    private var needsBreastType: Bool {
        guard let subCategory = currentRecordType?.subCategory ?? existingRecord?.subCategory else {
            return false
        }
        return subCategory == "nursing"
    }
    
    // 是否需要用量
    private var needsValue: Bool {
        guard let subCategory = currentRecordType?.subCategory ?? existingRecord?.subCategory else {
            return false
        }
        return ["formula", "water_intake", "breast_milk", "solid_food", "height", "weight", "head", "jaundice", "medication", "supplement"].contains(subCategory)
    }
    
    // 是否需要白天/黑夜
    private var needsDayOrNight: Bool {
        guard let subCategory = currentRecordType?.subCategory ?? existingRecord?.subCategory else {
            return false
        }
        return subCategory == "sleep"
    }
    
    // 是否需要接受程度
    private var needsAcceptance: Bool {
        guard let subCategory = currentRecordType?.subCategory ?? existingRecord?.subCategory else {
            return false
        }
        return subCategory == "solid_food"
    }
    
    // 是否需要排泄物类型
    private var needsExcrementStatus: Bool {
        guard let subCategory = currentRecordType?.subCategory ?? existingRecord?.subCategory else {
            return false
        }
        return subCategory == "diaper"
    }
    
    // 单位选项
    private let unitOptions: [String] = ["ml", "g", "kg", "cm", "degree", "tablet", "piece"]
    
    // 获取时间段标签
    private func getTimePeriod(date: Date) -> String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        
        if hour >= 6 && hour < 12 {
            return "早上"
        } else if hour >= 12 && hour < 14 {
            return "中午"
        } else if hour >= 14 && hour < 18 {
            return "下午"
        } else if hour >= 18 && hour < 22 {
            return "晚上"
        } else {
            return "凌晨"
        }
    }
    
    // 格式化日期显示
    private func formatDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        
        // 检查是否为今天
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "今天 " + formatter.string(from: date)
        } else {
            return formatter.string(from: date)
        }
    }
    
    // 格式化时间显示
    private func formatTime(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    // 初始化现有记录数据
    init(baby: Baby, recordType: (category: String, subCategory: String, icon: String)? = nil, existingRecord: Record? = nil) {
        self.baby = baby
        self.recordType = recordType
        self.existingRecord = existingRecord
        
        if let record = existingRecord {
            _startTimestamp = State(initialValue: record.startTimestamp)
            _endTimestamp = State(initialValue: record.endTimestamp)
            _showEndTimePicker = State(initialValue: record.endTimestamp != nil)
            _name = State(initialValue: record.name ?? "")
            _value = State(initialValue: record.value != nil ? String(record.value!) : "")
            _unit = State(initialValue: record.unit ?? "ml")
            _remark = State(initialValue: record.remark ?? "")
            _photos = State(initialValue: record.photos ?? [])
            _breastType = State(initialValue: record.breastType ?? "BOTH")
            _dayOrNight = State(initialValue: record.dayOrNight ?? "DAY")
            _acceptance = State(initialValue: record.acceptance ?? "NEUTRAL")
            _excrementStatus = State(initialValue: record.excrementStatus ?? "URINE")
            
            // 从现有记录中提取recordType信息并设置selectedRecordType的初始值
            _selectedRecordType = State(initialValue: (category: record.category, subCategory: record.subCategory, icon: record.icon))
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // 记录类型选择（横向滚动）
                RecordTypeSelector(
                    selectedRecordType: $selectedRecordType,
                    initialRecordType: recordType
                )
                
                // 时间选择模块
                RecordTimeSelector(
                    startTimestamp: $startTimestamp,
                    endTimestamp: $endTimestamp,
                    showEndTimePicker: $showEndTimePicker
                )
                
                // 信息模块
                RecordInfoSection(
                    name: $name,
                    breastType: $breastType,
                    value: $value,
                    unit: $unit,
                    dayOrNight: $dayOrNight,
                    acceptance: $acceptance,
                    excrementStatus: $excrementStatus,
                    needsName: needsName,
                    needsBreastType: needsBreastType,
                    needsValue: needsValue,
                    needsDayOrNight: needsDayOrNight,
                    needsAcceptance: needsAcceptance,
                    needsExcrementStatus: needsExcrementStatus
                )
                
                // 补充信息模块
                RecordAdditionalInfoSection(
                    remark: $remark,
                    photos: $photos,
                    tempImages: $tempImages,
                    tempImageDatas: $tempImageDatas
                )
            }
            .navigationTitle(existingRecord != nil ? "edit_record".localized : "create_record".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 保存按钮
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("save".localized) {
                        saveRecord()
                    }
                    .disabled(existingRecord == nil && currentRecordType == nil)
                }
                
                // 删除按钮（仅编辑模式）
                if existingRecord != nil {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(role: .destructive, action: {
                            deleteRecord()
                        }) {
                            Text("delete".localized)
                        }
                    }
                }
            }
            .toolbar(.hidden, for: .tabBar)
            
            .onChange(of: tempImageDatas) { oldValue, newValue in
                if !newValue.isEmpty {
                    photos.append(contentsOf: newValue)
                    tempImageDatas.removeAll()
                }
            }
            
            // 错误提示
            .alert(isPresented: $showingErrorAlert) {
                Alert(
                    title: Text("save_failed".localized),
                    message: Text(errorMessage ?? "unknown_error".localized),
                    dismissButton: .default(Text("ok".localized))
                )
            }
        }
    }
    
    private func saveRecord() {
        // 重置错误信息
        errorMessage = nil
        
        // 输入验证
        if needsName && name.isEmpty {
            errorMessage = "please_enter_name".localized
            showingErrorAlert = true
            return
        }
        
        if needsValue {
            if value.isEmpty {
                errorMessage = "please_enter_amount".localized
                showingErrorAlert = true
                return
            }
            
            if Double(value) == nil {
                errorMessage = "please_enter_valid_number".localized
                showingErrorAlert = true
                return
            }
        }
        
        // 获取当前有效的记录类型（优先使用用户选择的，其次使用传入的，最后使用现有记录的）
        let finalRecordType = currentRecordType
        
        guard let category = finalRecordType?.category ?? existingRecord?.category,
              let subCategory = finalRecordType?.subCategory ?? existingRecord?.subCategory,
              let icon = finalRecordType?.icon ?? existingRecord?.icon else {
            errorMessage = "record_type_incomplete".localized
            showingErrorAlert = true
            return
        }
        
        do {
            // 开始事务
            try modelContext.transaction {
                if let existingRecord = self.existingRecord {
                    // 更新现有记录
                    existingRecord.startTimestamp = startTimestamp
                    existingRecord.endTimestamp = endTimestamp
                    existingRecord.name = needsName ? name : nil
                    existingRecord.value = needsValue && !value.isEmpty ? Double(value) : nil
                    existingRecord.unit = needsValue ? unit : nil
                    existingRecord.remark = !remark.isEmpty ? remark : nil
                    existingRecord.photos = !photos.isEmpty ? photos : nil
                    existingRecord.breastType = needsBreastType ? breastType : nil
                    existingRecord.dayOrNight = needsDayOrNight ? dayOrNight : nil
                    existingRecord.acceptance = needsAcceptance ? acceptance : nil
                    existingRecord.excrementStatus = needsExcrementStatus ? excrementStatus : nil
                } else {
                    // 创建新记录
                    let newRecord = Record(
                        babyId: baby.id,
                        icon: icon,
                        category: category,
                        subCategory: subCategory,
                        startTimestamp: startTimestamp
                    )
                    
                    // 设置记录属性
                    newRecord.endTimestamp = endTimestamp
                    newRecord.name = needsName ? name : nil
                    newRecord.value = needsValue && !value.isEmpty ? Double(value) : nil
                    newRecord.unit = needsValue ? unit : nil
                    newRecord.remark = !remark.isEmpty ? remark : nil
                    newRecord.photos = !photos.isEmpty ? photos : nil
                    newRecord.breastType = needsBreastType ? breastType : nil
                    newRecord.dayOrNight = needsDayOrNight ? dayOrNight : nil
                    newRecord.acceptance = needsAcceptance ? acceptance : nil
                    newRecord.excrementStatus = needsExcrementStatus ? excrementStatus : nil
                    
                    // 插入新记录
                    modelContext.insert(newRecord)
                }
            }
            
            // 保存成功，关闭视图
            dismiss()
        } catch {
            errorMessage = "save_failed".localized + "：\(error.localizedDescription)"
            showingErrorAlert = true
        }
    }
    
    private func deleteRecord() {
        if let existing = existingRecord {
            modelContext.delete(existing)
        }
        dismiss()
    }
}
