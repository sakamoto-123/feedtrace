//
//  Logger.swift
//  BabyDaily
//
//  日志工具类 - 仅在 Debug 环境输出日志
//

import Foundation

/// 日志级别
enum LogLevel {
    case info
    case warning
    case error
    case debug
    
    var prefix: String {
        switch self {
        case .info:
            return "[INFO]"
        case .warning:
            return "[WARNING]"
        case .error:
            return "[ERROR]"
        case .debug:
            return "[DEBUG]"
        }
    }
}

/// 日志工具类
class Logger {
    /// 日志输出方法 - 仅在 Debug 环境输出
    /// - Parameters:
    ///   - message: 日志消息
    ///   - level: 日志级别，默认为 info
    ///   - file: 文件名（自动获取）
    ///   - function: 函数名（自动获取）
    ///   - line: 行号（自动获取）
    static func log(
        _ message: String,
        level: LogLevel = .info,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        #if DEBUG
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "\(timestamp) \(level.prefix) [\(fileName):\(line)] \(function) - \(message)"
        Swift.print(logMessage)
        #endif
    }
    
    /// 信息级别日志
    static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, file: file, function: function, line: line)
    }
    
    /// 警告级别日志
    static func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, file: file, function: function, line: line)
    }
    
    /// 错误级别日志
    static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, file: file, function: function, line: line)
    }
    
    /// 调试级别日志
    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, file: file, function: function, line: line)
    }
}

/// 全局 print 函数包装 - 仅在 Debug 环境输出
/// 使用方式：直接调用 print()，会自动判断是否为 Debug 环境
func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    #if DEBUG
    Swift.print(items.map { "\($0)" }.joined(separator: separator), terminator: terminator)
    #endif
}

/// 带标签的 print 函数 - 仅在 Debug 环境输出
func print(_ label: String, _ items: Any..., separator: String = " ", terminator: String = "\n") {
    #if DEBUG
    Swift.print("[\(label)]", items.map { "\($0)" }.joined(separator: separator), terminator: terminator)
    #endif
}
