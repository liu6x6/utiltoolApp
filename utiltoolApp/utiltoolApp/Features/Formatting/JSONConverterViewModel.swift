import Foundation

@Observable
class JSONConverterViewModel {
    enum TargetFormat: String, CaseIterable, Identifiable {
        case yaml = "YAML"
        case csv = "CSV"
        var id: String { self.rawValue }
    }
    
    var targetFormat: TargetFormat = .yaml {
        didSet { convert() }
    }
    
    var inputText: String = "" {
        didSet { convert() }
    }
    
    var outputText: String = ""
    var errorMessage: String? = nil
    
    func convert() {
        guard !inputText.isEmpty else {
            outputText = ""
            errorMessage = nil
            return
        }
        
        guard let data = inputText.data(using: .utf8) else {
            errorMessage = "无效的字符串编码"
            return
        }
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
            errorMessage = nil
            
            switch targetFormat {
            case .yaml:
                outputText = jsonToYAML(value: jsonObject, indentLevel: 0)
            case .csv:
                outputText = jsonToCSV(value: jsonObject)
            }
        } catch {
            errorMessage = "JSON 语法错误: \(error.localizedDescription)"
        }
    }
    
    // MARK: - JSON to YAML
    private func jsonToYAML(value: Any, indentLevel: Int) -> String {
        let indent = String(repeating: "  ", count: indentLevel)
        
        if let dict = value as? [String: Any] {
            if dict.isEmpty { return "{}" }
            var result = ""
            let sortedKeys = dict.keys.sorted()
            
            for (index, key) in sortedKeys.enumerated() {
                let val = dict[key]!
                let isComplex = val is [String: Any] || (val as? [Any])?.isEmpty == false
                let valStr = jsonToYAML(value: val, indentLevel: indentLevel + 1)
                
                if isComplex {
                    result += "\(indent)\(key):\n\(valStr)"
                } else {
                    result += "\(indent)\(key): \(valStr)\n"
                }
            }
            return result
        } else if let array = value as? [Any] {
            if array.isEmpty { return "[]" }
            var result = ""
            
            for item in array {
                let isComplexDict = item is [String: Any]
                let isComplexArray = (item as? [Any])?.isEmpty == false
                let itemStr = jsonToYAML(value: item, indentLevel: indentLevel + 1)
                
                if isComplexDict {
                    let lines = itemStr.components(separatedBy: .newlines).filter { !$0.isEmpty }
                    if let first = lines.first {
                        let rest = lines.dropFirst().map { "  \($0)" }.joined(separator: "\n")
                        // 移除第一行的缩进并加上 "- "
                        let trimmedFirst = first.trimmingCharacters(in: .whitespaces)
                        result += "\(indent)- \(trimmedFirst)\n"
                        if !rest.isEmpty { result += "\(rest)\n" }
                    }
                } else if isComplexArray {
                    result += "\(indent)-\n\(itemStr)"
                } else {
                    // 标量数组
                    let trimmedItem = itemStr.trimmingCharacters(in: .whitespacesAndNewlines)
                    result += "\(indent)- \(trimmedItem)\n"
                }
            }
            return result
        } else if let str = value as? String {
            // 需要转义的字符串
            if str.contains("\n") || str.contains(":") || str.contains("\"") || str.contains("'") || str.hasPrefix(" ") || str.hasSuffix(" ") {
                let escaped = str.replacingOccurrences(of: "\"", with: "\\\"")
                return "\"\(escaped)\""
            }
            return str.isEmpty ? "\"\"" : str
        } else if let num = value as? NSNumber {
            // 区分 Bool 和其他 Number
            if CFGetTypeID(num) == CFGetTypeID(kCFBooleanTrue) {
                return num.boolValue ? "true" : "false"
            }
            return num.stringValue
        } else if value is NSNull {
            return "null"
        } else {
            return String(describing: value)
        }
    }
    
    // MARK: - JSON to CSV
    private func jsonToCSV(value: Any) -> String {
        var rows: [[String: Any]] = []
        
        if let dict = value as? [String: Any] {
            rows = [dict] // 单个对象作为一行
        } else if let array = value as? [[String: Any]] {
            rows = array // 对象数组
        } else {
            return "转换错误：JSON 必须是对象 (Object) 或对象数组 (Array of Objects) 才能转换为 CSV。"
        }
        
        guard !rows.isEmpty else { return "" }
        
        // 收集所有唯一的表头 (Keys)
        var keys: [String] = []
        for row in rows {
            for key in row.keys {
                if !keys.contains(key) {
                    keys.append(key)
                }
            }
        }
        
        // 生成表头
        var csvString = keys.map { escapeCSV(String($0)) }.joined(separator: ",") + "\n"
        
        // 生成数据行
        for row in rows {
            let rowValues = keys.map { key -> String in
                if let val = row[key] {
                    return escapeCSV(val)
                }
                return ""
            }
            csvString += rowValues.joined(separator: ",") + "\n"
        }
        
        return csvString
    }
    
    private func escapeCSV(_ value: Any) -> String {
        var stringValue = ""
        
        if let dict = value as? [String: Any], let data = try? JSONSerialization.data(withJSONObject: dict), let json = String(data: data, encoding: .utf8) {
            stringValue = json
        } else if let array = value as? [Any], let data = try? JSONSerialization.data(withJSONObject: array), let json = String(data: data, encoding: .utf8) {
            stringValue = json
        } else if let num = value as? NSNumber {
            if CFGetTypeID(num) == CFGetTypeID(kCFBooleanTrue) {
                stringValue = num.boolValue ? "true" : "false"
            } else {
                stringValue = num.stringValue
            }
        } else if value is NSNull {
            stringValue = ""
        } else {
            stringValue = String(describing: value)
        }
        
        // CSV 转义规则: 包含逗号、双引号或换行符的字段需要被双引号包裹，且字段内的双引号需要翻倍 ("")
        if stringValue.contains(",") || stringValue.contains("\"") || stringValue.contains("\n") {
            let escaped = stringValue.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return stringValue
    }
}
