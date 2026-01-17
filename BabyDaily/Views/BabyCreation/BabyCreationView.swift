import SwiftUI
import SwiftData

struct BabyCreationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var name: String = ""
    @State private var photos: [Image] = []
    @State private var photoDatas: [Data] = []
    @State private var birthday: Date = Date()
    @State private var gender: String = "male"
    @State private var height: String = ""
    @State private var weight: String = ""
    
    @State private var showingImagePicker = false
    @State private var showingDatePicker = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#f2f2f2")
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
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)
                    .padding(.top, 40)
                    .padding(.bottom, 32)
                }
                
                // 日期选择器弹窗
                if showingDatePicker {
                    DatePickerOverlay(date: $birthday, onDismiss: { showingDatePicker = false })
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 移除了取消按钮
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(
                    images: $photos,
                    imageDatas: $photoDatas,
                    allowsMultipleSelection: false,
                    allowsEditing: true
                )
            }
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
                        .fill(Color(.systemGray6))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "camera.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                        .foregroundColor(themeManager.currentThemeColor)
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
                  
            // 身高体重一行
            bodyDataRow

            // 主题颜色选择
            themeColorPicker
        }
        .padding(36)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .frame(maxWidth: 400)
    }
    
    // 宝宝名称字段
    private var nameField: some View {
        VStack(alignment: .center, spacing: 8) {
            TextField("", text: $name, prompt: Text("enter_baby_name".localized).foregroundColor(.gray))

                .font(.system(size: 16))
                .multilineTextAlignment(.center)
                .padding(.vertical, 8)
                .frame(width: 200)
                .overlay(
                    Divider()
                        .background(themeManager.currentThemeColor)
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
                   .background(themeManager.currentThemeColor)
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
                        .background(gender == "male" ? themeManager.currentThemeColor : Color(.systemGray5))
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
                        .background(gender == "female" ? themeManager.currentThemeColor : Color(.systemGray5))
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
                        .background(gender == "prefer_not_to_say" ? themeManager.currentThemeColor : Color(.systemGray5))
                        .cornerRadius(20)
                }
                .fixedSize(horizontal: true, vertical: false)
                .animation(.easeInOut, value: gender)
            }
        }
    }
    
    // 主题颜色选择器
    private var themeColorPicker: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("theme_color".localized)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                ForEach(ThemeColor.allCases) { themeColor in
                    Button(action: {
                        themeManager.switchThemeColor(to: themeColor)
                    }) {
                        ZStack {
                            Circle()
                                .fill(themeColor.color)
                                .frame(width: 40, height: 40)
                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                            
                            if themeManager.selectedThemeColor == themeColor {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
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
                        
                        Text("cm".localized)
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                    .overlay(
                        Divider()
                            .background(themeManager.currentThemeColor)
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
                        
                        Text("kg".localized)
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                    .overlay(
                        Divider()
                            .background(themeManager.currentThemeColor)
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
            Text("add_baby".localized)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 48)
                .padding(.vertical, 14)
                .background(themeManager.currentThemeColor)
                .cornerRadius(24)
        }
        .disabled(name.isEmpty)
        .opacity(name.isEmpty ? 0.6 : 1.0)
        .animation(.easeInOut, value: name.isEmpty)
    }
    
    private func saveBaby() {
        let heightValue = Double(height) ?? 50
        let weightValue = Double(weight) ?? 3.5
        
        let newBaby = Baby(
            name: name,
            photo: photoDatas.first,
            birthday: birthday,
            gender: gender,
            weight: weightValue,
            height: heightValue,
            headCircumference: 34 // 默认值
        )
        
        modelContext.insert(newBaby)
        dismiss()
    }
}

// 颜色扩展，支持十六进制颜色
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let (a, r, g, b): (Int, Int, Int, Int)
        if hex.count == 8 {
            a = Int(int >> 24) & 0xff
            r = Int(int >> 16) & 0xff
            g = Int(int >> 8) & 0xff
            b = Int(int) & 0xff
        } else if hex.count == 6 {
            a = 255
            r = Int(int >> 16) & 0xff
            g = Int(int >> 8) & 0xff
            b = Int(int) & 0xff
        } else {
            a = 255
            r = 0
            g = 0
            b = 0
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// 日期选择器弹窗
struct DatePickerOverlay: View {
    @Binding var date: Date
    var onDismiss: () -> Void
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            // 日期选择器卡片
            VStack {
                HStack {
                    Spacer()
                    
                    Button("complete".localized) {
                    onDismiss()
                }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.currentThemeColor)
                }
                .padding(16)
                
                DatePicker(
                    "",
                    selection: $date,
                    in: ...Date(),
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .padding()
            }
            .background(Color.white)
            .cornerRadius(16)
            .padding(.horizontal, 24)
            .shadow(radius: 20)
        }
    }
}
