import Foundation

@Observable
class JSONFormatterViewModel {
    var inputText: String = "" {
        didSet {
            formatJSON()
        }
    }
    var outputText: String = ""
    var errorMessage: String? = nil
    
    // 选项状态
    var useTwoSpaces: Bool = true {
        didSet { formatJSON() }
    }
    
    func formatJSON() {
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
            
            var writingOptions: JSONSerialization.WritingOptions = [.prettyPrinted, .withoutEscapingSlashes]
            if #available(macOS 13.0, *) {
                // 如果需要支持早期版本 macOS，可以使用其他方式处理空格缩进
                // macOS 13+ 支持自定义缩进，但这里为了兼容性，我们先使用默认的 prettyPrinted
                // 默认的 prettyPrinted 是 2 个空格
            }

            let formattedData = try JSONSerialization.data(withJSONObject: jsonObject, options: writingOptions)
            
            if let formattedString = String(data: formattedData, encoding: .utf8) {
                // 简单的替换缩进策略 (针对 4 个空格的需求)
                if !useTwoSpaces {
                     let fourSpacesString = formattedString.replacingOccurrences(of: "  \"", with: "    \"")
                     outputText = fourSpacesString
                } else {
                     outputText = formattedString
                }
                errorMessage = nil
            }
        } catch {
            errorMessage = "JSON 语法错误: \(error.localizedDescription)"
        }
    }
    
    func compressJSON() {
         guard !inputText.isEmpty else { return }
         guard let data = inputText.data(using: .utf8) else { return }
         
         do {
             let jsonObject = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
             // 不使用 .prettyPrinted 即可实现压缩
             let compressedData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.withoutEscapingSlashes])
             if let compressedString = String(data: compressedData, encoding: .utf8) {
                 outputText = compressedString
                 errorMessage = nil
             }
         } catch {
             errorMessage = "JSON 语法错误: \(error.localizedDescription)"
         }
    }
}
