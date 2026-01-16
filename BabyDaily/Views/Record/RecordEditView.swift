import SwiftUI
import SwiftData
import UIKit

struct RecordEditView: View {
    let baby: Baby
    let recordType: (category: String, subCategory: String, icon: String)?
    let existingRecord: Record?
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // 基本信息
    @State private var startTimestamp: Date = Date()
    @State private var endTimestamp: Date? = nil
    @State private var name: String = ""
    @State private var value: String = ""
    @State private var unit: String = "ml"
    @State private var remark: String = ""
    @State private var photos: [Data] = []
    
    // 图片选择器
    @State private var showingImagePicker = false
    @State private var tempImage: Image?
    @State private var tempImageData: Data? = nil
    
    // 类型特定信息
    @State private var breastType: String = "BOTH" // LEFT/RIGHT/BOTH
    @State private var dayOrNight: String = "DAY" // DAY/NIGHT
    @State private var acceptance: String = "NEUTRAL" // LIKE/NEUTRAL/DISLIKE/ALLERGY
    @State private var excrementStatus: String = "URINE" // URINE/STOOL/MIXED
    
    // 是否需要结束时间
    private var needsEndTime: Bool {
        guard let subCategory = recordType?.subCategory ?? existingRecord?.subCategory else {
            return false
        }
        return subCategory == "亲喂" || subCategory == "睡觉"
    }
    
    // 是否需要名称
    private var needsName: Bool {
        guard let subCategory = recordType?.subCategory ?? existingRecord?.subCategory else {
            return false
        }
        return subCategory == "就医" || subCategory == "用药" || subCategory == "补剂" || subCategory == "疫苗"
    }
    
    // 是否需要喂养侧
    private var needsBreastType: Bool {
        guard let subCategory = recordType?.subCategory ?? existingRecord?.subCategory else {
            return false
        }
        return subCategory == "亲喂"
    }
    
    // 是否需要用量
    private var needsValue: Bool {
        guard let subCategory = recordType?.subCategory ?? existingRecord?.subCategory else {
            return false
        }
        return ["奶粉", "水", "母乳", "辅食", "身高", "体重", "头围", "黄疸", "用药", "补剂"].contains(subCategory)
    }
    
    // 是否需要白天/黑夜
    private var needsDayOrNight: Bool {
        guard let subCategory = recordType?.subCategory ?? existingRecord?.subCategory else {
            return false
        }
        return subCategory == "睡觉"
    }
    
    // 是否需要接受程度
    private var needsAcceptance: Bool {
        guard let subCategory = recordType?.subCategory ?? existingRecord?.subCategory else {
            return false
        }
        return subCategory == "辅食"
    }
    
    // 是否需要排泄物类型
    private var needsExcrementStatus: Bool {
        guard let subCategory = recordType?.subCategory ?? existingRecord?.subCategory else {
            return false
        }
        return subCategory == "纸尿裤"
    }
    
    // 单位选项
    private let unitOptions: [String] = ["ml", "g", "kg", "cm", "度", "片", "块"]
    
