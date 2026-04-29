import Foundation

@Observable
class URLEncodeViewModel {
    enum Mode {
        case encode
        case decode
    }
    
    var mode: Mode = .encode {
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
            // 也可以使用 urlQueryAllowed 等
            let allowedCharacterSet = CharacterSet.urlQueryAllowed
            if let encoded = inputText.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) {
                outputText = encoded
                errorMessage = nil
            } else {
                outputText = ""
                errorMessage = "URL 编码失败"
            }
        case .decode:
            if let decoded = inputText.removingPercentEncoding {
                outputText = decoded
                errorMessage = nil
            } else {
                outputText = ""
                errorMessage = "URL 解码失败"
            }
        }
    }
}
