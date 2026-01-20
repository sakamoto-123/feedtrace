import SwiftUI

// MARK: - 日期选择器弹窗
struct DatePickerOverlay: View {
    @Binding var date: Date
    var onDismiss: () -> Void
    @EnvironmentObject var appSettings: AppSettings
    
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
                    .foregroundColor(appSettings.currentThemeColor)
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
            .background(.background)
            .cornerRadius(16)
            .padding(.horizontal, 24)
            .shadow(radius: 20)
        }
    }
}