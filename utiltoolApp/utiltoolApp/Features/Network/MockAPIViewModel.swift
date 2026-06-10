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

private enum MockConfigLoadError: LocalizedError {
    case unsupportedFileType(String)
    case unreadableFile(String)
    case writeFailed
    case invalidTopLevel
    case missingEndpoints
    case invalidEndpoint(Int, String)
    case serializationFailed
    
    var errorDescription: String? {
        switch self {
        case .unsupportedFileType(let ext):
            return "暂不支持导入 \(ext.isEmpty ? "该类型" : ".\(ext)") 配置文件"
        case .unreadableFile(let message):
            return message
        case .writeFailed:
            return "保存配置文件失败"
        case .invalidTopLevel:
            return "配置文件顶层结构无效，需包含 endpoints"
        case .missingEndpoints:
            return "配置文件中未找到有效 endpoints"
        case .invalidEndpoint(let index, let reason):
            return "第 \(index) 条接口配置无效：\(reason)"
        case .serializationFailed:
            return "responseBody 序列化失败"
        }
    }
}

private struct ImportedMockConfiguration {
    var port: String?
    var endpoints: [MockEndpoint]
}

@Observable
class MockAPIViewModel {
    private enum StorageKey {
        static let endpoints = "MockEndpointsData"
        static let port = "MockEndpointsPort"
        static let configFilePath = "MockConfigFilePath"
    }
    
    var endpoints: [MockEndpoint] = []
    var isRunning: Bool = false
    var port: String = "8080"
    var errorMessage: String? = nil
    
    var configBaseDirectory: URL? = nil
    var lastConfigFileURL: URL? = nil
    
    var requestLogs: [MockRequestLog] = []
    var selectedLogId: UUID? = nil
    
