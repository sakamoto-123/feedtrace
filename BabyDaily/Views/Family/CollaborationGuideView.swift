//
//  CollaborationGuideView.swift
//  BabyDaily
//
//  Created by Assistant on 2026/01/27.
//

import SwiftUI

struct CollaborationGuideView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appSettings: AppSettings
    let onInvite: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航栏
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Text("close".localized)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .foregroundColor(.primary)
                        .background(Color.white)
                        .cornerRadius(20)
                }
                
                Spacer()
                
                Text("collaboration_invitation_tip".localized)
                    .font(.headline)
                
                Spacer()
                
                // 占位以保持标题居中
                Color.clear
                    .frame(width: 60, height: 40)
            }
            .padding()
            .background(Color(UIColor.systemGroupedBackground))
            
            ScrollView {
                VStack(spacing: 20) {
                    // 步骤说明
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("three_steps_to_share".localized)
                                .font(.headline)
                        }
                        
                        GuideStepRow(number: 1, text: "step_1_invite_text".localized)
                        GuideStepRow(number: 2, text: "step_2_contact_info".localized)
                        GuideStepRow(number: 3, text: "step_3_send_invite".localized)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    
                    // iCloud 设置提示
                    GuideTipCard(
                        icon: "icloud.fill",
                        iconColor: appSettings.currentThemeColor,
                        title: "ensure_icloud_setup".localized,
                        description: "ensure_icloud_setup_desc".localized
                    )
                    
                    // 短信 App 提示
                    GuideTipCard(
                        icon: "message.fill",
                        iconColor: appSettings.currentThemeColor,
                        title: "must_use_imessage".localized,
                        description: "must_use_imessage_desc".localized
                    )
                    
                    // 安装 App 提示
                    GuideTipCard(
                        icon: "app.badge.fill", // 或者使用应用图标
                        iconColor: appSettings.currentThemeColor,
                        title: "remind_install_app".localized,
                        description: "remind_install_app_desc".localized
                    )
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
            
            // 底部按钮
            Button(action: onInvite) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("invite_family_to_join".localized)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(appSettings.currentThemeColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding()
            .background(Color.white)
        }
    }
}

struct GuideStepRow: View {
    @EnvironmentObject var appSettings: AppSettings
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(appSettings.currentThemeColor)
                    .frame(width: 24, height: 24)
                Text("\(number)")
                    .foregroundColor(.white)
                    .font(.caption)
                    .bold()
            }
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

struct GuideTipCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .bold()
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}
