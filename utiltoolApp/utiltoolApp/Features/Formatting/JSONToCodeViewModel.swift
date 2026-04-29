import Foundation

@Observable
class JSONToCodeViewModel {
    enum TargetLanguage: String, CaseIterable, Identifiable {
        case typescript = "TypeScript (Interface)"
        case swift = "Swift (Struct)"
        case go = "Go (Struct)"
        case python = "Python (TypedDict)"
        var id: String { self.rawValue }
    }
    
    var language: TargetLanguage = .typescript {
        didSet { generate() }
    }
    
    var rootClassName: String = "RootObject" {
        didSet { generate() }
    }
    
    var inputText: String = "" {
        didSet { generate() }
    }
    var outputText: String = ""
    var errorMessage: String? = nil
    
    // 用于存储拍平的嵌套结构，防止嵌套地狱
    private var subStructures: [(name: String, content: String)] = []
    
    func generate() {
        guard !inputText.isEmpty else {
            outputText = ""
            errorMessage = nil
            return
        }
        
        guard let data = inputText.data(using: .utf8) else {
            errorMessage = "编码错误"
            return
        }
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            errorMessage = nil
            subStructures = []
            
            var result = ""
            let rootName = rootClassName.isEmpty ? "RootObject" : rootClassName
            
            if let dictionary = jsonObject as? [String: Any] {
                let rootContent = generateClassContent(from: dictionary, name: rootName, lang: language)
                result = assembleFinalCode(rootName: rootName, rootContent: rootContent, lang: language)
            } else if let array = jsonObject as? [[String: Any]], let first = array.first {
                let rootContent = generateClassContent(from: first, name: rootName, lang: language)
                result = assembleFinalCode(rootName: rootName, rootContent: rootContent, lang: language)
            } else {
                result = "// 无法推断顶层结构"
            }
            
            outputText = result
        } catch {
            errorMessage = "JSON 语法错误: \(error.localizedDescription)"
        }
    }
    
    private func assembleFinalCode(rootName: String, rootContent: String, lang: TargetLanguage) -> String {
        var finalCode = ""
        
        // Swift 和 Python 可能需要引入基础库
        if lang == .swift { finalCode += "import Foundation\n\n" }
        if lang == .python { finalCode += "from typing import TypedDict, List, Any\n\n" }
        
        // 打印子结构
        for sub in subStructures.reversed() {
            finalCode += formatBlock(name: sub.name, content: sub.content, lang: lang) + "\n\n"
        }
        
        // 打印根结构
        finalCode += formatBlock(name: rootName, content: rootContent, lang: lang)
        
        return finalCode
    }
    
    private func formatBlock(name: String, content: String, lang: TargetLanguage) -> String {
        switch lang {
        case .typescript:
            return "interface \(name) {\n\(content)}"
        case .swift:
            return "struct \(name): Codable {\n\(content)}"
        case .go:
            return "type \(name) struct {\n\(content)}"
        case .python:
            return "class \(name)(TypedDict):\n\(content.isEmpty ? "    pass\n" : content)"
        }
    }
    
    private func generateClassContent(from dictionary: [String: Any], name: String, lang: TargetLanguage) -> String {
        var lines = ""
        let indent = lang == .python ? "    " : "  "
        
        // 保证输出字段顺序稳定
        let sortedKeys = dictionary.keys.sorted()
        
        for key in sortedKeys {
            let value = dictionary[key]!
            let capitalizedKey = key.prefix(1).capitalized + key.dropFirst()
            let subClassName = "\(name)\(capitalizedKey)"
            
            let typeStr = getLanguageType(for: value, key: key, lang: lang, subClassName: subClassName)
            
            switch lang {
            case .typescript:
                lines += "\(indent)\(key): \(typeStr);\n"
            case .swift:
                lines += "\(indent)let \(key): \(typeStr)?\n"
            case .go:
                lines += "\(indent)\(capitalizedKey) \(typeStr) `json:\"\(key)\"`\n"
            case .python:
                lines += "\(indent)\(key): \(typeStr)\n"
            }
        }
        return lines
    }
    
    private func getLanguageType(for value: Any, key: String, lang: TargetLanguage, subClassName: String) -> String {
        if value is String {
            switch lang { case .typescript: return "string"; case .swift: return "String"; case .go: return "string"; case .python: return "str" }
        }
        
        if let boolValue = value as? Bool {
            // Swift 里的 NSNumber 可能会把 0/1 当做 Bool，这里做个简单区分
            let mirror = NSNumber(value: boolValue)
            if String(cString: mirror.objCType) == "c" {
                 switch lang { case .typescript: return "boolean"; case .swift: return "Bool"; case .go: return "bool"; case .python: return "bool" }
            }
        }
        
        if value is Int || value is Int64 {
            switch lang { case .typescript: return "number"; case .swift: return "Int"; case .go: return "int"; case .python: return "int" }
        }
        
        if value is Double || value is Float {
            switch lang { case .typescript: return "number"; case .swift: return "Double"; case .go: return "float64"; case .python: return "float" }
        }
        
        if let dict = value as? [String: Any] {
            // 发现嵌套对象，注册为子结构
            let content = generateClassContent(from: dict, name: subClassName, lang: lang)
            subStructures.append((name: subClassName, content: content))
            return subClassName
        }
        
        if let array = value as? [Any] {
            if let first = array.first {
                let innerType = getLanguageType(for: first, key: key, lang: lang, subClassName: subClassName + "Item")
                switch lang {
                case .typescript: return "\(innerType)[]"
                case .swift: return "[\(innerType)]"
                case .go: return "[]\(innerType)"
                case .python: return "List[\(innerType)]"
                }
            } else {
                switch lang { case .typescript: return "any[]"; case .swift: return "[Any]"; case .go: return "[]interface{}"; case .python: return "List[Any]" }
            }
        }
        
        switch lang { case .typescript: return "any"; case .swift: return "Any"; case .go: return "interface{}"; case .python: return "Any" }
    }
}
