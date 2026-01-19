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
    @StateObject private var userSettingManager = UserSettingManager.shared
    
    // 新增：当前选中的宝宝状态
    @State private var selectedBaby: Baby?
    
    var body: some View {
        if babies.isEmpty {
            // 如果没有宝宝数据，显示宝宝信息创建页面
            BabyCreationView(isEditing: false, existingBaby: nil, isFirstCreation: true)
                .onAppear {
                    // 初始化UserSettingManager
                    userSettingManager.setup(modelContext: modelContext)
                }
        } else {
            // 显示首页（底部Tab栏）
            if let firstBaby = babies.first {
                // 使用firstBaby作为默认值，显式指定Binding类型
            let babyBinding: Binding<Baby> = Binding(get: {
                return selectedBaby ?? firstBaby
            }, set: {
                let baby = $0
                selectedBaby = baby
                // 保存选中的宝宝ID到UserSetting
                Task {
                    await userSettingManager.setSelectedBabyId(baby.id)
                }
            })
                
                MainTabView(baby: babyBinding)
                    .onAppear {
                        // 初始化UserSettingManager
                        userSettingManager.setup(modelContext: modelContext)
                        // 加载选中的宝宝
                        loadSelectedBaby()
                    }
                    .onChange(of: babies) { 
                        // 当宝宝列表变化时，确保selectedBaby仍然有效
                        if !babies.contains(where: { $0.id == selectedBaby?.id }) {
                            selectedBaby = babies.first
                            // 保存默认宝宝ID到UserSetting
                            Task {
                                if let firstBaby = babies.first {
                                    await userSettingManager.setSelectedBabyId(firstBaby.id)
                                }
                            }
                        }
                    }
                    .onChange(of: userSettingManager.userSetting?.selectedBabyId) {
                        // 当UserSetting中的selectedBabyId变化时，更新selectedBaby
                        loadSelectedBaby()
                    }
            }
        }
    }
    
    // 从UserSetting加载选中的宝宝
    private func loadSelectedBaby() {
        if let selectedBabyId = userSettingManager.getSelectedBabyId() {
            if let baby = babies.first(where: { $0.id == selectedBabyId }) {
                selectedBaby = baby
            } else if !babies.isEmpty {
                // 如果保存的宝宝ID不存在，使用第一个宝宝
                selectedBaby = babies.first
                // 更新UserSetting中的selectedBabyId
                Task {
                    if let firstBaby = babies.first {
                        await userSettingManager.setSelectedBabyId(firstBaby.id)
                    }
                }
            }
        } else if !babies.isEmpty {
            // 如果UserSetting中没有selectedBabyId，使用第一个宝宝
            selectedBaby = babies.first
            // 更新UserSetting中的selectedBabyId
            Task {
                if let firstBaby = babies.first {
                    await userSettingManager.setSelectedBabyId(firstBaby.id)
                }
            }
        }
    }
}
