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
    var outputHexText: String? = nil
    
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
            
            outputHexText = data?.hexString ?? ""
            
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

extension Data {
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}

extension Data {
    /// 生成类似 hexdump -C 的格式
    /// - Parameters:
    ///   - bytesPerRow: 每行显示的字节数，默认 16
    ///   - showOffset: 是否显示偏移量，默认 true
    /// - Returns: 格式化后的字符串
    func hexDump(bytesPerRow: Int = 16, showOffset: Bool = true) -> String {
        guard !isEmpty else { return "" }
        
        var result = ""
        for i in stride(from: 0, to: count, by: bytesPerRow) {
            let start = i
            let end = Swift.min(i + bytesPerRow, count)
            let bytes = [UInt8](self[start..<end])
            
            // 偏移量
            if showOffset {
                result += String(format: "%08x  ", start)
            }
            
            // 十六进制部分
            let hexBytes = bytes.map { String(format: "%02x", $0) }
            for (index, hex) in hexBytes.enumerated() {
                result += hex
                if index % 2 == 1 && index != hexBytes.count - 1 {
                    result += " "  // 每两个字节后加一个空格（类似 hexdump）
                } else if index != hexBytes.count - 1 {
                    result += " "
                }
            }
            
            // 补齐不足 bytesPerRow 的空位（保持对齐）
            let missing = bytesPerRow - bytes.count
            if missing > 0 {
                let spaces = (missing * 2) + (missing / 2) - (missing % 2 == 0 ? 0 : 1)
                result += String(repeating: " ", count: spaces)
            }
            
            // ASCII 部分
            result += "  |"
            for byte in bytes {
                let char = (32...126).contains(byte) ? Character(UnicodeScalar(byte)) : "."
                result += String(char)
            }
            result += "|\n"
        }
        return result
    }
}
