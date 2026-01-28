//
//  FamilyCollaborationView.swift
//  BabyDaily
//
//  Created by Assistant on 2026/01/27.
//

import SwiftUI
import CoreData

struct FamilyCollaborationView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Baby.createdAt, ascending: true)],
        animation: .default)
    private var babies: FetchedResults<Baby>
    
    @State private var selectedBabyForInvite: Baby?
    @State private var selectedBabyForManage: Baby?
    @State private var showGuideSheet = false
    @State private var showShareSheet = false
    @State private var isCreatingShare = false
    
    // 用于在 Guide 视图关闭后触发 Share Sheet
    @State private var pendingShareBaby: Baby?
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("select_baby_to_collaborate".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    // 宝宝列表
                    LazyVStack(spacing: 16) {
                        ForEach(babies) { baby in
                            BabyCollaborationCard(
                                baby: baby,
                                onInvite: {
                                    selectedBabyForInvite = baby
                                    showGuideSheet = true
                                },
                                onManage: {
                                    selectedBabyForManage = baby
                                    // 直接打开系统共享页面进行管理，但先确保 Share 对象存在（虽然管理时通常已存在，但为了保险和统一逻辑）
                                    isCreatingShare = true
                                    Task {
                                        do {
                                            // 尝试获取或创建 Share (如果是管理，通常是获取已存在的)
                                            let _ = try await ShareManager.shared.createShare(for: baby)
                                            
                                            await MainActor.run {
                                                isCreatingShare = false
                                                showShareSheet = true
                                            }
                                        } catch {
                                            await MainActor.run {
                                                isCreatingShare = false
                                                Logger.error("Failed to prepare share for management: \(error)")
                                                // 即使失败也尝试打开，可能是在无网络情况下查看本地状态
                                                showShareSheet = true
                                            }
                                        }
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("family_collaboration".localized)
            .toolbar(.hidden, for: .tabBar)
            .navigationBarTitleDisplayMode(.inline)
            
            // 加载指示器
            if isCreatingShare {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    
                    Text("creating_share_link".localized)
                        .foregroundColor(.white)
                        .font(.headline)
                }
                .padding(30)
                .background(Color.black.opacity(0.7))
                .cornerRadius(16)
            }
        }
        .sheet(isPresented: $showGuideSheet) {
            CollaborationGuideView {
                // 用户点击了引导页中的“邀请”按钮
                showGuideSheet = false
                
                // 延迟一下以确保 sheet 关闭动画完成后再开始操作
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if let baby = selectedBabyForInvite {
                        isCreatingShare = true
                        
                        Task {
                            do {
                                // 异步创建 Share
                                let _ = try await ShareManager.shared.createShare(for: baby)
                                
                                await MainActor.run {
                                    isCreatingShare = false
                                    pendingShareBaby = baby
                                    showShareSheet = true
                                }
                            } catch {
                                await MainActor.run {
                                    isCreatingShare = false
                                    Logger.error("Share creation failed: \(error)")
                                    // 这里可以添加 Alert
                                }
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let baby = pendingShareBaby ?? selectedBabyForManage {
                CloudSharingView(baby: baby)
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }
}

struct BabyCollaborationCard: View {
    let baby: Baby
    let onInvite: () -> Void
    let onManage: () -> Void
    
    // 计算年龄
    private var ageString: String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: baby.birthday, to: Date())
        
        if let years = components.year, years > 0 {
            return "\(years)\("year_unit".localized) \(components.month ?? 0)\("month_unit".localized)"
        } else if let months = components.month, months > 0 {
            return "\(months)\("month_unit".localized) \(components.day ?? 0)\("day_unit".localized)"
        } else {
            return "\(components.day ?? 0)\("day_unit".localized)"
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 宝宝头部信息
            HStack(spacing: 12) {
                if let photoData = baby.photo, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .foregroundColor(.gray)
                        .frame(width: 50, height: 50)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(baby.name)
                        .font(.headline)
                    Text(ageString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // 协作者状态
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.secondary)
                Text("no_collaborators_yet".localized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)
            
            // 按钮组
            VStack(spacing: 12) {
                Button(action: onInvite) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("invite_family_to_join".localized)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                Button(action: onManage) {
                    HStack {
                        Image(systemName: "gearshape")
                        Text("manage_collaboration".localized)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(UIColor.secondarySystemBackground))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
}
