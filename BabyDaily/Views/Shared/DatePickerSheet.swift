import SwiftUI

// MARK: - 可复用日期选择Sheet组件
struct DatePickerSheet: View {
    let title: String
    @Binding var date: Date
    @Binding var isPresented: Bool
    
    // 可选的日期绑定，用于处理结束时间等可选日期情况
    @Binding var optionalDate: Date?
    let isOptional: Bool
    
    // 可选的日期显示组件，默认为日期和时间
    let displayedComponents: DatePickerComponents
    
    // 初始化方法 - 用于非可选日期
    init(title: String, date: Binding<Date>, isPresented: Binding<Bool>, displayedComponents: DatePickerComponents = [.date, .hourAndMinute]) {
        self.title = title
        self._date = date
        self._optionalDate = .constant(nil)
        self._isPresented = isPresented
        self.isOptional = false
        self.displayedComponents = displayedComponents
    }
    
    // 初始化方法 - 用于可选日期
    init(title: String, optionalDate: Binding<Date?>, isPresented: Binding<Bool>, displayedComponents: DatePickerComponents = [.date, .hourAndMinute]) {
        self.title = title
        self._date = Binding(get: { optionalDate.wrappedValue ?? Date() }, 
                            set: { optionalDate.wrappedValue = $0 })
        self._optionalDate = optionalDate
        self._isPresented = isPresented
        self.isOptional = true
        self.displayedComponents = displayedComponents
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 20) {
                Button("取消") {
                    isPresented = false
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                
                Text(title)
                    .font(.headline)
                    .padding(.top, 20)
                
                Button("确定") {
                    // 如果是可选日期，确保更新可选日期的值
                    if isOptional {
                        optionalDate = date
                    }
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            
            DatePicker(
                "",
                selection: $date,
                displayedComponents: displayedComponents
            )
            .datePickerStyle(.graphical)
            .padding(.horizontal, 20)
            
       
        }
    }
}
