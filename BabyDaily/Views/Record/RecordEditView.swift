import SwiftUI
import SwiftData
import UIKit
import Combine

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
                            .fill(isSelected ? action.color.opacity(0.8) : .secondary.opacity(0.1))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Circle()
                                    .stroke(isSelected ? action.color : .secondary.opacity(0.2), lineWidth: 2)
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
    
    // 生成所有记录类型按钮
    private var recordTypeButtons: some View {
        HStack(spacing: 16) {
            // 将所有分类下的记录类型合并到一个列表
            recordTypeButtonsContent
        }
        .padding(.vertical, 8)
    }
    
    // 分解ForEach循环为单独的计算属性
    private var recordTypeButtonsContent: some View {
        // 使用Group来组合多个ForEach
        Group {
            // 按分类生成按钮
            ForEach(getSortedCategories(), id: \.category) { item in
                // 为每个分类生成按钮
                categoryButtons(category: item.category, actions: item.actions)
            }
        }
    }
    
    // 获取原始顺序的分类
    private func getSortedCategories() -> [(category: String, actions: [(icon: String, name: String, color: Color)])] {
        // 直接返回数组，保持原始顺序
        return Constants.allCategorysByOrder
    }
    
    // 为单个分类生成按钮
    private func categoryButtons(category: String, actions: [(icon: String, name: String, color: Color)]) -> some View {
        ForEach(actions, id: \.name) { action in
            ActionButton(
                category: category,
                action: action,
                isSelected: isActionSelected(action: action),
                onTap: {
                    selectAction(category: category, action: action)
                }
            )
        }
    }
    
    // 检查动作是否被选中
    private func isActionSelected(action: (icon: String, name: String, color: Color)) -> Bool {
        return currentSelectedType?.subCategory == action.name
    }
    
    // 选择动作
    private func selectAction(category: String, action: (icon: String, name: String, color: Color)) {
        selectedRecordType = (category: category, subCategory: action.name, icon: action.icon)
    }
    
    // 滚动到初始记录类型位置
    private func scrollToInitialType(proxy: ScrollViewProxy) {
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
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                recordTypeButtons
            }
            .onAppear {
                scrollToInitialType(proxy: proxy)
            }
        }
    }
}

// MARK: - 时间选择组件
struct RecordTimeSelector: View {
    @Binding var startTimestamp: Date
    @Binding var endTimestamp: Date?
    @Binding var showEndTimePicker: Bool
    
    // 控制日期和时间选择sheet的显示状态
    @State private var showStartDateSheet = false
    @State private var showStartTimeSheet = false
    @State private var showEndDateSheet = false
    @State private var showEndTimeSheet = false
    
