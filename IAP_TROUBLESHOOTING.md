# 内购产品加载失败问题诊断指南

## 问题描述

在 App Store Connect 中已创建产品ID，但代码中加载产品时显示 "No products found for IDs"。

**产品ID**:
- `cn.iizhi.babydaily.monthly_subscribe`
- `cn.iizhi.babydaily.lifetime`

**应用Bundle ID**: `cn.iizhi.babyDaily.BabyDaily`

## 可能原因分析

### 1. 产品状态问题 ⚠️ **最常见**

**问题**: 产品可能还在"准备提交"状态，尚未通过审核。

**检查方法**:
1. 登录 App Store Connect
2. 进入"我的App" > 选择应用 > "功能" > "App内购买项目"
3. 检查产品状态：
   - ✅ **已批准** (Approved) - 可以正常使用
   - ⚠️ **准备提交** (Ready to Submit) - 需要提交审核
   - ❌ **待处理** (Pending) - 正在审核中
   - ❌ **被拒绝** (Rejected) - 需要修复后重新提交

**解决方案**:
- 如果产品状态是"准备提交"，需要：
  1. 点击产品进入详情页
  2. 点击"提交以供审核"
  3. 等待审核通过（通常需要1-3天）

### 2. Bundle ID 不匹配

**问题**: 产品关联的Bundle ID与应用实际Bundle ID不一致。

**检查方法**:
- 在 App Store Connect 中查看产品详情，确认关联的Bundle ID
- 对比应用的实际Bundle ID: `cn.iizhi.babyDaily.BabyDaily`

**注意**: 
- Bundle ID 区分大小写
- 产品ID通常不区分大小写，但建议保持一致

**解决方案**:
- 确保产品关联的Bundle ID与应用Bundle ID完全一致
- 如果不同，需要重新创建产品或修改Bundle ID

### 3. 测试环境问题

**问题**: 在模拟器上测试或未使用沙盒账号。

**检查方法**:
- 确认是否在真实设备上测试
- 确认是否使用沙盒测试账号

**解决方案**:
1. **使用真实设备测试**:
   - 模拟器可能无法正常加载产品
   - 建议使用真实iPhone/iPad设备

2. **配置沙盒测试账号**:
   - 在设备"设置" > "App Store"中退出当前账号
   - 在应用内购买时，系统会提示使用沙盒账号登录
   - 使用在 App Store Connect 中创建的沙盒测试账号

### 4. 产品类型配置错误

**问题**: 产品类型与代码中期望的类型不匹配。

**检查方法**:
- 确认产品类型：
  - `lifetime` 应该是 **非消耗型产品** (Non-Consumable)
  - `monthly_subscribe` 应该是 **自动续期订阅** (Auto-Renewable Subscription)

**解决方案**:
- 在 App Store Connect 中检查产品类型是否正确
- 如果类型错误，需要删除并重新创建产品

### 5. 产品信息不完整

**问题**: 产品缺少必要的本地化信息或价格。

**检查方法**:
- 确认产品已填写：
  - ✅ 产品名称（所有语言）
  - ✅ 产品描述（所有语言）
  - ✅ 价格（所有地区）
  - ✅ 审核截图（如需要）

**解决方案**:
- 补充所有必需的产品信息
- 确保所有本地化信息完整

### 6. 同步延迟问题

**问题**: 产品创建后需要时间同步到StoreKit服务器。

**检查方法**:
- 确认产品创建时间
- 通常需要等待几分钟到几小时

**解决方案**:
- 等待24小时后重试
- 重启应用和设备
- 清除应用缓存

### 7. 网络和地区问题

**问题**: 网络连接问题或地区限制。

**检查方法**:
- 确认设备网络连接正常
- 确认App Store账号地区与产品可用地区匹配

**解决方案**:
- 检查网络连接
- 确认App Store账号地区设置
- 尝试切换网络（WiFi/蜂窝数据）

### 8. StoreKit配置问题

**问题**: 应用未正确配置StoreKit能力。

**检查方法**:
- 在Xcode中检查项目设置 > Signing & Capabilities
- 确认已添加"In-App Purchase"能力

**解决方案**:
1. 在Xcode中打开项目
2. 选择Target > Signing & Capabilities
3. 点击"+ Capability"
4. 添加"In-App Purchase"
5. 重新编译运行

## 诊断步骤

### 步骤1: 检查产品状态
```
1. 登录 App Store Connect
2. 进入产品列表
3. 检查每个产品的状态
4. 确认状态为"已批准"
```

### 步骤2: 验证Bundle ID
```
1. 在App Store Connect中查看产品详情
2. 确认关联的Bundle ID
3. 对比应用实际Bundle ID
4. 确保完全一致
```

### 步骤3: 检查产品信息
```
1. 确认产品类型正确
2. 确认所有本地化信息完整
3. 确认价格已设置
```

### 步骤4: 测试环境配置
```
1. 使用真实设备（非模拟器）
2. 配置沙盒测试账号
3. 在设备设置中退出App Store账号
```

### 步骤5: 查看详细日志
运行应用后，查看控制台输出：
- 产品ID列表
- Bundle ID信息
- 找到的产品数量
- 缺失的产品ID
- 错误详情

## 快速检查清单

- [ ] 产品状态为"已批准"
- [ ] Bundle ID完全匹配
- [ ] 产品类型正确（非消耗型/订阅型）
- [ ] 所有本地化信息完整
- [ ] 价格已设置
- [ ] 在真实设备上测试
- [ ] 使用沙盒测试账号
- [ ] 已添加In-App Purchase能力
- [ ] 网络连接正常
- [ ] 等待足够时间（如刚创建产品）

## 常见错误信息及解决方案

### "No products found for IDs"
- **原因**: 产品未找到
- **解决**: 检查产品状态、Bundle ID、产品信息完整性

### "Network error"
- **原因**: 网络连接问题
- **解决**: 检查网络，切换网络类型

### "StoreKit system error"
- **原因**: StoreKit系统错误
- **解决**: 重启应用和设备，检查系统版本

## 测试建议

1. **使用StoreKit Configuration文件**（推荐用于开发测试）:
   - 在Xcode中创建StoreKit Configuration文件
   - 添加测试产品
   - 在Scheme中启用StoreKit Configuration
   - 这样可以在不连接App Store的情况下测试

2. **使用沙盒环境**:
   - 创建沙盒测试账号
   - 在真实设备上测试
   - 使用沙盒账号完成购买流程

3. **查看详细日志**:
   - 代码已添加详细日志输出
   - 查看Xcode控制台获取诊断信息

## 联系支持

如果以上方法都无法解决问题，可以：
1. 查看Apple官方文档: [App Store Connect Help](https://help.apple.com/app-store-connect/)
2. 联系Apple开发者支持
3. 检查Apple开发者论坛相关问题

---

**最后更新**: 2026年1月
**版本**: 1.0.0