    var selectedEndpointId: UUID? = nil {
        didSet {
            if let selected = endpoints.first(where: { $0.id == selectedEndpointId }) {
                editingEndpoint = refreshedEndpointFromFileIfAvailable(selected)
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
        if let data = UserDefaults.standard.data(forKey: StorageKey.endpoints),
           let decoded = try? JSONDecoder().decode([MockEndpoint].self, from: data) {
            endpoints = decoded
        } else {
            endpoints = [MockEndpoint()]
        }
        
        if let savedPort = UserDefaults.standard.string(forKey: StorageKey.port) {
            port = savedPort
        }
        
        if let savedConfigFilePath = UserDefaults.standard.string(forKey: StorageKey.configFilePath),
           !savedConfigFilePath.isEmpty {
            let configURL = URL(fileURLWithPath: savedConfigFilePath)
            lastConfigFileURL = configURL
            configBaseDirectory = configURL.deletingLastPathComponent()
        }
        
        selectedEndpointId = endpoints.first?.id
    }
    
    func save() {
        if let encoded = try? JSONEncoder().encode(endpoints) {
            UserDefaults.standard.set(encoded, forKey: StorageKey.endpoints)
        }
        UserDefaults.standard.set(port, forKey: StorageKey.port)
        if let lastConfigFileURL {
            UserDefaults.standard.set(lastConfigFileURL.path, forKey: StorageKey.configFilePath)
        } else {
            UserDefaults.standard.removeObject(forKey: StorageKey.configFilePath)
        }
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
        do {
            let imported = try parseConfig(from: url)
            DispatchQueue.main.async {
                self.applyImportedConfiguration(imported, from: url)
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func saveConfig(to url: URL) {
        do {
            let data = try makeExportedConfigData()
            try data.write(to: url, options: .atomic)
            
            configBaseDirectory = url.deletingLastPathComponent()
            lastConfigFileURL = url
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func clearLogs() {
        requestLogs.removeAll()
        selectedLogId = nil
    }
    
    func refreshedEndpointFromFileIfAvailable(_ endpoint: MockEndpoint) -> MockEndpoint {
        guard let fileBody = responseBodyFromConfiguredFile(for: endpoint) else {
            return endpoint
        }
        
        var refreshedEndpoint = endpoint
        refreshedEndpoint.responseBody = fileBody
        return refreshedEndpoint
    }
    
    func persistResponseBodyToFileIfAvailable(for endpoint: MockEndpoint, body: String) {
        guard let fileURL = existingResponseFileURL(for: endpoint) else {
            return
        }
        
        do {
            try body.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            errorMessage = "写入响应数据文件失败: \(fileURL.lastPathComponent)"
        }
    }
    
    func hasExistingResponseFile(for endpoint: MockEndpoint) -> Bool {
        existingResponseFileURL(for: endpoint) != nil
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
            server?.requestHandler = { [weak self] method, requestTarget, headers, body in
                guard let self = self else { return (500, "Internal Server Error", "text/plain", nil) }
                
                let isWSRequest = headers.contains(where: { $0.key.lowercased() == "upgrade" && $0.value.lowercased() == "websocket" })
                let effectiveMethod = isWSRequest ? "WS" : method
                
                let log = MockRequestLog(method: effectiveMethod, path: requestTarget, headers: headers, body: body, timestamp: Date())
                
                // 处理 CORS 预检请求 (OPTIONS)
                if method == "OPTIONS" {
                    self.appendLog(log, statusCode: 200)
                    return (200, "", "text/plain", nil)
                }
                
                // 精确匹配 Method 和 Path
                if let endpoint = self.endpoints.first(where: {
                    $0.isActive
                    && $0.method == effectiveMethod
                    && self.isPathOK(
                        definePath: $0.path,
                        requestTarget: requestTarget,
                        headers: headers,
                        isWebSocket: isWSRequest
                    )
                }) {
                    var responseBody = endpoint.responseBody
                    
                    let dynamicBodyClosure: () -> String = { [weak self] in
                        self?.responseBodyFromConfiguredFile(for: endpoint) ?? endpoint.responseBody
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
    
    func isPathOK(
        definePath: String,
        requestTarget: String,
        headers: [String: String] = [:],
        isWebSocket: Bool = false
    ) -> Bool {
        let normalizedDefinePath = definePath.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedRequestTarget = requestTarget.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !normalizedDefinePath.isEmpty, !normalizedRequestTarget.isEmpty else {
            return false
        }
        
        let hasExplicitQueryRule = queryDelimiterIndex(in: normalizedDefinePath) != nil
        let shouldTryRequestTargetMatching = hasExplicitQueryRule || isAbsoluteURLPattern(normalizedDefinePath)
        
        if shouldTryRequestTargetMatching {
            let patternCandidates = requestTargetMatchCandidates(
                for: normalizedDefinePath,
                headers: [:],
                isWebSocket: isWebSocket
            )
            let requestCandidates = requestTargetMatchCandidates(
                for: normalizedRequestTarget,
                headers: headers,
                isWebSocket: isWebSocket
            )
            
            for patternCandidate in patternCandidates {
                if patternCandidate == definePath {
                    return true
                }
                for requestCandidate in requestCandidates where matchesRequestTarget(pattern: patternCandidate, requestTarget: requestCandidate) {
                    return true
                }
            }
            
          
        }
        
        let definePathOnly = pathOnlyForMatching(from: normalizedDefinePath)
        let requestPathOnly = pathOnlyForMatching(from: normalizedRequestTarget)
        
        // 1. 如果完全相等，直接返回 true
        if definePathOnly == requestPathOnly {
            return true
        }
        
        // 2. 按 "/" 拆分成组件数组并过滤掉空值
        let defineComponents = definePathOnly.components(separatedBy: "/").filter { !$0.isEmpty }
        let urlComponents = requestPathOnly.components(separatedBy: "/").filter { !$0.isEmpty }
        
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
    
    private func isAbsoluteURLPattern(_ value: String) -> Bool {
        let normalizedValue = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalizedValue.hasPrefix("http://")
            || normalizedValue.hasPrefix("https://")
            || normalizedValue.hasPrefix("ws://")
            || normalizedValue.hasPrefix("wss://")
    }
    
    private func queryDelimiterIndex(in value: String) -> String.Index? {
        guard let questionMarkIndex = value.firstIndex(of: "?"), questionMarkIndex > value.startIndex else {
            return nil
        }
        
        let previousIndex = value.index(before: questionMarkIndex)
        return value[previousIndex] == "/" ? nil : questionMarkIndex
    }
    
    private func requestTargetMatchCandidates(
        for value: String,
        headers: [String: String],
        isWebSocket: Bool
    ) -> [String] {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else { return [] }
        
        var candidates: [String] = [trimmedValue]
        
        if let pathWithQuery = pathWithQueryForMatching(from: trimmedValue), pathWithQuery != trimmedValue {
            candidates.append(pathWithQuery)
        }
        
        if !isAbsoluteURLPattern(trimmedValue), let host = normalizedHost(from: headers) {
            let schemes = isWebSocket ? ["ws", "wss"] : ["http", "https"]
            for scheme in schemes {
                candidates.append("\(scheme)://\(host)\(trimmedValue)")
            }
        }
        
        return uniqueNonEmptyStrings(candidates)
    }
    
    private func pathWithQueryForMatching(from value: String) -> String? {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else { return nil }
        
        if isAbsoluteURLPattern(trimmedValue),
           let components = URLComponents(string: trimmedValue) {
            let path = components.path.isEmpty ? "/" : components.path
            if let query = components.percentEncodedQuery, !query.isEmpty {
                return "\(path)?\(query)"
            }
            if queryDelimiterIndex(in: trimmedValue) != nil {
                return "\(path)?"
            }
            return path
        }
        
        return trimmedValue
    }
    
    private func pathOnlyForMatching(from value: String) -> String {
        let candidate = pathWithQueryForMatching(from: value) ?? value
        return candidate.components(separatedBy: "?").first ?? candidate
    }
    
    private func normalizedHost(from headers: [String: String]) -> String? {
        headers.first(where: { $0.key.caseInsensitiveCompare("Host") == .orderedSame })?
            .value
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func matchesRequestTarget(pattern: String, requestTarget: String) -> Bool {
        if pattern == requestTarget {
            return true
        }
        
        if let prefix = requestTargetPrefixPattern(from: pattern) {
            return requestTarget.hasPrefix(prefix)
        }
        
        return false
    }
    
    private func requestTargetPrefixPattern(from pattern: String) -> String? {
        guard !pattern.isEmpty else { return nil }
        
        if pattern.hasSuffix("*") {
            return String(pattern.dropLast())
        }
        
        if pattern.hasSuffix("&") {
            return pattern
        }
        
        guard pattern.hasSuffix("?"), pattern.count > 1 else {
            return nil
        }
        
        let previousIndex = pattern.index(before: pattern.endIndex)
        let beforeQuestionMark = pattern.index(before: previousIndex)
        return pattern[beforeQuestionMark] == "/" ? nil : pattern
    }
    
    private func uniqueNonEmptyStrings(_ values: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        
        for value in values {
            guard !value.isEmpty, seen.insert(value).inserted else {
                continue
            }
            result.append(value)
        }
        
        return result
    }
    
    private func applyImportedConfiguration(_ imported: ImportedMockConfiguration, from url: URL) {
        configBaseDirectory = url.deletingLastPathComponent()
        lastConfigFileURL = url
        
        if let importedPort = imported.port, !importedPort.isEmpty {
            port = importedPort
        }
        
        endpoints = imported.endpoints
        selectedEndpointId = imported.endpoints.first?.id
        save()
        errorMessage = nil
    }
    
    private func parseConfig(from url: URL) throws -> ImportedMockConfiguration {
        switch url.pathExtension.lowercased() {
        case "json":
            return try parseJSONConfig(from: url)
        case "yaml", "yml":
            return try parseYAMLConfig(from: url)
        default:
            throw MockConfigLoadError.unsupportedFileType(url.pathExtension.lowercased())
        }
    }
    
    private func parseJSONConfig(from url: URL) throws -> ImportedMockConfiguration {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw MockConfigLoadError.unreadableFile("读取 JSON 失败")
        }
        
        let rawObject: Any
        do {
            rawObject = try JSONSerialization.jsonObject(with: data)
        } catch {
            throw MockConfigLoadError.unreadableFile("JSON 配置解析失败")
        }
        
        guard let root = rawObject as? [String: Any] else {
            throw MockConfigLoadError.invalidTopLevel
        }
        
        let port = extractPort(from: root)
        guard let rawEndpoints = root["endpoints"] as? [[String: Any]] else {
            throw MockConfigLoadError.missingEndpoints
        }
        
        let baseDirectory = url.deletingLastPathComponent()
        let endpoints = try rawEndpoints.enumerated().map { offset, raw in
            try makeEndpoint(from: raw, index: offset + 1, baseDirectory: baseDirectory)
        }
        
        return ImportedMockConfiguration(port: port, endpoints: endpoints)
    }
    
    private func parseYAMLConfig(from url: URL) throws -> ImportedMockConfiguration {
        let yamlString: String
        do {
            yamlString = try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw MockConfigLoadError.unreadableFile("读取 YAML 失败")
        }
        
        let parsed = SimpleYAMLParser.parse(yaml: yamlString)
        let port = extractPort(from: parsed)
        
        guard let rawEndpoints = parsed["endpoints"] as? [[String: Any]] else {
            throw MockConfigLoadError.missingEndpoints
        }
        
        let baseDirectory = url.deletingLastPathComponent()
        let endpoints = try rawEndpoints.enumerated().map { offset, raw in
            try makeEndpoint(from: raw, index: offset + 1, baseDirectory: baseDirectory)
        }
        
        return ImportedMockConfiguration(port: port, endpoints: endpoints)
    }
    
    private func extractPort(from root: [String: Any]) -> String? {
        if let serverDict = root["server"] as? [String: Any],
           let port = stringValue(from: serverDict["port"]) {
            return port
        }
        
        if let serverList = root["server"] as? [[String: Any]],
           let port = stringValue(from: serverList.first?["port"]) {
            return port
        }
        
        return stringValue(from: root["port"])
    }
    
    private func makeEndpoint(from raw: [String: Any], index: Int, baseDirectory: URL) throws -> MockEndpoint {
        let path = (stringValue(from: raw["path"]) ?? stringValue(from: raw["url"]) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !path.isEmpty else {
            throw MockConfigLoadError.invalidEndpoint(index, "缺少 path/url")
        }
        guard path.hasPrefix("/") || isAbsoluteURLPattern(path) else {
            throw MockConfigLoadError.invalidEndpoint(index, "path 必须以 / 开头，或使用完整的 http/https/ws/wss URL")
        }
        
        var endpoint = MockEndpoint(path: path)
        
        if let method = stringValue(from: raw["method"])?.trimmingCharacters(in: .whitespacesAndNewlines),
           !method.isEmpty {
            endpoint.method = method.uppercased()
        }
        
        if let statusCode = intValue(from: raw["statusCode"]) {
            endpoint.statusCode = statusCode
        }
        
        if let contentType = stringValue(from: raw["contentType"])?.trimmingCharacters(in: .whitespacesAndNewlines),
           !contentType.isEmpty {
            endpoint.contentType = contentType
        }
        
        if let isActive = boolValue(from: raw["isActive"]) {
            endpoint.isActive = isActive
        }
        
        if let wsStrategy = stringValue(from: raw["wsStrategy"])?.trimmingCharacters(in: .whitespacesAndNewlines),
           !wsStrategy.isEmpty {
            endpoint.wsStrategy = wsStrategy
        }
        
        if let wsInterval = doubleValue(from: raw["wsInterval"]) {
            endpoint.wsInterval = wsInterval
        }
        
        let rawResponseBody = raw["responseBody"] ?? raw["body"]
        if let rawResponseBody {
            endpoint.responseBody = try stringifyResponseBody(rawResponseBody, index: index)
        }
        
        if let responseFile = (stringValue(from: raw["responseFile"]) ?? stringValue(from: raw["bodyFile"]))?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !responseFile.isEmpty {
            endpoint.responseFilePath = responseFile
            if let preloadedBody = preloadResponseBody(from: responseFile, baseDirectory: baseDirectory) {
                endpoint.responseBody = preloadedBody
            } else if rawResponseBody == nil {
                endpoint.responseBody = "{\n  \"error\": \"Missing file: \(responseFile)\"\n}"
            }
        }
        
        return endpoint
    }
    
    private func preloadResponseBody(from relativePath: String, baseDirectory: URL) -> String? {
        let fileURL = baseDirectory.appendingPathComponent(relativePath)
        guard let data = try? Data(contentsOf: fileURL),
              let content = String(data: data, encoding: .utf8) else {
            return nil
        }
        return content
    }
    
    private func responseBodyFromConfiguredFile(for endpoint: MockEndpoint) -> String? {
        guard let fileURL = existingResponseFileURL(for: endpoint) else {
            return nil
        }
        
        guard let data = try? Data(contentsOf: fileURL),
              let content = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return content
    }
    
    private func existingResponseFileURL(for endpoint: MockEndpoint) -> URL? {
        guard let trimmedPath = endpoint.responseFilePath?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !trimmedPath.isEmpty,
            let baseDirectory = configBaseDirectory else {
            return nil
        }
        
        let fileURL = baseDirectory.appendingPathComponent(trimmedPath)
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDirectory),
              !isDirectory.boolValue else {
            return nil
        }
        
        return fileURL
    }
    
    private func makeExportedConfigData() throws -> Data {
        let exportedPort: Any = Int(port) ?? port
        let exportedEndpoints = try endpoints.map { try makeExportedEndpoint(from: $0) }
        let payload: [String: Any] = [
            "server": ["port": exportedPort],
            "endpoints": exportedEndpoints
        ]
        
        do {
            return try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
        } catch {
            throw MockConfigLoadError.writeFailed
        }
    }
    
    private func makeExportedEndpoint(from endpoint: MockEndpoint) throws -> [String: Any] {
        var exported: [String: Any] = [
            "method": endpoint.method,
            "path": endpoint.path,
            "statusCode": endpoint.statusCode,
            "contentType": endpoint.contentType,
            "isActive": endpoint.isActive
        ]
        
        if endpoint.method == "WS" {
            exported["wsStrategy"] = endpoint.wsStrategy
            exported["wsInterval"] = endpoint.wsInterval
        }
        
        if let responseFilePath = endpoint.responseFilePath?.trimmingCharacters(in: .whitespacesAndNewlines),
           !responseFilePath.isEmpty {
            exported["responseFile"] = responseFilePath
        } else {
            exported["responseBody"] = exportedResponseBody(from: endpoint)
        }
        
        return exported
    }
    
    private func exportedResponseBody(from endpoint: MockEndpoint) -> Any {
        let trimmedBody = endpoint.responseBody.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedBody.isEmpty else {
            return ""
        }
        
        if endpoint.contentType.lowercased().contains("json"),
           let data = trimmedBody.data(using: .utf8),
           let jsonObject = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) {
            return jsonObject
        }
        
        return endpoint.responseBody
    }
    
    private func stringifyResponseBody(_ value: Any, index: Int) throws -> String {
        if let string = value as? String {
            return string
        }
        
        if value is NSNull {
            return "null"
        }
        
        if let number = value as? NSNumber {
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return number.boolValue ? "true" : "false"
            }
            return number.stringValue
        }
        
        guard JSONSerialization.isValidJSONObject(value) else {
            throw MockConfigLoadError.invalidEndpoint(index, "responseBody 类型不支持")
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys])
            guard let result = String(data: data, encoding: .utf8) else {
                throw MockConfigLoadError.serializationFailed
            }
            return result
        } catch let error as MockConfigLoadError {
            throw error
        } catch {
            throw MockConfigLoadError.serializationFailed
        }
    }
    
    private func stringValue(from value: Any?) -> String? {
        switch value {
        case let string as String:
            return string
        case let int as Int:
            return String(int)
        case let double as Double:
            return String(double)
        case let number as NSNumber:
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return number.boolValue ? "true" : "false"
            }
            return number.stringValue
        default:
            return nil
        }
    }
    
    private func intValue(from value: Any?) -> Int? {
        switch value {
        case let int as Int:
            return int
        case let string as String:
            return Int(string.trimmingCharacters(in: .whitespacesAndNewlines))
        case let number as NSNumber:
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return nil
            }
            return number.intValue
        default:
            return nil
        }
    }
    
    private func doubleValue(from value: Any?) -> Double? {
        switch value {
        case let double as Double:
            return double
        case let int as Int:
            return Double(int)
        case let string as String:
            return Double(string.trimmingCharacters(in: .whitespacesAndNewlines))
        case let number as NSNumber:
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return nil
            }
            return number.doubleValue
        default:
            return nil
        }
    }
    
    private func boolValue(from value: Any?) -> Bool? {
        switch value {
        case let bool as Bool:
            return bool
        case let number as NSNumber:
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return number.boolValue
            }
            return nil
        case let string as String:
            switch string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "true", "1", "yes", "y":
                return true
            case "false", "0", "no", "n":
                return false
            default:
                return nil
            }
        default:
            return nil
        }
    }
}
