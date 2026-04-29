import Foundation
import AppKit

@Observable
class CaseConverterViewModel {
    enum CaseType: String, CaseIterable, Identifiable {
        case camel = "camelCase"
        case pascal = "PascalCase"
        case snake = "snake_case"
        case kebab = "kebab-case"
        case upperSnake = "UPPER_SNAKE_CASE"
        case lowercase = "lowercase"
        case uppercase = "UPPERCASE"
        
        var id: String { self.rawValue }
    }
    
    var inputText: String = "" {
        didSet { convert() }
    }
    var targetCase: CaseType = .camel {
        didSet { convert() }
    }
    
    var outputText: String = ""
    
    private func convert() {
        guard !inputText.isEmpty else {
            outputText = ""
            return
        }
        
        // 处理多行文本
        let lines = inputText.components(separatedBy: .newlines)
        let convertedLines = lines.map { convertLine($0, to: targetCase) }
        outputText = convertedLines.joined(separator: "\n")
    }
    
    private func convertLine(_ line: String, to type: CaseType) -> String {
        if line.trimmingCharacters(in: .whitespaces).isEmpty { return line }
        let words = tokenize(line)
        if words.isEmpty { return line }
        
        switch type {
        case .camel:
            return words.enumerated().map { index, word in
                index == 0 ? word : word.capitalized
            }.joined()
            
        case .pascal:
            return words.map { $0.capitalized }.joined()
            
        case .snake:
            return words.joined(separator: "_")
            
        case .kebab:
            return words.joined(separator: "-")
            
        case .upperSnake:
            return words.map { $0.uppercased() }.joined(separator: "_")
            
        case .lowercase:
            return words.joined(separator: " ")
            
        case .uppercase:
            return words.map { $0.uppercased() }.joined(separator: " ")
        }
    }
    
    /// 将任何风格的字符串拆分为单词数组
    private func tokenize(_ string: String) -> [String] {
        var processed = string
        
        // 在小写字母和大写字母之间插入空格 (针对 camelCase / PascalCase)
        processed = processed.replacingOccurrences(
            of: "([a-z])([A-Z])",
            with: "$1 $2",
            options: .regularExpression
        )
        
        // 在连续大写字母和首字母大写的单词之间插入空格 (针对 XMLHttpRequest 变 XML Http Request)
        processed = processed.replacingOccurrences(
            of: "([A-Z])([A-Z][a-z])",
            with: "$1 $2",
            options: .regularExpression
        )
        
        // 将所有非字母数字字符替换为空格 (针对 snake_case / kebab-case)
        processed = processed.replacingOccurrences(
            of: "[^a-zA-Z0-9]+",
            with: " ",
            options: .regularExpression
        )
        
        // 分割并转换为全小写
        let words = processed.split(separator: " ")
            .map { String($0).lowercased() }
            .filter { !$0.isEmpty }
            
        return words
    }
}
