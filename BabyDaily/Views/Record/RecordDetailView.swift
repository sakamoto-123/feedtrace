import SwiftUI
import SwiftData

struct RecordDetailView: View {
    let record: Record
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // 删除确认提示
    @State private var showingDeleteConfirmation = false
    // 导航状态
    @State private var isNavigatingToEdit = false
    // 图片预览状态
    @State private var isShowingImagePreview = false
    @State private var selectedImageIndex = 0
    
    // 根据record.babyId查询对应的baby对象
    private var baby: Baby? {
        do {
            let fetchDescriptor = FetchDescriptor<Baby>()
            let babies = try modelContext.fetch(fetchDescriptor)
            return babies.first(where: { $0.id == record.babyId })
        } catch {
            Logger.error("Failed to fetch baby: \(error)")
            return nil
        }
    }
    
    // 记录基本信息视图
    private var recordHeaderView: some View {
        HStack(spacing: 16) {
            Text(record.icon)
                .font(.title)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(record.subCategory.localized)
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
    
    // 时间信息视图
    private var timeInfoView: some View {
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

                if Constants.hasEndTimeCategories.contains(record.subCategory) {
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
                    Text(calculateBabyAge(baby!, record.startTimestamp))
                        .font(.title2)
                }
            }
            .padding()
            .background(.background)
            .cornerRadius(Constants.cornerRadius)
        }
    }

     // 庆祝
    private var milestoneInfoView: some View {
          // 使用Group来确保总是返回一个视图
        Group {
            if Constants.milestoneCategories.contains(record.subCategory) {
                Text("🎉🎉🎉")
                    .font(.title)
            } else {
                // 对于不需要详细信息的分类，返回一个空视图
                EmptyView()
            }
        }
    }
    
    // 详细信息视图
    private var detailedInfoView: some View {
        // 使用Group来确保总是返回一个视图
        Group {
            if !Constants.noDetailCategories.contains(record.subCategory) {
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

                            Text(record.breastType ?? "both_sides".localized)
                                .font(.subheadline)
                        }
                    }

                    if let name = record.name, !name.isEmpty {
                        Text(name)
                            .font(.subheadline)
                    }
                    
                    if let value = record.value, let unit = record.unit {
                        Text("\(value.smartDecimal) · \(unit.localized)")
                            .font(.subheadline)
                    }

                     if let dayOrNight = record.dayOrNight {
                        HStack {
                            Text("day_night".localized + "colon_separator".localized)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(dayOrNight == "DAY" ? "daytime".localized + "☀️" : "night".localized + "🌙")
                                .font(.subheadline)
                        }
                    }
                    
                    if let acceptance = record.acceptance {
                        HStack {
                            Text("acceptance_level".localized )
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(acceptance == "LIKE" ? "like".localized : acceptance == "NEUTRAL" ? "neutral".localized : acceptance == "DISLIKE" ? "dislike".localized : "allergy".localized)
                                .font(.subheadline)
                        }
                    }
                    
                    if let excrementStatus = record.excrementStatus {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("excrement_type".localized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(excrementStatus == "URINE" ? "urine".localized : excrementStatus == "STOOL" ? "stool".localized : "mixed".localized)
                                .font(.subheadline)
                        }
                    }
                } 
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.background)
                .cornerRadius(Constants.cornerRadius)
            } else {
                // 对于不需要详细信息的分类，返回一个空视图
                EmptyView()
            }
        }
    }
    
    // 备注视图
    private var remarkView: some View {
        Group {
            if let remark = record.remark, !remark.isEmpty {
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
    }
    
    // 照片视图
    private var photosView: some View {
        Group {
            if let photos = record.photos, !photos.isEmpty {

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
            RecordEditView(baby: baby!, recordType: nil, existingRecord: record)
        }
        .background(Color(.systemGray6))
        // 删除确认弹窗
        .alert("confirm_delete_record_title".localized,  isPresented: $showingDeleteConfirmation) {
            Button("cancel".localized, role: .cancel) {}
            Button("delete".localized, role: .destructive) {
                // 删除记录
                modelContext.delete(record)
                dismiss()
            }
        } message: {
            Text("delete_record_warning".localized)
        }
        // 图片预览
        .fullScreenCover(isPresented: $isShowingImagePreview) {
            if let photos = record.photos {
                ImagePreview(images: photos, initialIndex: selectedImageIndex)
            }
        }
    }
}