    // 辅助函数：获取日期相对时间描述（今天、昨天、几天前）
    private func getRelativeDateDescription(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "今天"
        } else if calendar.isDateInYesterday(date) {
            return "昨天"
        } else {
            let components = calendar.dateComponents([.day], from: date, to: now)
            let days = components.day ?? 0
            if days < 0 {
                return "\(days)天后"
            } else {
                return "\(days)天前" 
            }
        }
    }
    
    // 辅助函数：获取时间段标签（早上、中午、下午、晚上、凌晨）
    private func getTimePeriod(_ date: Date) -> String {
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
    
    var body: some View {
        VStack(alignment: .leading) {
            // 开始时间
            VStack(alignment: .leading, spacing: 12) {
                // 日期部分
                HStack(spacing: 8) {
                    Text("start_time".localized)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)

                    Spacer()

                    // 相对时间标签
                    if !getRelativeDateDescription(startTimestamp).isEmpty {
                        Text(getRelativeDateDescription(startTimestamp))
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray6))
                            .cornerRadius(6)
                    }
                    
                    // 具体日期
                    Button(action: {
                        showStartDateSheet.toggle()
                    }) {
                        Text(formatDateTime(startTimestamp, dateStyle: .long, timeStyle: .omitted))
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                    }
                }
                
                // 时间部分
                HStack(alignment: .center, spacing: 8) {
                    Button(action: {
                        showStartTimeSheet.toggle()
                    }) {
                        Text(formatDateTime(startTimestamp, dateStyle: .omitted, timeStyle: .shortened))
                            .font(.system(size: 36))
                            .foregroundColor(.primary)
                    }
                                    
                    Text(getTimePeriod(startTimestamp))
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)

                    Spacer()
                }
                
            }
            .padding(.vertical, 8)
            
            // 结束时间
            if showEndTimePicker && endTimestamp != nil {
                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    // 日期部分
                    HStack(spacing: 8) {
                        Text("end_time".localized)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)

                        Spacer()
                            
                        // 相对时间标签
                        if let endDate = endTimestamp, !getRelativeDateDescription(endDate).isEmpty {
                            Text(getRelativeDateDescription(endDate))
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.systemGray6))
                                .cornerRadius(4)
                        }
                        // 具体日期
                        Button(action: {
                            showEndDateSheet.toggle()
                        }) {
                            Text(formatDateTime(endTimestamp!, dateStyle: .long, timeStyle: .omitted))
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                        }
                    }

                    // 时间部分
                    HStack(alignment: .center, spacing: 8) {
                         Button(action: {
                            showEndTimeSheet.toggle()
                        }) {
                            Text(formatDateTime(endTimestamp!, dateStyle: .omitted, timeStyle: .shortened))
                                .font(.system(size: 36))
                                .foregroundColor(.primary)
                        }
                      
                        Text(getTimePeriod(endTimestamp!))
                            .font(.system(size: 2))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray6))
                            .cornerRadius(4)
                    }
                }
                .padding(.vertical, 8)
            }
            
            // 添加/移除结束时间按钮
            HStack {
                Spacer()
                Button {
                    if showEndTimePicker {
                        showEndTimePicker = false
                        endTimestamp = nil
                    } else {
                        endTimestamp = Date()
                        showEndTimePicker = true
                    }
                } label: {
                    Image(systemName: showEndTimePicker ? "minus.circle.fill" : "plus.circle.fill")
                            .foregroundColor(.blue)
                    Text(showEndTimePicker ? "移除结束时间" : "添加结束时间")
                            .foregroundColor(.blue)
                }
                    
                Spacer()
            }
            .font(.system(size: 14))
            .padding(.vertical, 8)
           
        }
        // 开始日期选择 - 使用 sheet + presentation detents 控制高度
        .sheet(isPresented: $showStartDateSheet) {
            DatePickerSheet(
                date: $startTimestamp,
                isPresented: $showStartDateSheet,
                displayedComponents: [.date]
            )
            .presentationDetents([.height(460)])
            .presentationDragIndicator(.visible)
        }
        // 开始时间选择 - 使用 sheet + presentation detents 控制高度
        .sheet(isPresented: $showStartTimeSheet) {
            DatePickerSheet(
                date: $startTimestamp,
                isPresented: $showStartTimeSheet,
                displayedComponents: [.hourAndMinute]
            )
            .presentationDetents([.height(300)])
            .presentationDragIndicator(.visible)
        }
        // 结束日期选择 - 使用 sheet + presentation detents 控制高度
        .sheet(isPresented: $showEndDateSheet) {
            DatePickerSheet(
                optionalDate: $endTimestamp,
                isPresented: $showEndDateSheet,
                displayedComponents: [.date]
            )
            .presentationDetents([.height(460)])
            .presentationDragIndicator(.visible)
        }
        // 结束时间选择 - 使用 sheet + presentation detents 控制高度
        .sheet(isPresented: $showEndTimeSheet) {
            DatePickerSheet(
                optionalDate: $endTimestamp,
                isPresented: $showEndTimeSheet,
                displayedComponents: [.hourAndMinute]
            )
            .presentationDetents([.height(300)])
            .presentationDragIndicator(.visible)
        }
        
    }
}

// MARK: - 信息模块组件
struct RecordInfoSection: View {
    // 绑定参数
    let subCategory: String?
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
    
