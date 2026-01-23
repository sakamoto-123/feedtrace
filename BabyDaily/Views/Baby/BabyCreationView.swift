import SwiftUI
import SwiftData

struct BabyCreationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var appSettings: AppSettings
    
    // 新增：编辑模式标识和现有宝宝数据
    let isEditing: Bool
    let existingBaby: Baby?
    let isFirstCreation: Bool
    
    @State private var name: String = ""
    @State private var photos: [Image] = []
    @State private var photoDatas: [Data] = []
    @State private var birthday: Date = Date()
    @State private var gender: String = "male"
    @State private var height: String = ""
    @State private var weight: String = ""
    
    @State private var showingImagePicker = false
    @State private var showingDatePicker = false
    @State private var showingUnitSettingSheet = false
    @State private var showingMembershipView = false
    @StateObject private var unitManager = UnitManager.shared
    @StateObject private var membershipManager = MembershipManager.shared
    
    // 初始化：如果是编辑模式，加载现有宝宝数据
    init(isEditing: Bool = false, existingBaby: Baby? = nil, isFirstCreation: Bool = true) {
        self.isEditing = isEditing
        self.existingBaby = existingBaby
        self.isFirstCreation = isFirstCreation
        
        if let baby = existingBaby {
            _name = State(initialValue: baby.name)
            _birthday = State(initialValue: baby.birthday)
            _gender = State(initialValue: baby.gender)
            _height = State(initialValue: String(baby.height))
            _weight = State(initialValue: String(baby.weight))
            
            // 加载照片数据
            if let photoData = baby.photo {
                _photoDatas = State(initialValue: [photoData])
                if let uiImage = UIImage(data: photoData) {
                    _photos = State(initialValue: [Image(uiImage: uiImage)])
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBackground(for: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 40) {
                        // 表单卡片
                        formCard
                        
                        // 保存按钮
                        saveButton
                        
                        // 辅助文字
                        Text("partner_device_tip".localized)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 50)
                    .padding(.bottom, 32)
                }
                
                // 日期选择器弹窗
                if showingDatePicker {
                    DatePickerOverlay(date: $birthday, onDismiss: { showingDatePicker = false })
                }
            }
            .navigationTitle(isEditing ? "edit_baby_info".localized : "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(
                    images: $photos,
                    imageDatas: $photoDatas,
                    allowsMultipleSelection: false,
                    allowsEditing: true
                )
            }
            .sheet(isPresented: $showingUnitSettingSheet) {
                UnitSettingView()
            }
            .sheet(isPresented: $showingMembershipView) {
                MembershipPrivilegesView()
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
    }
    
    // 宝宝照片区域
    private var babyPhotoSection: some View {
        Button(action: {
            showingImagePicker = true
        }) {
            if let photo = photos.first {
                photo
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else {
                ZStack {
                    Circle()
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "camera.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                        .foregroundColor(appSettings.currentThemeColor)
                }
            }
        }
        .animation(.easeInOut, value: photos)
    }
    
    // 表单卡片
    private var formCard: some View {
        VStack(spacing: 24) {
            
            // 宝宝照片区域
            babyPhotoSection
            
            // 宝宝名称
            nameField
            
            // 出生日期
            birthdayField
            
            // 性别选择
            genderField
                  
            // 身高体重一行 - 仅在非编辑模式显示
            bodyDataRow

            // 主题颜色选择
            if isFirstCreation && !isEditing {
                themeColorPicker
            }
        }
        .padding(36)
        .frame(minWidth: 360, maxWidth: 600)
        .background(Color.themeCardBackground(for: colorScheme))
        .cornerRadius(Constants.cornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // 宝宝名称字段
    private var nameField: some View {
        VStack(alignment: .center, spacing: 8) {
            TextField("", text: $name, prompt: Text("enter_baby_name".localized).foregroundColor(.gray))
                .font(.system(size: 16))
                .multilineTextAlignment(.center)
                .padding(.vertical, 8)
                .frame(width: 200)
                .submitLabel(.done)
                .autocorrectionDisabled()
                .overlay(
                    Divider()
                        .background(appSettings.currentThemeColor)
                        .offset(y: 16)
                )
        }
    }
    
    // 出生日期字段
    private var birthdayField: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("birthday".localized)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(alignment: .center) {
                Button(action: {
                    showingDatePicker = true
                }) {
                    Text(birthday, style: .date)
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                }
                
                Image(systemName: "calendar")
                    .foregroundColor(.secondary)
            }

            .padding(.vertical, 8)
            .frame(width: 200)
           .overlay(
               Divider()
                   .background(appSettings.currentThemeColor)
                   .offset(y: 16)
           )
        }
    }
    
    // 性别选择字段
    private var genderField: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("gender".localized)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                Button(action: {
                    gender = "male"
                }) {
                    Text("male".localized)
                        .font(.system(size: 15))
                        .foregroundColor(gender == "male" ? .white : .primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(gender == "male" ? appSettings.currentThemeColor : Color(.systemGray5))
                        .cornerRadius(20)
                }
                .fixedSize(horizontal: true, vertical: false)
                .animation(.easeInOut, value: gender)
                
                Button(action: {
                    gender = "female"
                }) {
                    Text("female".localized)
                        .font(.system(size: 15))
                        .foregroundColor(gender == "female" ? .white : .primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(gender == "female" ? appSettings.currentThemeColor : Color(.systemGray5))
                        .cornerRadius(20)
                }
                .fixedSize(horizontal: true, vertical: false)
                .animation(.easeInOut, value: gender)
                
                Button(action: {
                    gender = "prefer_not_to_say"
                }) {
                    Text("prefer_not_to_say".localized)
                        .font(.system(size: 15))
                        .foregroundColor(gender == "prefer_not_to_say" ? .white : .primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(gender == "prefer_not_to_say" ? appSettings.currentThemeColor : Color(.systemGray5))
                        .cornerRadius(20)
                }
                .fixedSize(horizontal: true, vertical: false)
                .animation(.easeInOut, value: gender)
            }
        }
    }
    
    // 前6个颜色是免费的（索引0-5）
    private let freeColorCount = 6
    
    // 判断颜色是否需要会员
    private func isColorPremium(_ color: ThemeColor) -> Bool {
        guard let index = ThemeColor.allCases.firstIndex(of: color) else {
            return false
        }
        return index >= freeColorCount
    }
    
    // 判断颜色是否可用（免费或会员已购买）
    private func isColorAvailable(_ color: ThemeColor) -> Bool {
        if !isColorPremium(color) {
            return true // 免费颜色总是可用
        }
        return membershipManager.isPremiumMember // 会员颜色需要会员身份
    }
    
    // 主题颜色选择器
    private var themeColorPicker: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("theme_color".localized)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            ScrollView(.horizontal, showsIndicators: false) {
               HStack(spacing: 16) {
                    ForEach(ThemeColor.allCases) { themeColor in
                        let isPremium = isColorPremium(themeColor)
                        let isAvailable = isColorAvailable(themeColor)
                        
                        Button(action: {
                            if isAvailable {
                                appSettings.setThemeColor(themeColor)
                            } else {
                                // 非会员点击会员颜色，弹出会员页面
                                showingMembershipView = true
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(themeColor.color)
                                    .frame(width: 40, height: 40)
                                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                                
                                if appSettings.themeColor == themeColor {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                } else if isPremium && !isAvailable {
                                    // 非会员的会员颜色显示锁图标
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // 身高体重一行
    private var bodyDataRow: some View {
        VStack(spacing: 8) {
            HStack(spacing: 32) {
                // 身高
                VStack(alignment: .center, spacing: 8) {
                    Text("height".localized)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    HStack {
                        TextField("", text: $height)
                            .font(.system(size: 16))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .submitLabel(.done)
                            .autocorrectionDisabled()
                        
                        Button(action: {
                            showingUnitSettingSheet = true
                        }) {
                            Text(unitManager.lengthUnit.rawValue)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(appSettings.currentThemeColor)
                        }
                    }
                    .padding(.vertical, 8)
                    .overlay(
                        Divider()
                            .background(appSettings.currentThemeColor)
                            .offset(y: 16)
                    )
                }
                .frame(maxWidth: .infinity)
                
                // 体重
                VStack(alignment: .center, spacing: 8) {
                    Text("weight".localized)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    HStack {
                        TextField("", text: $weight)
                            .font(.system(size: 16))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .submitLabel(.done)
                            .autocorrectionDisabled()
                        
                        Button(action: {
                            showingUnitSettingSheet = true
                        }) {
                            Text(unitManager.weightUnit.rawValue)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(appSettings.currentThemeColor)
                        }
                    }
                    .padding(.vertical, 8)
                    .overlay(
                        Divider()
                            .background(appSettings.currentThemeColor)
                            .offset(y: 16)
                    )
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    // 保存按钮
    private var saveButton: some View {
        Button(action: {
            saveBaby()
        }) {
            Text(!isEditing ? "add_baby".localized : "save".localized)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 48)
                .padding(.vertical, 14)
                .background(appSettings.currentThemeColor)
                .cornerRadius(24)
        }
        .disabled(name.isEmpty)
        .opacity(name.isEmpty ? 0.6 : 1.0)
        .animation(.easeInOut, value: name.isEmpty)
    }
    
    private func saveBaby() {
        let heightValue = Double(height) ?? 50
        let weightValue = Double(weight) ?? 3.5
        
        if isEditing, let baby = existingBaby {
            // 保存旧值用于比较
            let oldHeight = baby.height
            let oldWeight = baby.weight
            
            // 更新现有宝宝数据
            baby.name = name
            baby.photo = photoDatas.first
            baby.birthday = birthday
            baby.gender = gender
            baby.weight = weightValue
            baby.height = heightValue
            
            // 如果身高改变了，创建新的身高记录
            if abs(oldHeight - heightValue) > 0.01 { // 使用小的容差值来比较浮点数
                let heightRecord = Record(
                    babyId: baby.id,
                    icon: "📏",
                    category: "growth_category",
                    subCategory: "height",
                    startTimestamp: Date(),
                    value: heightValue,
                    unit: unitManager.lengthUnit.rawValue
                )
                modelContext.insert(heightRecord)
            }
            
            // 如果体重改变了，创建新的体重记录
            if abs(oldWeight - weightValue) > 0.01 { // 使用小的容差值来比较浮点数
                let weightRecord = Record(
                    babyId: baby.id,
                    icon: "⚖️",
                    category: "growth_category",
                    subCategory: "weight",
                    startTimestamp: Date(),
                    value: weightValue,
                    unit: unitManager.weightUnit.rawValue
                )
                modelContext.insert(weightRecord)
            }
        } else {
            // 创建新宝宝
            let newBaby = Baby(
                name: name,
                photo: photoDatas.first,
                birthday: birthday,
                gender: gender,
                weight: weightValue,
                height: heightValue,
                headCircumference: 0.0
            )
            
            modelContext.insert(newBaby)
            
            // 保存宝宝以便获取 ID
            try? modelContext.save()
            
            // 创建身高记录（使用实际输入的值或默认值）
            let heightRecord = Record(
                babyId: newBaby.id,
                icon: "📏",
                category: "growth_category",
                subCategory: "height",
                startTimestamp: Date(),
                value: heightValue,
                unit: unitManager.lengthUnit.rawValue
            )
            modelContext.insert(heightRecord)
            
            // 创建体重记录（使用实际输入的值或默认值）
            let weightRecord = Record(
                babyId: newBaby.id,
                icon: "⚖️",
                category: "growth_category",
                subCategory: "weight",
                startTimestamp: Date(),
                value: weightValue,
                unit: unitManager.weightUnit.rawValue
            )
            modelContext.insert(weightRecord)
        }
        
        // 保存更改到存储中
        try? modelContext.save()
        
        dismiss()
    }
}
