//
//  ContentView.swift
//  BabyDaily
//
//  Created by 常明 on 2026/1/15.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var babies: [Baby]
    
    var body: some View {
        if babies.isEmpty {
            // 如果没有宝宝数据，显示宝宝信息创建页面
            BabyCreationView()
        } else {
            // 否则显示首页（底部Tab栏）
            MainTabView(selectedBaby: babies.first!)
        }
    }
}
