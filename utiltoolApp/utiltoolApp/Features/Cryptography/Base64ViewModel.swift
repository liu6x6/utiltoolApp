import Foundation

@Observable
class BaseEncodeViewModel {
    enum Mode {
        case encode
        case decode
    }
    
    enum BaseType: String, CaseIterable, Identifiable {
        case base64 = "Base64"
        case base32 = "Base32"
        var id: String { self.rawValue }
    }
    
    var mode: Mode = .encode {
        didSet { process() }
    }
    
    var baseType: BaseType = .base64 {
        didSet { process() }
    }
    
    var inputText: String = "" {
        didSet { process() }
    }
    
    var outputText: String = ""
    var errorMessage: String? = nil
    
    func process() {
        guard !inputText.isEmpty else {
            outputText = ""
            errorMessage = nil
            return
        }
        
        switch mode {
        case .encode:
            if let data = inputText.data(using: .utf8) {
                if baseType == .base64 {
                    outputText = data.base64EncodedString()
                } else {
                    outputText = Base32.encode(data)
                }
                errorMessage = nil
            } else {
                errorMessage = "编码失败：无法将文本转换为 Data"
            }
        case .decode:
            let cleanText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
            
            var data: Data?
            if baseType == .base64 {
                data = Data(base64Encoded: cleanText)
            } else {
                data = Base32.decode(cleanText)
            }
            
            if let decodedData = data,
               let decodedString = String(data: decodedData, encoding: .utf8) {
                outputText = decodedString
                errorMessage = nil
            } else {
                outputText = ""
                errorMessage = "无效的 \(baseType.rawValue) 字符串"
            }
        }
    }
}
