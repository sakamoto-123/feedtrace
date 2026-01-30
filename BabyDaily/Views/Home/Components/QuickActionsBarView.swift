//
//  QuickActionsBarView.swift
//  BabyDaily
//
// 首页底部固定的 4 个快速操作入口。
//

import SwiftUI
import CoreData

struct QuickActionsBarView: View {
    let baby: Baby

    private var quickActions: [(category: String, icon: String, name: String, color: Color)] {
        Constants.quickActions
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Spacer()
            ForEach(quickActions, id: \.name) { action in
                CategoryActionButton(
                    icon: action.icon,
                    name: action.name,
                    color: action.color,
                    category: action.category,
                    baby: baby,
                    size: 44
                )
                .frame(maxWidth: .infinity)
            }

            NavigationLink(destination: AllActionsView(baby: baby)) {
                VStack(alignment: .center, spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.3))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .stroke(Color.accentColor, lineWidth: 1.5)
                            )
                        Text("📦")
                            .font(.system(size: 20))
                    }
                    Text("more".localized)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PlainButtonStyle())
            Spacer() 
        }
        .padding(.vertical, 8)
        .background(.ultraThinMaterial.opacity(0.9))
        .cornerRadius(60)
        .padding(.horizontal, 16)
        .offset(y: -20)

    }
}
