import SwiftUI
import CoreData

struct RecordDetailView: View {
    let recordId: UUID
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @FetchRequest private var records: FetchedResults<Record>
    @FetchRequest private var babies: FetchedResults<Baby>
    
    @State private var showingDeleteConfirmation = false
    @State private var isNavigatingToEdit = false
    @State private var isShowingImagePreview = false
    @State private var selectedImageIndex = 0
    
    init(recordId: UUID) {
        self.recordId = recordId
        _records = FetchRequest<Record>(
            sortDescriptors: [],
            predicate: NSPredicate(format: "id == %@", recordId as CVarArg))
        _babies = FetchRequest<Baby>(sortDescriptors: [])
    }
    
    private var record: Record? { records.first }
    
    private var baby: Baby? {
        guard let record = record, let babyEntity = record.baby else { return nil }
        return babyEntity
    }
    
    // 记录基本信息视图
    @ViewBuilder
    private var recordHeaderView: some View {
        if let record = record {
            HStack(spacing: 16) {
                Text(record.icon)
                    .font(.title)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.subCategory?.localized ?? "")
                        .font(.title2)
                        .fontWeight(.bold)
                        
                    Text("\(record.category.localized) · \(formatRelativeTime(record.startTimestamp))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                milestoneInfoView
            }
            .padding()
            .background(.background)
            .cornerRadius(Constants.cornerRadius)
        }
    }
    
