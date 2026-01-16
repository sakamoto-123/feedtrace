import SwiftUI

struct MainTabView: View {
    let selectedBaby: Baby
    
    var body: some View {
        TabView {
            // 首页
            HomeView(baby: selectedBaby)
                .tabItem {
                    Label("home".localized, systemImage: "house.fill")
                }
            
            // 记录
            RecordListView(baby: selectedBaby)
                .tabItem {
                    Label("records".localized, systemImage: "list.bullet")
                }
            
            // 统计
            StatisticsView(baby: selectedBaby)
                .tabItem {
                    Label("statistics".localized, systemImage: "chart.bar.fill")
                }
            
            // 设置
            SettingsView(baby: selectedBaby)
                .tabItem {
                    Label("settings".localized, systemImage: "gearshape.fill")
                }
        }
    }
}