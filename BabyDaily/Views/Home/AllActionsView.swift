//
//  AllActionsView.swift
//  BabyDaily
//
// 所有操作独立页面，承载 AllActionsSection；作为可 push 的 destination 使用。
//

import SwiftUI
import CoreData

struct AllActionsView: View {
    let baby: Baby
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            AllActionsSection(
                allActions: Constants.allCategorysByOrder,
                baby: baby
            )
            .padding(.bottom, 20)
        }
        .background(Color.themeListBackground(for: colorScheme))
        .navigationTitle("all_actions".localized)
        .navigationBarTitleDisplayMode(.inline)
    }
}