    // 时间信息视图
    @ViewBuilder
    private var timeInfoView: some View {
        if let record = record, let baby = baby {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("start_time".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack(alignment: .center){
                            Text(formatDateTime(record.startTimestamp, dateStyle: .omitted, timeStyle: .shortened))
                                .font(.title2)
                            Spacer()
                            Text(formatDateTime(record.startTimestamp, dateStyle: .long, timeStyle: .omitted))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let end = record.endTimestamp {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("end_time".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            HStack(alignment: .center){
                                Text(formatDateTime(end, dateStyle: .omitted, timeStyle: .shortened))
                                    .font(.title2)
                                Spacer()
                                Text(formatDateTime(end, dateStyle: .long, timeStyle: .omitted))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    if let subCategory = record.subCategory, Constants.hasEndTimeCategories.contains(subCategory) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("duration_label".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if let end = record.endTimestamp {
                                Text(localizedDuration(from: record.startTimestamp, to: end))
                                    .font(.title2)
                            } else {
                                Text("ongoing".localized)
                                    .font(.title2)
                            }
                        }
                    }
                       
                    VStack(alignment: .leading, spacing: 10) {
                        Text("baby_age_at_record".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(calculateBabyAge(baby, record.startTimestamp))
                            .font(.title2)
                    }
                }
                .padding()
                .background(.background)
                .cornerRadius(Constants.cornerRadius)
            }
        }
    }

    @ViewBuilder
    private var milestoneInfoView: some View {
        if let record = record, let subCategory = record.subCategory, Constants.milestoneCategories.contains(subCategory) {
            Text("🎉🎉🎉")
                .font(.title)
        }
    }
    
    @ViewBuilder
    private var detailedInfoView: some View {
        if let record = record, let subCategory = record.subCategory, !Constants.noDetailCategories.contains(subCategory) {
            VStack(alignment: .leading, spacing: 8) {
                Text("detailed_information".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // 根据记录类型显示不同的详细信息
                if record.subCategory == "nursing" {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("breast_side".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)

                        Text(record.breastType == "BOTH" ? "both_sides".localized : record.breastType == "LEFT" ? "left_side".localized : "right_side".localized)
                            .font(.title2)
                    }
                }

                if let name = record.name, !name.isEmpty {
                    Text(name)
                        .font(.title2)
                }
                
                if record.value > 0, let unit = record.unit {
                    Text("\(record.value.smartDecimal) \(unit.localized)")
                        .font(.title2)
                }

                 if let dayOrNight = record.dayOrNight {
                   VStack(alignment: .leading, spacing: 10) {
                        Text("day_night".localized + "colon_separator".localized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(dayOrNight == "DAY" ? "daytime".localized + "☀️" : "night".localized + "🌙")
                            .font(.title2)
                    }
                }
                
                if let acceptance = record.acceptance {
                   VStack(alignment: .leading, spacing: 10) {
                        Text("acceptance_level".localized )
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(acceptance.lowercased().localized)
                            .font(.title2)
                    }
                }
                
                if let excrementStatus = record.excrementStatus {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("excrement_type".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(excrementStatus.lowercased().localized)
                           .font(.title2)
                    }
                }
            } 
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background)
            .cornerRadius(Constants.cornerRadius)
        }
    }
    
    // 备注视图
    @ViewBuilder
    private var remarkView: some View {
        if let record = record, let remark = record.remark, !remark.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("remark".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack {
                    Text(remark)
                        .font(.subheadline)
                    Spacer()
                }
            }
            .padding()
            .background(.background)
            .cornerRadius(Constants.cornerRadius)
        }
    }
    
    // 照片视图
    @ViewBuilder
    private var photosView: some View {
        let photos = record?.photosArray ?? []
        if !photos.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("photos".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 75), spacing: 12)], alignment: .leading, spacing: 12) {
                    ForEach(photos.indices, id: \.self) { index in
                        if let uiImage = UIImage(data: photos[index]) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 75, height: 75)
                                .clipped()
                                .cornerRadius(Constants.cornerRadius)
                                .onTapGesture {
                                    selectedImageIndex = index
                                    isShowingImagePreview = true
                                }
                        }
                    }
                }
            }  
            .padding()
            .background(.background)
            .cornerRadius(Constants.cornerRadius)
        }
    }
    

    
    var body: some View {
        ZStack {
            // 背景颜色
            Color(.systemGray6)
                .ignoresSafeArea()
            
            VStack {
                // 滚动视图内容
                ScrollView {
                    VStack(spacing: 0) {
                        // 记录详情卡片
                        VStack(spacing: 20) {
                            // 记录基本信息
                            recordHeaderView

                            // 详细信息
                            detailedInfoView

                             // 时间信息
                            timeInfoView
                                 
                            // 备注
                            remarkView
                                 
                            // 照片
                            photosView
                            
                            
                        }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
        }
            }
        }
        .navigationTitle("record_detail".localized)
        .navigationBarTitleDisplayMode(.inline)
        // .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .toolbar { // 右上角按钮
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 24) { // 增加间距到 24
                    // 删除按钮（红色，左边）
                    Button {
                        showingDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .tint(Color.red)
                    }
                    
                    // 编辑按钮（主题色，右边）
                    Button {
                        isNavigatingToEdit = true
                    } label: {
                        Image(systemName: "square.and.pencil") // 更换为 square.and.pencil 图标
                            .tint(Color.accentColor)
                    }
                }.padding(.horizontal, 16)
            }
        }
        // 编辑页面以 sheet 形式弹出
        .sheet(isPresented: $isNavigatingToEdit) {
            if let record = record, let baby = baby {
                RecordEditView(baby: baby, recordType: nil, existingRecordId: record.id)
            }
        }
        .background(Color(.systemGray6))
        // 删除确认弹窗
        .alert("confirm_delete_record_title".localized,  isPresented: $showingDeleteConfirmation) {
            Button("cancel".localized, role: .cancel) {}
            Button("delete".localized, role: .destructive) {
                if let record = record {
                    viewContext.delete(record)
                    do {
                        try viewContext.save()
                    } catch {
                        print("Failed to delete record: \(error)")
                    }
                    dismiss()
                }
            }
        } message: {
            Text("delete_record_warning".localized)
        }
        // 图片预览
        .fullScreenCover(isPresented: $isShowingImagePreview) {
            if let record = record {
                ImagePreview(images: record.photosArray, initialIndex: selectedImageIndex)
            }
        }
    }
}
