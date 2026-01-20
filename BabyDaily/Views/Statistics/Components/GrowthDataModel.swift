import Foundation

// MARK: - 数据模型

// 单个月龄的成长百分位数据
struct GrowthPercentileData: Identifiable {
    let id = UUID()
    let month: Int
    let fifth: Double
    let twentyFifth: Double
    let fiftieth: Double
    let seventyFifth: Double
    let ninetyFifth: Double
    
    init(month: Int, fifth: Double?, twentyFifth: Double?, fiftieth: Double?, seventyFifth: Double?, ninetyFifth: Double?) {
        self.month = month
        self.fifth = fifth ?? 0.0
        self.twentyFifth = twentyFifth ?? 0.0
        self.fiftieth = fiftieth ?? 0.0
        self.seventyFifth = seventyFifth ?? 0.0
        self.ninetyFifth = ninetyFifth ?? 0.0
    }
}

// 完整的成长数据集
struct GrowthDataset {
    let data: [GrowthPercentileData]
    let dimension: String
    
    static var defaultData: GrowthDataset {
        // 分解复杂表达式，帮助编译器类型检查
        var defaultData: [GrowthPercentileData] = []
        
        for month in 0...24 {
            let percentileData = GrowthPercentileData(
                month: month,
                fifth: Double(month) * 2.0,
                twentyFifth: Double(month) * 2.5,
                fiftieth: Double(month) * 3.0,
                seventyFifth: Double(month) * 3.5,
                ninetyFifth: Double(month) * 4.0
            )
            defaultData.append(percentileData)
        }
        
        return GrowthDataset(data: defaultData, dimension: "height")
    }
}

// MARK: - CSV读取器

class CSVReader {
    
    static func readGrowthData(for gender: String, dimension: String) -> GrowthDataset {
        print("=== CSVReader 日志 ===")
        print("请求读取: 性别=\(gender), 维度=\(dimension)")
        
        guard let fileURL = getCSVFileURL(for: gender, dimension: dimension) else {
            print("❌ 无法找到CSV文件")
            return GrowthDataset.defaultData
        }
        
        print("✅ 找到CSV文件: \(fileURL.path)")
        
        guard let data = readGrowthData(from: fileURL) else {
            print("❌ 无法从CSV文件读取数据")
            return GrowthDataset.defaultData
        }
        
        print("✅ 成功读取\(data.count)条数据")
        print("====================")
        return GrowthDataset(data: data, dimension: dimension)
    }
    
