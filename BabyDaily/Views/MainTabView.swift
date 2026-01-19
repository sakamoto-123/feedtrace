import SwiftUI

struct MainTabView: View {
    @Binding var baby: Baby
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        TabView {
            // 首页
            HomeView(baby: $baby)
                .tabItem {
                    Label("home".localized, systemImage: "house.fill")
                }
            
            // 记录
            RecordListView(baby: baby)
                .tabItem {
                    Label("records".localized, systemImage: "list.bullet")
                }
            
            // 统计
            StatisticsView(baby: baby)
                .tabItem {
                    Label("statistics".localized, systemImage: "chart.bar.fill")
                }
            
            // 设置
            SettingsView(baby: baby)
                .tabItem {
                    Label("settings".localized, systemImage: "gearshape.fill")
                }
        }
    }
}
