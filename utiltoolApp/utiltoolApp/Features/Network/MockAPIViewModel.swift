import Foundation

struct MockEndpoint: Identifiable, Codable, Hashable {
    var id = UUID()
    var method: String = "GET"
    var path: String = "/api/test"
    var statusCode: Int = 200
    var responseBody: String = "{\n  \"message\": \"Hello World\"\n}"
    var contentType: String = "application/json"
    var isActive: Bool = true
    var responseFilePath: String? = nil
    
    // WebSocket 特有配置
    var wsStrategy: String = "on_connect" // "on_connect" 或 "periodic"
    var wsInterval: Double = 5.0
}

struct MockRequestLog: Identifiable, Hashable {
    var id = UUID()
    var method: String
    var path: String
    var headers: [String: String]
    var body: String
    var timestamp: Date
    var responseStatusCode: Int?
}

@Observable
class MockAPIViewModel {
    var endpoints: [MockEndpoint] = []
    var isRunning: Bool = false
    var port: String = "8080"
    var errorMessage: String? = nil
    
    var configBaseDirectory: URL? = nil
    
    var requestLogs: [MockRequestLog] = []
    var selectedLogId: UUID? = nil
    
    var selectedEndpointId: UUID? = nil {
        didSet {
            if let selected = endpoints.first(where: { $0.id == selectedEndpointId }) {
                editingEndpoint = selected
            } else {
                editingEndpoint = nil
            }
        }
    }
    
    // 当前正在编辑的 Endpoint 草稿，当它改变时实时同步到数组
    var editingEndpoint: MockEndpoint? {
        didSet {
            if let editing = editingEndpoint, let index = endpoints.firstIndex(where: { $0.id == editing.id }) {
                endpoints[index] = editing
                save()
            }
        }
    }
    
    private var server: SimpleHTTPServer?
    
    let availableMethods = ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS", "WS"]
    let availableContentTypes = ["application/json", "text/plain", "text/html", "application/xml"]
    
    init() {
        if let data = UserDefaults.standard.data(forKey: "MockEndpointsData"),
           let decoded = try? JSONDecoder().decode([MockEndpoint].self, from: data) {
            endpoints = decoded
        } else {
            endpoints = [MockEndpoint()]
        }
        
        if let savedPort = UserDefaults.standard.string(forKey: "MockEndpointsPort") {
            port = savedPort
        }
        
        selectedEndpointId = endpoints.first?.id
    }
    
    func save() {
        if let encoded = try? JSONEncoder().encode(endpoints) {
            UserDefaults.standard.set(encoded, forKey: "MockEndpointsData")
        }
        UserDefaults.standard.set(port, forKey: "MockEndpointsPort")
    }
    
    func addEndpoint() {
        let newEndpoint = MockEndpoint(path: "/api/new-\(endpoints.count + 1)")
        endpoints.append(newEndpoint)
        selectedEndpointId = newEndpoint.id
        save()
    }
    
    func removeEndpoint(id: UUID) {
        endpoints.removeAll { $0.id == id }
        if selectedEndpointId == id {
            selectedEndpointId = endpoints.first?.id
        }
        save()
    }
    
    func loadConfig(from url: URL) {
        guard let yamlString = try? String(contentsOf: url, encoding: .utf8) else {
            DispatchQueue.main.async {
                self.errorMessage = "读取 YAML 失败"
            }
            return
        }
        
        let parsed = SimpleYAMLParser.parse(yaml: yamlString)
        
        DispatchQueue.main.async {
            self.configBaseDirectory = url.deletingLastPathComponent()
            
            // Extract port
            if let serverDict = parsed["server"] as? [String: Any] {
                if let portStr = serverDict["port"] as? String {
                    self.port = portStr
                }
            } else if let serverList = parsed["server"] as? [[String: Any]], let serverDict = serverList.first {
                if let portStr = serverDict["port"] as? String {
                    self.port = portStr
                }
            }
            
            // Extract endpoints
            if let epsList = parsed["endpoints"] as? [[String: Any]] {
                var newEps: [MockEndpoint] = []
                for epDict in epsList {
                    guard let path = epDict["path"] as? String else { continue }
                    var ep = MockEndpoint(path: path)
                    
                    if let method = epDict["method"] as? String {
                        ep.method = method.uppercased()
                    }
                    if let file = epDict["responseFile"] as? String {
                        ep.responseFilePath = file
                        // 预读取 JSON 避免沙盒权限问题，也支持实时修改（如果是完全授权目录）
                        if let baseDir = self.configBaseDirectory {
                            let fileURL = baseDir.appendingPathComponent(file)
                            if let jsonStr = try? String(contentsOf: fileURL, encoding: .utf8) {
                                ep.responseBody = jsonStr
                            } else {
                                ep.responseBody = "{\n  \"error\": \"Missing file: \(file)\"\n}"
                            }
                        }
                    }
                    if let codeStr = epDict["statusCode"] as? String, let code = Int(codeStr) {
                        ep.statusCode = code
                    }
                    if let strategy = epDict["wsStrategy"] as? String {
                        ep.wsStrategy = strategy
                    }
                    if let intervalStr = epDict["wsInterval"] as? String, let interval = Double(intervalStr) {
                        ep.wsInterval = interval
                    }
                    newEps.append(ep)
                }
                
                if !newEps.isEmpty {
                    self.endpoints = newEps
                    self.selectedEndpointId = newEps.first?.id
                    self.save()
                    self.errorMessage = nil
                } else {
                    self.errorMessage = "YAML 中未找到有效的 endpoints"
                }
            }
        }
    }
    