    private static func getCSVFileURL(for gender: String, dimension: String) -> URL? {
        let fileName = "\(gender.lowercased())_\(dimension.lowercased()).csv"
        print("尝试查找文件: \(fileName)")
        
        // 1. 首先尝试使用bundle查找（用于生产环境）
        if let fileURL = Bundle.main.url(forResource: fileName, withExtension: nil, subdirectory: "csv") {
            print("✅ 在bundle的csv子目录中找到文件: \(fileURL.path)")
            return fileURL
        }
        
        // 2. 尝试在bundle根目录中查找
        if let fileURL = Bundle.main.url(forResource: fileName, withExtension: nil) {
            print("✅ 在bundle根目录中找到文件: \(fileURL.path)")
            return fileURL
        }
        
        // 3. 开发环境：直接使用项目目录下的Resources/csv路径
        let projectDir = URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let resourcesCSVPath = projectDir.appendingPathComponent("BabyDaily/Resources/csv/\(fileName)")
        print("尝试直接访问项目目录: \(resourcesCSVPath.path)")
        
        if FileManager.default.fileExists(atPath: resourcesCSVPath.path) {
            print("✅ 在项目的Resources/csv目录中找到文件")
            return resourcesCSVPath
        }
        
        // 4. 尝试其他可能的路径
        let alternativePaths = [
            projectDir.appendingPathComponent("Resources/csv/\(fileName)"),
            projectDir.appendingPathComponent("csv/\(fileName)"),
            URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("Resources/csv/\(fileName)")
        ]
        
        for path in alternativePaths {
            if FileManager.default.fileExists(atPath: path.path) {
                print("✅ 在替代路径中找到文件: \(path.path)")
                return path
            }
            print("❌ 替代路径不存在: \(path.path)")
        }
        
        // 如果都失败，列出当前目录结构以便调试
        print("❌ 无法找到文件 \(fileName)")
        do {
            // 打印当前文件所在目录
            let currentDir = URL(fileURLWithPath: #file).deletingLastPathComponent()
            print("📁 当前文件目录: \(currentDir.path)")
            let currentFiles = try FileManager.default.contentsOfDirectory(at: currentDir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            print("📁 当前目录文件: \(currentFiles.map { $0.lastPathComponent })")
            
            // 打印项目根目录
            print("📁 项目根目录: \(projectDir.path)")
            let rootFiles = try FileManager.default.contentsOfDirectory(at: projectDir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            print("📁 项目根目录文件: \(rootFiles.map { $0.lastPathComponent })")
            
            // 检查BabyDaily目录
            let babyDailyDir = projectDir.appendingPathComponent("BabyDaily")
            if FileManager.default.fileExists(atPath: babyDailyDir.path) {
                let babyDailyFiles = try FileManager.default.contentsOfDirectory(at: babyDailyDir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
                print("📁 BabyDaily目录文件: \(babyDailyFiles.map { $0.lastPathComponent })")
                
                // 检查Resources目录
                let resourcesDir = babyDailyDir.appendingPathComponent("Resources")
                if FileManager.default.fileExists(atPath: resourcesDir.path) {
                    let resourcesFiles = try FileManager.default.contentsOfDirectory(at: resourcesDir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
                    print("📁 Resources目录文件: \(resourcesFiles.map { $0.lastPathComponent })")
                    
                    // 检查csv目录
                    let csvDir = resourcesDir.appendingPathComponent("csv")
                    if FileManager.default.fileExists(atPath: csvDir.path) {
                        let csvFiles = try FileManager.default.contentsOfDirectory(at: csvDir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
                        print("📁 csv目录文件: \(csvFiles.map { $0.lastPathComponent })")
                    }
                }
            }
            
        } catch {
            print("❌ 无法列出目录文件: \(error)")
        }
        
        return nil
    }
    
    private static func readGrowthData(from fileURL: URL) -> [GrowthPercentileData]? {
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            print("📄 成功读取文件内容")
            
            let lines = content.components(separatedBy: .newlines)
            print("📋 文件共有\(lines.count)行")
            
            guard lines.count > 1 else { 
                print("❌ 文件行数以少")
                return nil 
            }
            
            let headers = lines[0].components(separatedBy: ",")
            print("🏷️ 标题行: \(headers)")
            
            guard let monthIndex = headers.firstIndex(of: "Month") else {
                print("❌ 无法找到Month列")
                return nil
            }
            
            guard let fifthIndex = headers.firstIndex(of: "5th") else {
                print("❌ 无法找到5th列")
                return nil
            }
            
            guard let twentyFifthIndex = headers.firstIndex(of: "25th") else {
                print("❌ 无法找到25th列")
                return nil
            }
            
            guard let fiftiethIndex = headers.firstIndex(of: "50th") else {
                print("❌ 无法找到50th列")
                return nil
            }
            
            guard let seventyFifthIndex = headers.firstIndex(of: "75th") else {
                print("❌ 无法找到75th列")
                return nil
            }
            
            guard let ninetyFifthIndex = headers.firstIndex(of: "95th") else {
                print("❌ 无法找到95th列")
                return nil
            }
            
            print("✅ 成功找到所有需要的列")
            print("Month列索引: \(monthIndex)")
            print("5th列索引: \(fifthIndex)")
            print("25th列索引: \(twentyFifthIndex)")
            print("50th列索引: \(fiftiethIndex)")
            print("75th列索引: \(seventyFifthIndex)")
            print("95th列索引: \(ninetyFifthIndex)")
            
            var result: [GrowthPercentileData] = []
            let maxIndex = max(monthIndex, fifthIndex, twentyFifthIndex, fiftiethIndex, seventyFifthIndex, ninetyFifthIndex)
            
            print("🔄 开始解析数据行...")
            
            for (index, line) in lines.dropFirst().enumerated() where !line.trimmingCharacters(in: .whitespaces).isEmpty {
                print("\n📝 解析第\(index+1)行: \(line)")
                
                let columns = line.components(separatedBy: ",")
                print("📊 列数: \(columns.count), 需要的最大列索引: \(maxIndex)")
                
                guard columns.count > maxIndex else {
                    print("⚠️  列数不足，跳过该行")
                    continue
                }
                
                guard let month = Int(columns[monthIndex]) else {
                    print("⚠️  月龄格式错误，跳过该行: \(columns[monthIndex])")
                    continue
                }
                
                let fifth = Double(columns[fifthIndex])
                let twentyFifth = Double(columns[twentyFifthIndex])
                let fiftieth = Double(columns[fiftiethIndex])
                let seventyFifth = Double(columns[seventyFifthIndex])
                let ninetyFifth = Double(columns[ninetyFifthIndex])
                
                print("📈 解析结果 - 月龄: \(month), 5th: \(fifth ?? 0.0), 25th: \(twentyFifth ?? 0.0), 50th: \(fiftieth ?? 0.0), 75th: \(seventyFifth ?? 0.0), 95th: \(ninetyFifth ?? 0.0)")
                
                let percentileData = GrowthPercentileData(
                    month: month,
                    fifth: fifth,
                    twentyFifth: twentyFifth,
                    fiftieth: fiftieth,
                    seventyFifth: seventyFifth,
                    ninetyFifth: ninetyFifth
                )
                
                result.append(percentileData)
            }
            
            print("✅ 数据解析完成，共解析\(result.count)条数据")
            return !result.isEmpty ? result : nil
            
        } catch {
            print("Error reading CSV: \(error)")
            return nil
        }
    }
}