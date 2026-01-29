//
//  FamilyCollaborationView.swift
//  BabyDaily
//
//  Created by Assistant on 2026/01/27.
//

import SwiftUI
import CoreData
import CloudKit

struct FamilyCollaborationView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
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
                        ForEach(babies, id: \.objectID) { baby in
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
            .background(Color.themeBackground(for: colorScheme))
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
        .onAppear {
            // 请求 CloudKit 用户发现权限 (解决 Share Owner 名字为 nil 的问题)
            ShareManager.shared.requestPermissions()
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
    @Environment(\.colorScheme) private var colorScheme
    
    let baby: Baby
    let onInvite: () -> Void
    let onManage: () -> Void
    
    // 状态管理：共享数据
    @State private var share: CKShare?
    @State private var isLoadingShare = true
    @State private var participantCount = 0
    @State private var ownerName: String?
    
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
                if isLoadingShare {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("loading".localized) // 需确保有对应的本地化字符串，如果没有则显示默认
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else if let share = share {
                    // 已有共享
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.accentColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        if let owner = ownerName {
                            Text("Owner: \(owner)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // 显示参与者数量（不包括 Owner）
                        // CKShare.participants 包含 Owner 和其它参与者
                        // 我们通常关心的是“有多少人一起看”
                        let count = share.participants.count - 1 // 减去 Owner 自己（通常）
                        if count > 0 {
                            Text(String(format: "collaborators_count".localized, count))
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        } else {
                            Text("waiting_for_response".localized) // 或者 "仅自己"
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    // 无共享
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.secondary)
                    Text("no_collaborators_yet".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(Color.themeBackground(for: colorScheme))
            .cornerRadius(8)
            // 当视图出现时加载共享数据
            .task {
                await loadShareData()
            }
            
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
                     .background(Color.themeBackground(for: colorScheme))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.themeCardBackground(for: colorScheme))
        .cornerRadius(16)
    }
    
    // 加载共享数据
    private func loadShareData() async {
        isLoadingShare = true
        defer { isLoadingShare = false }
        
        let container = PersistenceController.shared.container
        do {
            let shares = try container.fetchShares(matching: [baby.objectID])
            if let share = shares[baby.objectID] {
                self.share = share
                self.participantCount = share.participants.count
                
                // 获取 Owner 名字
                if let nameComponents = share.owner.userIdentity.nameComponents {
                    self.ownerName = PersonNameComponentsFormatter().string(from: nameComponents)
                } else {
                    self.ownerName = "Unknown"
                }
            } else {
                self.share = nil
            }
        } catch {
            Logger.error("Failed to fetch share for baby \(baby.name): \(error)")
            self.share = nil
        }
    }
}