    // 初始化现有记录数据
    init(baby: Baby, recordType: (category: String, subCategory: String, icon: String)? = nil, existingRecord: Record? = nil) {
        self.baby = baby
        self.recordType = recordType
        self.existingRecord = existingRecord
        
        if let record = existingRecord {
            _startTimestamp = State(initialValue: record.startTimestamp)
            _endTimestamp = State(initialValue: record.endTimestamp)
            _name = State(initialValue: record.name ?? "")
            _value = State(initialValue: record.value != nil ? String(record.value!) : "")
            _unit = State(initialValue: record.unit ?? "ml")
            _remark = State(initialValue: record.remark ?? "")
            _photos = State(initialValue: record.photos ?? [])
            _breastType = State(initialValue: record.breastType ?? "BOTH")
            _dayOrNight = State(initialValue: record.dayOrNight ?? "DAY")
            _acceptance = State(initialValue: record.acceptance ?? "NEUTRAL")
            _excrementStatus = State(initialValue: record.excrementStatus ?? "URINE")
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // 时间选择模块
                Section("时间") {
                    DatePicker("开始时间", selection: $startTimestamp, displayedComponents: [.date, .hourAndMinute])
                    
                    if needsEndTime {
                        DatePicker("结束时间", selection: Binding(
                            get: { endTimestamp ?? Date() },
                            set: { endTimestamp = $0 }
                        ), displayedComponents: [.date, .hourAndMinute])
                    }
                }
                
                // 信息模块
                Section("信息") {
                    // 名称输入
                    if needsName {
                        TextField("名称", text: $name)
                    }
                    
                    // 喂养侧选择
                    if needsBreastType {
                        Picker("喂养侧", selection: $breastType) {
                            Text("双侧").tag("BOTH")
                            Text("左侧").tag("LEFT")
                            Text("右侧").tag("RIGHT")
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // 用量输入
                    if needsValue {
                        HStack {
                            TextField("用量", text: $value)
                                .keyboardType(.decimalPad)
                            
                            Picker("", selection: $unit) {
                                ForEach(unitOptions, id: \.self) {
                                    Text($0)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 80)
                        }
                    }
                    
                    // 白天/黑夜选择
                    if needsDayOrNight {
                        Picker("时段", selection: $dayOrNight) {
                            Text("白天").tag("DAY")
                            Text("黑夜").tag("NIGHT")
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // 接受程度选择
                    if needsAcceptance {
                        Picker("接受程度", selection: $acceptance) {
                            Text("喜欢").tag("LIKE")
                            Text("一般").tag("NEUTRAL")
                            Text("不喜欢").tag("DISLIKE")
                            Text("过敏").tag("ALLERGY")
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // 排泄物类型选择
                    if needsExcrementStatus {
                        Picker("排泄物类型", selection: $excrementStatus) {
                            Text("小便").tag("URINE")
                            Text("大便").tag("STOOL")
                            Text("混合").tag("MIXED")
                        }
                        .pickerStyle(.segmented)
                    }
                }
                
                // 补充信息模块
                Section("补充信息") {
                    // 备注
                    TextField("备注", text: $remark, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                    
                    // 照片
                    VStack(alignment: .leading, spacing: 8) {
                        Text("照片")
                            .font(.headline)
                        
                        HStack(spacing: 12) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(photos, id: \.self) {
                                        photoData in
                                        if let uiImage = UIImage(data: photoData) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 80, height: 80)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .overlay(
                                                    Button(action: {
                                                        // 删除照片
                                                        if let index = photos.firstIndex(of: photoData) {
                                                            photos.remove(at: index)
                                                        }
                                                    }) {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .foregroundColor(.red)
                                                            .background(Color.white)
                                                            .clipShape(Circle())
                                                    }
                                                    .offset(x: -8, y: -8)
                                                    .zIndex(1)
                                                , alignment: .topLeading)
                                        }
                                    }
                                }
                            }
                            
                            // 添加照片按钮
                            ImagePickerMenu(image: $tempImage, imageData: $tempImageData)
                        }
                    }
                }
            }
            .navigationTitle(existingRecord != nil ? "编辑记录" : "创建记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 保存按钮
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveRecord()
                    }
                    .disabled(existingRecord == nil && recordType == nil)
                }
                
                // 删除按钮（仅编辑模式）
                if existingRecord != nil {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(role: .destructive, action: {
                            deleteRecord()
                        }) {
                            Text("删除")
                        }
                    }
                }
            }

            .onChange(of: tempImageData) {
                if let data = $0 {
                    photos.append(data)
                    tempImageData = nil
                }
            }
        }
    }
    
    private func saveRecord() {
        guard let category = recordType?.category ?? existingRecord?.category, 
              let subCategory = recordType?.subCategory ?? existingRecord?.subCategory, 
              let icon = recordType?.icon ?? existingRecord?.icon else {
            return
        }
        
        let record: Record
        
        if let existing = existingRecord {
            // 更新现有记录
            record = existing
        } else {
            // 创建新记录
            record = Record(
                babyId: baby.id,
                icon: icon,
                category: category,
                subCategory: subCategory,
                startTimestamp: startTimestamp
            )
            modelContext.insert(record)
        }
        
        // 更新基本信息
        record.startTimestamp = startTimestamp
        record.endTimestamp = endTimestamp
        record.name = needsName ? name : nil
        record.value = needsValue && !value.isEmpty ? Int(value) : nil
        record.unit = needsValue ? unit : nil
        record.remark = !remark.isEmpty ? remark : nil
        record.photos = !photos.isEmpty ? photos : nil
        
        // 更新类型特定信息
        record.breastType = needsBreastType ? breastType : nil
        record.dayOrNight = needsDayOrNight ? dayOrNight : nil
        record.acceptance = needsAcceptance ? acceptance : nil
        record.excrementStatus = needsExcrementStatus ? excrementStatus : nil
        
        // 保存到数据库
        dismiss()
    }
    
    private func deleteRecord() {
        if let existing = existingRecord {
            modelContext.delete(existing)
        }
        dismiss()
    }
}