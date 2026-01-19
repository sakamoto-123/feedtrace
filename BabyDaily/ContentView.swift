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
    
    // 新增：当前选中的宝宝状态
    @State private var selectedBaby: Baby?
    
    var body: some View {
        if babies.isEmpty {
            // 如果没有宝宝数据，显示宝宝信息创建页面
            BabyCreationView(isEditing: false)
        } else {
            // 显示首页（底部Tab栏）
            if let firstBaby = babies.first {
                // 使用firstBaby作为默认值
                let babyBinding = Binding(get: {
                    return selectedBaby ?? firstBaby
                }, set: {
                    selectedBaby = $0
                })
                
                MainTabView(baby: babyBinding)
                    .onChange(of: babies) { 
                        // 当宝宝列表变化时，确保selectedBaby仍然有效
                        if !babies.contains(where: { $0.id == selectedBaby?.id }) {
                            selectedBaby = babies.first
                        }
                    }
            }
        }
    }
}
