import SwiftUI

// 颜色工具类
struct ColorUtils {
    // 将十六进制字符串转换为Color
    static func hexToColor(_ hex: String) -> Color {
        // 移除#前缀
        let hexString = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        
        // 检查是否为6位十六进制数
        guard hexString.count == 6, let hexValue = UInt32(hexString, radix: 16) else {
            return .gray // 默认颜色
        }
        
        // 提取RGB值
        let red = Double((hexValue & 0xFF0000) >> 16) / 255.0
        let green = Double((hexValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(hexValue & 0x0000FF) / 255.0
        
        return Color(red: red, green: green, blue: blue)
    }
}

// 为Color类型添加扩展
extension Color {
    // 从十六进制字符串创建Color
    static func fromHex(_ hex: String) -> Color {
        return ColorUtils.hexToColor(hex)
    }
    
    // 从十六进制字符串初始化Color
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let (a, r, g, b): (Int, Int, Int, Int)
        if hex.count == 8 {
            a = Int(int >> 24) & 0xff
            r = Int(int >> 16) & 0xff
            g = Int(int >> 8) & 0xff
            b = Int(int) & 0xff
        } else if hex.count == 6 {
            a = 255
            r = Int(int >> 16) & 0xff
            g = Int(int >> 8) & 0xff
            b = Int(int) & 0xff
        } else {
            a = 255
            r = 0
            g = 0
            b = 0
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}