import Foundation

@Observable
class JWTDecoderViewModel {
    var inputText: String = "" {
        didSet { decode() }
    }
    
    var headerText: String = ""
    var payloadText: String = ""
    var errorMessage: String? = nil
    
    func decode() {
        guard !inputText.isEmpty else {
            headerText = ""
            payloadText = ""
            errorMessage = nil
            return
        }
        
        let segments = inputText.components(separatedBy: ".")
        guard segments.count >= 2 else {
            errorMessage = "无效的 JWT 格式（应至少包含 Header 和 Payload）"
            headerText = ""
            payloadText = ""
            return
        }
        
        errorMessage = nil
        
        headerText = decodeSegment(segments[0]) ?? "无法解析 Header"
        payloadText = decodeSegment(segments[1]) ?? "无法解析 Payload"
    }
    
    private func decodeSegment(_ segment: String) -> String? {
        var base64 = segment
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // 补齐 Base64 填充符
        let length = base64.count
        if length % 4 != 0 {
            let padding = String(repeating: "=", count: 4 - (length % 4))
            base64 += padding
        }
        
        guard let data = Data(base64Encoded: base64),
              let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
              let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .withoutEscapingSlashes]),
              let result = String(data: prettyData, encoding: .utf8) else {
            return nil
        }
        
        return result
    }
}
