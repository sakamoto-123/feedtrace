//
//  MembershipPrivilegesView.swift
//  BabyDaily
//
//  会员特权页面
//  展示会员功能对比、价格信息和购买入口
//

import SwiftUI
import StoreKit

struct MembershipPrivilegesView: View {
    // MARK: - State Objects
    @StateObject private var iapManager = IAPManager.shared
    @StateObject private var membershipManager = MembershipManager.shared
    
    // MARK: - State Properties
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var showRedeemCode = false
    @State private var selectedProductID: String = IAPProductID.premiumMembership
    
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
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // 功能对比卡片
                    featureComparisonCard
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        .padding(.top, 16)
                    
                    // 价格信息卡片
                    pricingCards
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    
                    // 立即升级按钮
                    upgradeButton
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    
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
                    // 默认选择永久会员
                    if let premiumProduct = iapManager.products.first(where: { $0.id == IAPProductID.premiumMembership }) {
                        selectedProductID = IAPProductID.premiumMembership
                        iapManager.currentProduct = premiumProduct
                    } else if let firstProduct = iapManager.products.first {
                        selectedProductID = firstProduct.id
                        iapManager.currentProduct = firstProduct
                    }
                }
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("ok".localized, role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showRedeemCode) {
                RedeemCodeView()
            }
        }
    }
    
    // MARK: - Feature Comparison Card
    private var featureComparisonCard: some View {
        VStack(spacing: 0) {
            // 卡片标题行
            HStack(spacing: 0) {
                Text("feature_comparison".localized)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("regular_user".localized)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 80, alignment: .center)
                
                Text("premium_member".localized)
                    .font(.system(size: 14, weight: .semibold))
                    .premiumGradient()
                    .frame(width: 80, alignment: .center)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color(.systemGray3))
            
            // 功能列表
            ForEach(Array(features.enumerated()), id: \.element) { index, feature in
                featureRow(feature: feature)
                
                if index < features.count - 1 {
                    Divider()
                        .background(Color(.separator))
                        .padding(.leading, 16)
                }
            }
        }
        .background(Color.themeCardBackground(for: colorScheme))
        .cornerRadius(Constants.cornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Feature Row
    private func featureRow(feature: MembershipFeature) -> some View {
        HStack(spacing: 0) {
            Text(feature.localizedName)
                .font(.system(size: 14))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 普通用户状态
            statusIcon(isAvailable: feature.isAvailableForFreeUser)
                .frame(width: 80, alignment: .center)
            
            // 高级会员状态（总是可用）
            statusIcon(isAvailable: true)
                .frame(width: 80, alignment: .center)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Status Icon
    private func statusIcon(isAvailable: Bool) -> some View {
        Group {
            if isAvailable {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 20))
            } else {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray.opacity(0.4))
                    .font(.system(size: 20))
            }
        }
    }
    
    // MARK: - Pricing Cards
    private var pricingCards: some View {
        VStack(spacing: 12) {
            // 月订阅卡片
             if let monthlyProduct = iapManager.products.first(where: { $0.id == IAPProductID.monthlyMembership }) {
                selectablePricingCard(
                    product: monthlyProduct,
                    title: "premium_membership_monthly".localized,
                    isSelected: selectedProductID == IAPProductID.monthlyMembership
                ) {
                    selectedProductID = IAPProductID.monthlyMembership
                    iapManager.currentProduct = monthlyProduct
                }
             }
            
            // 永久会员卡片
             if let premiumProduct = iapManager.products.first(where: { $0.id == IAPProductID.premiumMembership }) {
                selectablePricingCard(
                    product: premiumProduct,
                    title: "premium_membership_lifetime".localized,
                    isSelected: selectedProductID == IAPProductID.premiumMembership
                ) {
                    selectedProductID = IAPProductID.premiumMembership
                    iapManager.currentProduct = premiumProduct
                }
             }
        }
    }
    
    // MARK: - Selectable Pricing Card
    private func selectablePricingCard(
        product: Product,
        title: String,
        isSelected: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // 选中图标
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? GradientColors.buttonColor : .gray)
                
                // 标题
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // 价格
                VStack(alignment: .trailing, spacing: 4) {
                    Text(product.displayPrice)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(isSelected ? GradientColors.buttonColor : .primary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color.fromHex("#FF6B35"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? GradientColors.buttonColor : Color.clear,
                        lineWidth: isSelected ? 2 : 0
                    )
            )
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Upgrade Button
    private var upgradeButton: some View {
        Button(action: {
            handlePurchase()
        }) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("upgrade_now".localized)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .buttonGradientBackground()
            .cornerRadius(12)
        }
        .disabled(isLoading || iapManager.purchaseStatus == .purchasing)
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
                    showRedeemCode = true
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
                .foregroundColor(.blue)
        }
    }
    
    // MARK: - Actions
    private func handlePurchase() {
        // 根据选中的产品ID获取产品
        let product = iapManager.products.first { $0.id == selectedProductID }
        
        guard let product = product else {
            showAlert(title: "purchase_failed".localized, message: "no_products_available".localized)
            return
        }
        
        // 更新当前产品
        iapManager.currentProduct = product
        
        isLoading = true
        
        Task {
            await iapManager.purchase(product)
            
            await MainActor.run {
                isLoading = false
                
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
        isLoading = true
        
        Task {
            await iapManager.restorePurchases()
            
            await MainActor.run {
                isLoading = false
                
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
        if let url = URL(string: "https://example.com/privacy") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openTermsOfService() {
        // TODO: 替换为实际的使用条款URL
        if let url = URL(string: "https://example.com/terms") {
            UIApplication.shared.open(url)
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

// MARK: - Redeem Code View
struct RedeemCodeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var redeemCode = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("redeem_code".localized)
                    .font(.headline)
                    .padding(.top)
                
                TextField("请输入会员码", text: $redeemCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button(action: {
                    handleRedeem()
                }) {
                    Text("兑换")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(GradientColors.buttonGradient)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("redeem_code".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .alert("提示", isPresented: $showAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func handleRedeem() {
        // TODO: 实现会员码兑换逻辑
        alertMessage = "会员码兑换功能开发中"
        showAlert = true
    }
}

// MARK: - Preview
#Preview {
    MembershipPrivilegesView()
}
