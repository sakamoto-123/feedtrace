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
    // 优化@Query：添加排序和限制，减少初始加载的数据量
    @Query(sort: [SortDescriptor(\Baby.createdAt)]) private var babies: [Baby]
    @StateObject private var userSettingManager = UserSettingManager.shared
    
    // 新增：当前选中的宝宝状态
    @State private var selectedBaby: Baby?
    // 新增：标记是否已经初始化，避免重复调用setup
    @State private var hasInitialized = false
    
    var body: some View {
        if babies.isEmpty {
            // 如果没有宝宝数据，显示宝宝信息创建页面
            BabyCreationView(isEditing: false, existingBaby: nil, isFirstCreation: true)
                .onAppear {
                    // 初始化UserSettingManager
                    if !hasInitialized {
                        userSettingManager.setup(modelContext: modelContext)
                        hasInitialized = true
                    }
                }
        } else {
            // 显示首页（底部Tab栏）
            MainTabView(baby: babyBinding)
                .onAppear {
                    // 初始化UserSettingManager，避免重复调用
                    if !hasInitialized {
                        userSettingManager.setup(modelContext: modelContext)
                        hasInitialized = true
                        // 直接从UserDefaults加载选中的宝宝，减少延迟
                        loadSelectedBaby()
                    }
                }
                .onChange(of: babies) {
                    // 当宝宝列表变化时，确保selectedBaby仍然有效
                    if let currentSelectedBaby = selectedBaby,
                       !$0.contains(where: { $0.id == currentSelectedBaby.id }) {
                        // 优先从本地缓存获取宝宝
                        if let cachedBabyId = userSettingManager.getSelectedBabyIdFromDefaults(),
                           let cachedBaby = $0.first(where: { $0.id == cachedBabyId }) {
                            selectedBaby = cachedBaby
                        } else {
                            // 只有在没有本地缓存时才使用firstBaby
                            selectedBaby = $0.first
                        }
                        // 更新本地缓存
                        if let selectedBaby = selectedBaby {
                            userSettingManager.setSelectedBabyId(selectedBaby.id)
                        }
                    }
                }
        }
    }
    
    // 优化：将babyBinding提取为计算属性，避免在body中重复创建
    private var babyBinding: Binding<Baby> {
        Binding(get: {
            if let selectedBaby = selectedBaby {
                return selectedBaby
            } else {
                if let cachedBabyId = userSettingManager.getSelectedBabyIdFromDefaults(),
                   let cachedBaby = babies.first(where: { $0.id == cachedBabyId }) {
                    return cachedBaby
                }
                // 只有在没有本地缓存时才使用firstBaby
                return babies.first!
            }
        }, set: {
            let baby = $0
            selectedBaby = baby
            // 保存选中的宝宝ID到本地缓存
            userSettingManager.setSelectedBabyId(baby.id)
        })
    }
    
    // 从本地缓存加载选中的宝宝
    private func loadSelectedBaby() {
        // 只有在babies非空时才执行，避免空数组操作
        guard !babies.isEmpty else { return }
        
        // 如果已经有选中的宝宝，直接返回，避免重复加载
        if selectedBaby != nil {
            return
        }
        
        // 从本地缓存获取选中的宝宝ID
        if let cachedBabyId = userSettingManager.getSelectedBabyIdFromDefaults() {
            if let baby = babies.first(where: { $0.id == cachedBabyId }) {
                selectedBaby = baby
                return
            }
        }
        
        // 如果本地缓存中没有对应的宝宝，使用第一个宝宝
        selectedBaby = babies.first
        // 更新本地缓存
        if let selectedBaby = selectedBaby {
            userSettingManager.setSelectedBabyId(selectedBaby.id)
        }
    }
}