    func clearLogs() {
        requestLogs.removeAll()
        selectedLogId = nil
    }
    
    private func appendLog(_ log: MockRequestLog, statusCode: Int) {
        var newLog = log
        newLog.responseStatusCode = statusCode
        DispatchQueue.main.async {
            self.requestLogs.insert(newLog, at: 0)
            if self.requestLogs.count > 100 {
                self.requestLogs.removeLast()
            }
        }
    }
    
    func toggleServer() {
        if isRunning {
            server?.stop()
            server = nil
            isRunning = false
            errorMessage = nil
        } else {
            guard let portNum = UInt16(port) else {
                errorMessage = "无效的端口号 (需在 1-65535 之间)"
                return
            }
            
            server = SimpleHTTPServer()
            server?.requestHandler = { [weak self] method, path, headers, body in
                guard let self = self else { return (500, "Internal Server Error", "text/plain", nil) }
                
                let isWSRequest = headers.contains(where: { $0.key.lowercased() == "upgrade" && $0.value.lowercased() == "websocket" })
                let effectiveMethod = isWSRequest ? "WS" : method
                
                let log = MockRequestLog(method: effectiveMethod, path: path, headers: headers, body: body, timestamp: Date())
                
                // 处理 CORS 预检请求 (OPTIONS)
                if method == "OPTIONS" {
                    self.appendLog(log, statusCode: 200)
                    return (200, "", "text/plain", nil)
                }
                
                // 精确匹配 Method 和 Path
                if let endpoint = self.endpoints.first(where: { $0.isActive && $0.method == effectiveMethod && self.isPathOK(definePath: $0.path, urlPath:path) }) {
                    var responseBody = endpoint.responseBody
                    
                    let dynamicBodyClosure: () -> String = { [weak self] in
                        var currentBody = endpoint.responseBody
                        if let file = endpoint.responseFilePath, let baseDir = self?.configBaseDirectory {
                            let fileURL = baseDir.appendingPathComponent(file)
                            if let liveData = try? Data(contentsOf: fileURL), let liveString = String(data: liveData, encoding: .utf8) {
                                currentBody = liveString
                            }
                        }
                        return currentBody
                    }
                    
                    responseBody = dynamicBodyClosure()
                    
                    if effectiveMethod == "WS" {
                        self.appendLog(log, statusCode: 101)
                        let options = WSOptions(strategy: endpoint.wsStrategy, interval: endpoint.wsInterval, dynamicBody: dynamicBodyClosure)
                        return (101, responseBody, "", options)
                    } else {
                        self.appendLog(log, statusCode: endpoint.statusCode)
                        return (endpoint.statusCode, responseBody, endpoint.contentType, nil)
                    }
                }
                
                // 找不到路由
                self.appendLog(log, statusCode: 404)
                return (404, "{\n  \"error\": \"Route Not Found\"\n}", "application/json", nil)
            }
            
            do {
                try server?.start(port: portNum)
                isRunning = true
                errorMessage = nil
                save()
            } catch {
                errorMessage = "启动服务器失败，端口可能被占用。"
                server = nil
                isRunning = false
            }
        }
    }
    
    func isPathOK(definePath: String, urlPath: String) -> Bool {
        // 1. 如果完全相等，直接返回 true
        if definePath == urlPath {
            return true
        }
        
        // 2. 按 "/" 拆分成组件数组并过滤掉空值
        let defineComponents = definePath.components(separatedBy: "/").filter { !$0.isEmpty }
        let urlComponents = urlPath.components(separatedBy: "/").filter { !$0.isEmpty }
        
        // 3. 逐个层级进行匹配
        for i in 0..<defineComponents.count {
            let defComp = defineComponents[i]
            
            // 规则 A: 如果遇到了 "*"，说明后面全部允许匹配
            if defComp == "*" {
                return urlComponents.count >= i
            }
            
            // 如果 urlPath 已经没有对应层级了，说明 urlPath 太短，匹配失败
            if i >= urlComponents.count {
                return false
            }
            
            let urlComp = urlComponents[i]
            
            // 规则 B: 如果是 "?"，代表任意单词，直接跳过
            if defComp == "?" {
                continue
            }
            
            // 规则 C: 支持 "或" 操作，语法如 (recipe|article|video)
            if defComp.hasPrefix("(") && defComp.hasSuffix(")") {
                // 去掉前后的括号，例如: "recipe|article"
                let start = defComp.index(defComp.startIndex, offsetBy: 1)
                let end = defComp.index(defComp.endIndex, offsetBy: -1)
                let innerContent = String(defComp[start..<end])
                
                // 按 "|" 拆分出所有的可能选项
                let options = innerContent.components(separatedBy: "|")
                
                // 如果当前 url 的层级不包含在这些选项里，说明匹配失败
                if !options.contains(urlComp) {
                    return false
                }
                
                // 包含在选项中，则这一层匹配成功，继续下一层
                continue
            }
            
            // 规则 D: 普通字符串精确匹配
            if defComp != urlComp {
                return false
            }
        }
        
        // 4. 长度必须一致
        return defineComponents.count == urlComponents.count
    }
}
