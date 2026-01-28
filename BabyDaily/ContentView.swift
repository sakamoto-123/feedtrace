//
//  ContentView.swift
//  BabyDaily
//
//  Created by 常明 on 2026/1/15.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    // 优化@FetchRequest：添加排序和限制，减少初始加载的数据量
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Baby.createdAt, ascending: true)],
        animation: .default)
    private var babies: FetchedResults<Baby>
    
    @StateObject private var userSettingManager = UserSettingManager.shared
    
    // 只存储选中的宝宝ID，不存储实例，避免持有失效的模型引用
    @State private var selectedBabyId: UUID?
    // 新增：标记是否已经初始化，避免重复调用setup
    @State private var hasInitialized = false
    
    // 计算属性：从当前有效的 babies 数组中获取选中的宝宝实例
    private var selectedBaby: Baby? {
        guard let selectedBabyId = selectedBabyId else {
            // 如果没有选中的ID，尝试从缓存加载
            if let cachedId = userSettingManager.getSelectedBabyIdFromDefaults() {
                return babies.first(where: { $0.id == cachedId })
            }
            return babies.first
        }
        return babies.first(where: { $0.id == selectedBabyId })
    }
    
    var body: some View {
        if babies.isEmpty {
            // 如果没有宝宝数据，显示宝宝信息创建页面
            BabyCreationView(isEditing: false, existingBaby: nil, isFirstCreation: true)
                .onAppear {
                    // 初始化UserSettingManager
                    if !hasInitialized {
                        userSettingManager.setup(modelContext: viewContext)
                        hasInitialized = true
                    }
                }
        } else {
            // 显示首页（底部Tab栏）
            MainTabView(baby: babyBinding)
                .onAppear {
                    // 初始化UserSettingManager，避免重复调用
                    if !hasInitialized {
                        userSettingManager.setup(modelContext: viewContext)
                        hasInitialized = true
                        // 直接从UserDefaults加载选中的宝宝，减少延迟
                        loadSelectedBaby()
                    }
                }
                .onChange(of: Array(babies)) { _, newBabies in
                    // 当宝宝列表变化时（包括容器切换），确保选中的宝宝ID仍然有效
                    // 如果当前选中的ID对应的宝宝不在新数组中，重新选择
                    if let currentId = selectedBabyId {
                        if !newBabies.contains(where: { $0.id == currentId }) {
                            // 当前选中的宝宝不在新数组中，重新选择
                            selectBabyFromList(Array(newBabies))
                        }
                    } else {
                        // 如果没有选中的ID，尝试加载
                        selectBabyFromList(Array(newBabies))
                    }
                }
        }
    }
    
    // 优化：将babyBinding提取为计算属性，避免在body中重复创建
    // 使用计算属性 selectedBaby 来获取当前有效的实例
    private var babyBinding: Binding<Baby> {
        Binding(get: {
            // selectedBaby 是计算属性，总是从当前有效的 babies 数组中获取
            guard let baby = selectedBaby else {
                // 如果计算属性返回 nil，说明 babies 为空，这不应该发生
                // 但为了安全，返回第一个（如果存在）
                return babies.first ?? Baby(context: viewContext)
            }
            return baby
        }, set: {
            // 当设置新的宝宝时，只保存ID
            selectedBabyId = $0.id
            userSettingManager.setSelectedBabyId($0.id)
        })
    }
    
    // 从宝宝列表中选择一个宝宝（优先使用缓存的ID，否则使用第一个）
    private func selectBabyFromList(_ babies: [Baby]) {
        guard !babies.isEmpty else { return }
        
        // 优先从缓存获取
        if let cachedId = userSettingManager.getSelectedBabyIdFromDefaults(),
           babies.contains(where: { $0.id == cachedId }) {
            selectedBabyId = cachedId
        } else {
            // 使用第一个宝宝
            selectedBabyId = babies.first?.id
            if let id = selectedBabyId {
                userSettingManager.setSelectedBabyId(id)
            }
        }
    }
    
    // 从本地缓存加载选中的宝宝ID
    private func loadSelectedBaby() {
        guard !babies.isEmpty else { return }
        selectBabyFromList(Array(babies))
    }
}
