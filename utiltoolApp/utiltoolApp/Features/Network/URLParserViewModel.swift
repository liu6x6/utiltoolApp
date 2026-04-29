import Foundation

@Observable
class URLParserViewModel {
    var inputURL: String = "" {
        didSet { parse() }
    }
    
    var scheme: String = ""
    var host: String = ""
    var path: String = ""
    var port: String = ""
    
    struct QueryItem: Identifiable {
        let id = UUID()
        let key: String
        let value: String
    }
    var queryItems: [QueryItem] = []
    
    func parse() {
        guard !inputURL.isEmpty else {
            clear()
            return
        }
        
        let trimmedURL = inputURL.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 尝试添加 https:// 如果没有 scheme 以便于 URLComponents 正常解析 Host
        var urlString = trimmedURL
        if !urlString.lowercased().hasPrefix("http://") && !urlString.lowercased().hasPrefix("https://") {
            if urlString.contains("://") {
                // 有其他协议但被误判，或者根本不是合法 URL
            } else {
                urlString = "https://" + urlString
            }
        }
        
        guard let components = URLComponents(string: urlString) else {
            clear()
            return
        }
        
        scheme = components.scheme ?? ""
        host = components.host ?? ""
        path = components.path
        port = components.port != nil ? String(components.port!) : ""
        
        if let qItems = components.queryItems {
            queryItems = qItems.map { QueryItem(key: $0.name, value: $0.value ?? "") }
        } else {
            queryItems = []
        }
    }
    
    private func clear() {
        scheme = ""
        host = ""
        path = ""
        port = ""
        queryItems = []
    }
}
