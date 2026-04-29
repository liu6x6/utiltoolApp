import Foundation

@Observable
class XMLFormatterViewModel {
    var inputText: String = "" {
        didSet { formatXML() }
    }
    var outputText: String = ""
    var errorMessage: String? = nil
    
    func formatXML() {
        guard !inputText.isEmpty else {
            outputText = ""
            errorMessage = nil
            return
        }
        
        do {
            // XMLDocument 仅在 macOS 的 Foundation 中可用
            let doc = try XMLDocument(xmlString: inputText, options: [.documentTidyXML])
            
            // 使用 prettyPrinted 选项
            let options: XMLNode.Options = [.nodePrettyPrint]
            let formattedXML = doc.xmlString(options: options)
            
            outputText = formattedXML
            errorMessage = nil
        } catch {
            errorMessage = "XML 语法错误: \(error.localizedDescription)"
        }
    }
    
    func compressXML() {
        guard !inputText.isEmpty else { return }
        do {
            let doc = try XMLDocument(xmlString: inputText, options: [.documentTidyXML])
            // 不带 prettyPrint 选项即可实现某种程度的压缩
            outputText = doc.xmlString(options: [])
            errorMessage = nil
        } catch {
            errorMessage = "XML 语法错误: \(error.localizedDescription)"
        }
    }
}