    // 单位管理
    let unitManager: UnitManager
    
    // 控制单位设置页面显示
    @State private var showUnitSettingSheet = false
    
    // 根据 subCategory 获取默认单位
    private var defaultUnit: String {
        guard let subCategory = subCategory else { return "" }
        
        switch subCategory {
        case "breast_bottle", "formula", "water_intake", "nursing", "pumping":
            return unitManager.volumeUnit.rawValue
        case "height", "head":
            return unitManager.lengthUnit.rawValue
        case "temperature":
            return unitManager.temperatureUnit.rawValue
        case "weight":
            return unitManager.weightUnit.rawValue
        case "jaundice":
            return "mg/dL"
        default:
            return ""
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 名称输入
            if needsName {
                TextField((subCategory?.localized ?? "") + "name".localized, text: $name)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(Constants.cornerRadius)
                    .keyboardDoneButton()
                    .submitLabel(.done)
            }
            
            // 喂养侧选择
            if needsBreastType {
                Picker("breast_side".localized, selection: $breastType) {
                    Text("both_sides".localized).tag("BOTH")
                    Text("left_side".localized).tag("LEFT")
                    Text("right_side".localized).tag("RIGHT")
                }
                .font(.system(size: 16))
                .pickerStyle(.segmented)
                .controlSize(.large)
                .tint(.accentColor)
            }
            
            // 用量输入
            if needsValue {
                HStack(spacing: 4) {
                    TextField("数量".localized, text: $value)
                        .keyboardType(.decimalPad)
                        .keyboardDoneButton()
                        .submitLabel(.done)
                        .autocorrectionDisabled()

                    Button(action: {
                        showUnitSettingSheet.toggle()
                    }) {
                        Text(defaultUnit.localized ?? "")
                            .font(.body)
                            .foregroundColor(.accentColor)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
                // 确保单位正确设置
                .onAppear {
                    if unit.isEmpty {
                        unit = defaultUnit
                    }
                }
                .onChange(of: subCategory) {
                    unit = defaultUnit
                }
            }

            // 白天/黑夜选择
            if needsDayOrNight {
                Picker("day_night".localized, selection: $dayOrNight) {
                    Label("daytime".localized, systemImage: "sunrise").tag("DAY")
                    Label("night".localized, systemImage: "moon.stars").tag("NIGHT")
                }
                .pickerStyle(.segmented)
                .controlSize(.large)
                .tint(.accentColor)
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
                .controlSize(.large)
                .tint(.accentColor)
            }
            
            // 排泄物类型选择
            if needsExcrementStatus {
                Picker("excrement_type".localized, selection: $excrementStatus) {
                    Text("urine".localized).tag("URINE")
                    Text("stool".localized).tag("STOOL")
                    Text("mixed".localized).tag("MIXED")
                }
                .pickerStyle(.segmented)
                .controlSize(.large)
                .tint(.accentColor)
            }
        }
        // 单位设置页面
        .sheet(isPresented: $showUnitSettingSheet, onDismiss: {
            // 当单位设置页面关闭时，更新当前单位
            unit = defaultUnit
        }) {
            UnitSettingView()
        }
    }
    
}

// 补充信息组件
struct RecordAdditionalInfoSection: View {
    // 绑定参数
    @Binding var remark: String
    @Binding var photos: [Data]
    @Binding var tempImages: [Image]
    @Binding var tempImageDatas: [Data]
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        // 备注
        TextField("remark".localized, text: $remark, axis: .vertical)
            .padding()
            .frame(minHeight: 120) // 确保至少显示4行，根据字体大小调整高度
            .background(Color(.systemGray6))
            .cornerRadius(Constants.cornerRadius)
            .lineLimit(10) // 设置最大10行的限制
            .keyboardDoneButton()
            .submitLabel(.done)
        
        Divider()
            .padding(.bottom, 8)

        // 照片
        VStack(alignment: .leading, spacing: 12) {
            Text("photos".localized)
                .font(.caption)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns:  [GridItem(.adaptive(minimum: 75), spacing: 12)], spacing: 12) {
                ForEach(photos.indices, id: \.self) { index in
                    let photoData = photos[index]
                    if let uiImage = UIImage(data: photoData) {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 75, height: 75)
                                .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
                            
                            Button(action: {
                                // 删除照片
                                photos.remove(at: index)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .background(colorScheme == .light ? Color.white : Color(.systemGray6))
                                    .clipShape(Circle())
                            }
                            .offset(x: 4, y: -4)
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
            }.padding(.leading, 0)
        }
    }
}

// MARK: - 主编辑视图
struct RecordEditView: View {
    let baby: Baby
    let recordType: (category: String, subCategory: String, icon: String)?
    let existingRecord: Record?
    var onSaveSuccess: ((String) -> Void)?
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // 单位管理
    @StateObject private var unitManager = UnitManager.shared
    
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
    
    // 获取当前有效的子分类
    private var currentSubCategory: String? {
        return currentRecordType?.subCategory ?? existingRecord?.subCategory
    }
    
    // 是否需要名称
    private var needsName: Bool {
        let subCategory = currentSubCategory
        return subCategory == "medical_visit" || subCategory == "medication" || subCategory == "supplement" || subCategory == "vaccination"  || subCategory == "solid_food" 
    }
    
    // 是否需要喂养侧
    private var needsBreastType: Bool {
        let subCategory = currentSubCategory
        return subCategory == "nursing" || subCategory == "pumping"
    }
    
    // 是否需要用量
    private var needsValue: Bool {
        let subCategory = currentSubCategory
        return ["formula", "water_intake", "breast_bottle", "breast_milk", "height", "weight", "head", "jaundice", "pumping", "temperature"].contains(subCategory)
    }
    
    // 是否需要白天/黑夜
    private var needsDayOrNight: Bool {
        let subCategory = currentSubCategory
        return subCategory == "sleep"
    }
    
    // 是否需要接受程度
    private var needsAcceptance: Bool {
        let subCategory = currentSubCategory
        return subCategory == "solid_food"
    }
    
    // 是否需要排泄物类型
    private var needsExcrementStatus: Bool {
        let subCategory = currentSubCategory
        return subCategory == "diaper"
    }
    
    // 初始化现有记录数据
    init(baby: Baby, recordType: (category: String, subCategory: String, icon: String)? = nil, existingRecord: Record? = nil, onSaveSuccess: ((String) -> Void)? = nil) {
        self.baby = baby
        self.recordType = recordType
        self.existingRecord = existingRecord
        self.onSaveSuccess = onSaveSuccess
        
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
    
    // 分解body为更小的计算属性
    private var recordTypeSection: some View {
        VStack(spacing: 16) {
            RecordTypeSelector(
                selectedRecordType: $selectedRecordType,
                initialRecordType: recordType
            )
        }
        .padding()
        .background(colorScheme == .light ? Color.white : Color(.systemGray6))
    }
    
    private var timeSection: some View {
        VStack (alignment: .leading, spacing: 8) {
            Text("时间信息".localized)
                .font(.caption)
                .foregroundColor(.secondary)

            VStack(spacing: 16) {
                RecordTimeSelector(
                    startTimestamp: $startTimestamp,
                    endTimestamp: $endTimestamp,
                    showEndTimePicker: $showEndTimePicker
                )
            } 
            .padding()
            .background(colorScheme == .light ? Color.white : Color(.systemGray6))
            .cornerRadius(Constants.cornerRadius)
        }
    }
    
    private var infoSection: some View {
        let shouldShowInfoSection = needsName || needsBreastType || needsValue || needsDayOrNight || needsAcceptance || needsExcrementStatus
        
        if shouldShowInfoSection {
            return AnyView(
                VStack(alignment: .leading, spacing: 8) {
                    Text("基础信息".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    VStack(spacing: 16) {
                        RecordInfoSection(
                            subCategory: currentSubCategory,
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
                            needsExcrementStatus: needsExcrementStatus,
                            unitManager: unitManager
                        )
                    }
                    .padding()
                    .background(colorScheme == .light ? Color.white : Color(.systemGray6))
                    .cornerRadius(Constants.cornerRadius)
            })
        } else {
            return AnyView(EmptyView())
        }
    }
    
    private var additionalInfoSection: some View {
        VStack (alignment: .leading, spacing: 8) {
            Text("补充信息".localized)
                .font(.caption)
                .foregroundColor(.secondary)

            VStack(spacing: 16) {
                RecordAdditionalInfoSection(
                    remark: $remark,
                    photos: $photos,
                    tempImages: $tempImages,
                    tempImageDatas: $tempImageDatas
                )
            }
            .padding()
            .background(colorScheme == .light ? Color.white : Color(.systemGray6))
            .cornerRadius(Constants.cornerRadius)
        }
    }
    
    var body: some View {
            NavigationStack {
                VStack(spacing: 8) {
                    recordTypeSection
                    mainScrollView
                }
                .background(colorScheme == .light ? Color(.systemGray6) : Color.black)
                .navigationTitle(getNavigationTitle())
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent() }
                .toolbar(.hidden, for: .tabBar)
                .onChange(of: tempImageDatas) { oldValue, newValue in
                    handleImageDataChange(oldValue: oldValue, newValue: newValue)
                }
                .alert(isPresented: $showingErrorAlert) {
                    errorAlert
                }
            }
    }
    
    // 主滚动视图
    private var mainScrollView: some View {
        ScrollView {
            VStack(spacing: 16) {
                timeSection
                infoSection
                additionalInfoSection
                Spacer()
            }
            .padding()
            .padding(.top, 0)
            .padding(.bottom, 24)
        }
        // 添加点击手势，点击外部关闭键盘
        .gesture(
            TapGesture()
                .onEnded {
                    // 关闭所有键盘
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
        )
    }
    
    // 获取导航标题
    private func getNavigationTitle() -> String {
        return existingRecord != nil ? "edit_record".localized : "create_record".localized
    }
    
    // 工具栏内容
    private func toolbarContent() -> some ToolbarContent {
        // 使用Group来组合多个ToolbarItem
        Group {
            // 删除按钮（仅编辑模式）
            if existingRecord != nil {
                ToolbarItem(placement: .navigationBarLeading) {
                    deleteButton
                }
            }
            
            // 保存按钮
            ToolbarItem(placement: .navigationBarTrailing) {
                saveButton
            }
        }
    }
    
    // 删除按钮
    private var deleteButton: some View {
        Button(role: .destructive, action: {
            deleteRecord()
        }) {
            Text("delete".localized)
        }
    }
    
    // 保存按钮
    private var saveButton: some View {
        Button("save".localized) {
            saveRecord()
        }
        .disabled(isSaveButtonDisabled())
    }
    
    // 检查保存按钮是否应该禁用
    private func isSaveButtonDisabled() -> Bool {
        return existingRecord == nil && currentRecordType == nil
    }
    
    // 处理图片数据变化
    private func handleImageDataChange(oldValue: [Data], newValue: [Data]) {
        if !newValue.isEmpty {
            photos.append(contentsOf: newValue)
            tempImageDatas.removeAll()
        }
    }
    
    // 错误提示
    private var errorAlert: Alert {
        Alert(
            title: Text("save_failed".localized),
            message: Text(errorMessage ?? "unknown_error".localized),
            dismissButton: .default(Text("ok".localized))
        )
    }
    
    // 保存记录
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
            if existingRecord == nil {
                onSaveSuccess?(subCategory)
            }
            dismiss()
        } catch {
            errorMessage = "save_failed".localized + "：\(error.localizedDescription)"
            showingErrorAlert = true
        }
    }
    
    // 删除记录
    private func deleteRecord() {
        if let existing = existingRecord {
            modelContext.delete(existing)
        }
        dismiss()
    }
}
