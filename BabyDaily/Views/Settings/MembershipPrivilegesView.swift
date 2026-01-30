//
//  MembershipPrivilegesView.swift
//  BabyDaily
//
//  会员特权页面
//  展示会员功能对比、价格信息和购买入口
//

import SwiftUI
import StoreKit

// MARK: - 会员权益行数据（图标 + 文案）
private struct PrivilegeRowItem {
    let feature: MembershipFeature
    let systemImage: String
}


struct MembershipPrivilegesView: View {
    // MARK: - State Objects
    @StateObject private var iapManager = IAPManager.shared
    @StateObject private var membershipManager = MembershipManager.shared
    
    // MARK: - State Properties
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Feature List
    private let features: [MembershipFeature] = [
        .removeAds,
        .basicRecords,
        // .quickActionRecords,
        .chartTrends,
        .familySharing,
        .multipleBabies,
        // .unlimitedWidgets,
        // .unlimitedCustomRecords,
        .iCloudSync,
        // .appleWatch,
        .futureFeatures
    ]

    private var privilegeRows: [PrivilegeRowItem] {
        [
            (MembershipFeature.removeAds, "megaphone"),
            (MembershipFeature.basicRecords, "doc.text"),
            (MembershipFeature.chartTrends, "chart.xyaxis.line"),
            (MembershipFeature.familySharing, "person.2"),
            (MembershipFeature.multipleBabies, "figure.2.and.child.holdinghands"),
            (MembershipFeature.iCloudSync, "icloud"),
            (MembershipFeature.futureFeatures, "sparkles")
        ].map { PrivilegeRowItem(feature: $0.0, systemImage: $0.1) }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // 当前会员状态卡片
                    if membershipManager.isPremiumMember {
                        currentMembershipStatusCard
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .padding(.bottom, 16)
                    }
                    
                    // 功能对比卡片
                    memberPrivilegesCard
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        .padding(.top, membershipManager.isPremiumMember ? 0 : 16)
                    
                    // 价格信息卡片
                    pricingCards
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    
                    // 法律声明和链接
                    legalSection
                        .padding(.horizontal, 16)
                        .padding(.bottom, 32)
                }
            }
            .navigationTitle("membership_subscription".localized)
            .navigationBarTitleDisplayMode(.inline)
             .toolbar(.hidden, for: .tabBar)
            .background(Color.themeBackground(for: colorScheme))
            .onAppear {
                Task {
                    await iapManager.loadProducts()
                }
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("ok".localized, role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - Helper Functions
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // MARK: - Current Membership Status Card
    private var currentMembershipStatusCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 24))
                
                Text("current_membership_status".localized)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Divider()
            
            // 会员类型
            HStack {
                Text("membership_type".localized)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let membershipType = membershipManager.membershipType {
                    Text(membershipType.localizedName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.accentColor)
                        .onTapGesture {
                            presentManageSubscriptions()
                        }
                } else {
                    Text("unknown".localized)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            // 会员状态
            HStack {
                Text("membership_status".localized)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(membershipManager.membershipStatus.localizedName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(membershipManager.membershipStatus == .active ? .green : .red)
            }
            
            // 过期时间（仅订阅会员）
            if membershipManager.membershipType == .subscription,
               let expirationDate = membershipManager.expirationDate {
                HStack {
                    Text("expiration_date".localized)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(formatDate(expirationDate))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(membershipManager.membershipStatus == .active ? .primary : .red)
                }
                
                // 到期提醒
                if membershipManager.isSubscriptionExpiringSoon {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 12))
                        
                        Text(membershipManager.isSubscriptionExpiringToday ? "subscription_expiring_today".localized : "subscription_expiring_soon_reminder".localized)
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                        
                        Spacer()
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(16)
        .background(Color.themeCardBackground(for: colorScheme))
        .cornerRadius(Constants.cornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

        

    private var memberPrivilegesCard: some View {
        VStack(alignment: .center, spacing: 10) {
            // 使用 Asset 中的 AppIconPreview（App Icon 的 appiconset 无法被 UIImage(named:) 加载）
            Image("Vip")
                .resizable()
                .frame(width: 120, height: 120)
                .cornerRadius(80)

            Text("membership_exclusive_privileges".localized)
                .font(.system(size: 14, weight: .semibold))
                .padding(.bottom, 12)
            
            ForEach(Array(privilegeRows.enumerated()), id: \.element.feature.rawValue) { index, item in
                memberPrivilegeRow(feature: item.feature, systemImage: item.systemImage)
                if index < privilegeRows.count - 1 {
                    GeometryReader { geometry in
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: 0))
                            path.addLine(to: CGPoint(x: geometry.size.width, y: 0))
                        }
                        .stroke(Color.accentColor.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                    }
                    .frame(height: 1)  // 限制高度，避免 GeometryReader 占满剩余空间导致 item 间留白
                    .padding(.leading, 36)
                }
            }
        }
        .padding()
        .background(Color.themeCardBackground(for: colorScheme))
        .cornerRadius(Constants.cornerRadius)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
    
    private func memberPrivilegeRow(feature: MembershipFeature, systemImage: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 18))
                .frame(width: 24, height: 24)
                .foregroundColor(Color.accentColor)

            Text(feature.localizedName)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer(minLength: 20)
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(Color.fromHex("#39855e"))
        }
    }
    
    // MARK: - Pricing Cards
    private var pricingCards: some View {
        VStack(spacing: 12) {
            // 月订阅卡片
            pricingCard(
                productID: IAPProductID.monthlyMembership,
                title: "premium_membership_monthly".localized
            )
            
            // 永久会员卡片
            pricingCard(
                productID: IAPProductID.premiumMembership,
                title: "premium_membership_lifetime".localized
            )
        }
    }
    
    // MARK: - Pricing Card
    private func pricingCard(
        productID: String,
        title: String
    ) -> some View {
        let product = iapManager.products.first(where: { $0.id == productID })
        // 检查是否正在加载产品
        let isLoadingProducts = iapManager.purchaseStatus == .loading
        // 检查是否正在购买当前产品
        let isPurchasingThisProduct = iapManager.purchaseStatus == .purchasing && 
                                      iapManager.currentProduct?.id == productID
        // 检查是否应该禁用（基于会员状态）
        let isDisabledByMembership = isCardDisabled(for: productID)
        // 按钮是否禁用：会员状态禁用 或 正在购买当前产品 或 产品未加载且正在加载
        let isDisabled = isDisabledByMembership || isPurchasingThisProduct || (product == nil && isLoadingProducts)
        // 是否显示加载状态：正在购买当前产品 或 产品未加载且正在加载产品
        let showLoading = isPurchasingThisProduct || (product == nil && isLoadingProducts)
        
        return Button(action: {
            guard let product = product else {
                showAlert(title: "purchase_failed".localized, message: "no_products_available".localized)
                return
            }
            handlePurchase(product: product)
        }) {
            HStack(spacing: 12) {
                // 标题
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // 价格或加载状态
                if showLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else if let product = product {
                    Text(product.displayPrice)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    // 产品未加载时显示占位符
                    Text("—")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color.accentColor)
            .cornerRadius(12)
            .opacity(isDisabled ? 0.8 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
    
    // MARK: - Card Disabled Check
    private func isCardDisabled(for productID: String) -> Bool {
        // 如果已经购买过永久会员，两个按钮都禁用
        if membershipManager.membershipType == .lifetime && 
           membershipManager.isPremiumMember && 
           membershipManager.membershipStatus == .active {
            return true
        }
        
        // 如果购买了月会员（且未过期），月会员订阅按钮禁用
        if productID == IAPProductID.monthlyMembership {
            if membershipManager.membershipType == .subscription &&
               membershipManager.isPremiumMember &&
               membershipManager.membershipStatus == .active {
                return true
            }
        }
        
        return false
    }
    
    
    // MARK: - Legal Section
    private var legalSection: some View {
        VStack(spacing: 16) {
            Text("subscribe_accept_terms".localized)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            HStack(spacing: 20) {
                legalLink(title: "privacy_policy".localized) {
                    openPrivacyPolicy()
                }
                
                legalLink(title: "terms_of_service".localized) {
                    openTermsOfService()
                }
                
                legalLink(title: "redeem_code".localized) {
                    presentCodeRedemption()
                }
                
                legalLink(title: "restore_purchases".localized) {
                    handleRestore()
                }
            }

        }
    }
    
    // MARK: - Legal Link
    private func legalLink(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.accentColor)
        }
    }
    
    // MARK: - Actions
    private func handlePurchase(product: Product) {
        // 更新当前产品
        iapManager.currentProduct = product
        
        Task {
            await iapManager.purchase(product)
            
            await MainActor.run {
                switch iapManager.purchaseStatus {
                case .success:
                    showAlert(title: "purchase_success".localized, message: "")
                    // 延迟关闭页面
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                case .failed(let error):
                    showAlert(title: "purchase_failed".localized, message: error)
                case .idle:
                    // 用户取消
                    break
                default:
                    break
                }
            }
        }
    }
    
    private func handleRestore() {
        Task {
            await iapManager.restorePurchases()
            
            await MainActor.run {
                switch iapManager.purchaseStatus {
                case .restored:
                    showAlert(title: "restore_success".localized, message: "")
                case .failed(let error):
                    showAlert(title: "restore_failed".localized, message: error)
                default:
                    break
                }
            }
        }
    }
    
    private func openPrivacyPolicy() {
        // TODO: 替换为实际的隐私政策URL
        if let url = URL(string: "https://my.feishu.cn/wiki/N6xkwhXXPikVDrk075tcsNpgn2q") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openTermsOfService() {
        // TODO: 替换为实际的使用条款URL
        if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
            UIApplication.shared.open(url)
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
    
    /// 显示iOS官方的兑换码界面
    private func presentCodeRedemption() {
        Task { @MainActor in
            // 获取当前的 window scene
            guard let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
                Logger.error("Failed to get current window scene")
                showAlert(title: "error".localized, message: "failed_to_present_code_redemption".localized)
                return
            }
            
            do {
                try await AppStore.presentOfferCodeRedeemSheet(in: windowScene)
                Logger.info("Code redemption sheet presented successfully")
            } catch {
                Logger.error("Failed to present code redemption sheet: \(error.localizedDescription)")
                showAlert(title: "error".localized, message: "failed_to_present_code_redemption".localized)
            }
        }
    }

    /// 显示管理订阅界面
    private func presentManageSubscriptions() {
        Task { @MainActor in
            guard let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
                Logger.error("Failed to get current window scene")
                return
            }
            
            do {
                try await AppStore.showManageSubscriptions(in: windowScene)
                Logger.info("Manage subscriptions sheet presented successfully")
            } catch {
                Logger.error("Failed to present manage subscriptions sheet: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Preview
#Preview {
    MembershipPrivilegesView()
}
