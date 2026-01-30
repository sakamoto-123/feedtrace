import SwiftUI
import CoreData

// 宝宝信息头部组件
struct BabyInfoHeader: View {
    let baby: Baby
    let latestGrowthData: GrowthData
    @Binding var showingBabySwitcher: Bool
    @Environment(\.colorScheme) private var colorScheme
    @FetchRequest private var allBabies: FetchedResults<Baby>
    
    // 判断是否有多个宝宝
    private var hasMultipleBabies: Bool {
        allBabies.count > 1
    }
    
    init(baby: Baby, latestGrowthData: GrowthData, showingBabySwitcher: Binding<Bool>) {
        self.baby = baby
        self.latestGrowthData = latestGrowthData
        self._showingBabySwitcher = showingBabySwitcher
        _allBabies = FetchRequest<Baby>(
            sortDescriptors: [NSSortDescriptor(keyPath: \Baby.createdAt, ascending: true)])
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // 宝宝头像和名称区域
            HStack(alignment: .center, spacing: 12) {
                // 宝宝头像
                if let photoData = baby.photo, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height:44)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .foregroundColor(.gray)
                }
                
                // 宝宝名称和年龄
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(baby.name)
                            .font(.system(size: 15))
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Text(calculateBabyAge(baby))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 6){
                        Text(String(format: "%.1f", latestGrowthData.weight) + "kg".localized)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)

                        Text((latestGrowthData.height > 0 ? String(format: "%.0f", latestGrowthData.height) : "---") + "cm".localized )
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }

                // 只在有多个宝宝时显示切换按钮
                if hasMultipleBabies {
                    Button(action: {
                        showingBabySwitcher = true
                    }) {
                        Image(systemName: "arrow.left.arrow.right.circle")
                            .font(.system(size: 16))
                            .foregroundColor(.accentColor)
                            .padding(.leading, -4)
                    }
                }
                
                Spacer()
            }
            .padding(.leading, 20)
            .padding(.bottom, 12)
        }
        .padding(.top, 8)
        .background(Color.themeCardBackground(for: colorScheme))
    }
}
