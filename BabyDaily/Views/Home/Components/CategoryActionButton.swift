import SwiftUI

// 快速操作按钮组件
struct CategoryActionButton: View {
    let icon: String
    let name: String
    let color: Color
    let category: String
    let baby: Baby
    let size: CGFloat
    /// 为 true 时以 sheet 形式打开 RecordEdit，为 false 时使用 NavigationLink push
    let presentAsSheet: Bool

    init(icon: String, name: String, color: Color, category: String, baby: Baby, size: CGFloat = 60, presentAsSheet: Bool = false) {
        self.icon = icon
        self.name = name
        self.color = color
        self.category = category
        self.baby = baby
        self.size = size
        self.presentAsSheet = presentAsSheet
    }

    private var recordType: (category: String, subCategory: String, icon: String) {
        (category: category, subCategory: name, icon: icon)
    }

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            if presentAsSheet {
                CategoryActionButtonSheetContent(
                    icon: icon,
                    name: name,
                    color: color,
                    size: size,
                    baby: baby,
                    recordType: recordType
                )
            } else {
                NavigationLink(destination: RecordEditView(baby: baby, recordType: recordType)) {
                    buttonContent
                }
                .buttonStyle(PlainButtonStyle())
            }

            Text(name.localized)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var buttonContent: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(color, lineWidth: 1.5)
                )

            Text(icon)
                .font(.system(size: 20))
        }
    }
}

// Sheet 形式：点击后弹出 RecordEditView
private struct CategoryActionButtonSheetContent: View {
    let icon: String
    let name: String
    let color: Color
    let size: CGFloat
    let baby: Baby
    let recordType: (category: String, subCategory: String, icon: String)

    @State private var isSheetPresented = false

    var body: some View {
        Button {
            isSheetPresented = true
        } label: {
            ZStack {
                Circle()
                    .fill(color.opacity(0.3))
                    .frame(width: size, height: size)
                    .overlay(
                        Circle()
                            .stroke(color, lineWidth: 1.5)
                    )

                Text(icon)
                    .font(.system(size: 20))
            }
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $isSheetPresented) {
            RecordEditView(baby: baby, recordType: recordType)
        }
    }
}
