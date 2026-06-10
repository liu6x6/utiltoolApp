import Foundation
import Network
import CryptoKit

struct WSOptions {
    var strategy: String // "on_connect" or "periodic"
    var interval: Double // seconds
    var dynamicBody: (() -> String)? // 用于每次发送时动态读取最新数据
}

/// 极其轻量级的原生本地 HTTP 服务器，现已支持 WebSocket
class SimpleHTTPServer {
    private var listener: NWListener?
    private let queue = DispatchQueue(label: "com.utiltoolapp.httpserver")
    private var connections: [NWConnection] = []
    private var wsTimers: [ObjectIdentifier: DispatchSourceTimer] = [:]
    
    // 路由处理器: (请求方法, 原始请求目标(保留 query/可能是完整 URL), Headers, Body) -> (状态码, 响应体, Content-Type, WSOptions?)
    var requestHandler: ((String, String, [String: String], String) -> (Int, String, String, WSOptions?))?
    
    func start(port: UInt16) throws {
        guard let nwPort = NWEndpoint.Port(rawValue: port) else {
            throw NSError(domain: "InvalidPort", code: 0, userInfo: nil)
        }
        
        listener = try NWListener(using: .tcp, on: nwPort)
        
        listener?.stateUpdateHandler = { state in
            print("Server state: \(state)")
        }
        
        listener?.newConnectionHandler = { [weak self] connection in
            self?.handleConnection(connection)
        }
        
        listener?.start(queue: queue)
    }
    
    func stop() {
        listener?.cancel()
        listener = nil
        
        for timer in wsTimers.values {
            timer.cancel()
        }
        wsTimers.removeAll()
        
        for connection in connections {
            connection.cancel()
        }
        connections.removeAll()
    }
    
    private func handleConnection(_ connection: NWConnection) {
        connections.append(connection)
        connection.start(queue: queue)
        receive(on: connection)
    }
    
    private func receive(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024 * 1024) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            
            if let data = data, !data.isEmpty {
                if let requestString = String(data: data, encoding: .utf8) {
                    self.processRequest(requestString, connection: connection)
                } else {
                    connection.cancel()
                    self.removeConnection(connection)
                }
            } else if isComplete || error != nil {
                connection.cancel()
                self.removeConnection(connection)
            } else {
                self.receive(on: connection)
            }
        }
    }
    
    private func processRequest(_ requestString: String, connection: NWConnection) {
        let components = requestString.components(separatedBy: "\r\n\r\n")
        let headString = components.first ?? ""
        let bodyString = components.count > 1 ? components.dropFirst().joined(separator: "\r\n\r\n") : ""
        
        let lines = headString.components(separatedBy: "\r\n")
        guard let firstLine = lines.first else {
            connection.cancel()
            removeConnection(connection)
            return
        }
        
        let parts = firstLine.components(separatedBy: " ")
        guard parts.count >= 2 else {
            connection.cancel()
            removeConnection(connection)
            return
        }
        
        let method = parts[0]
        let requestTarget = parts[1]
        
        // 解析 Headers
        var headers: [String: String] = [:]
        if lines.count > 1 {
            for line in lines.dropFirst() {
                let headerParts = line.components(separatedBy: ": ")
                if headerParts.count == 2 {
                    headers[headerParts[0]] = headerParts[1]
                } else if let firstColonIndex = line.firstIndex(of: ":") {
                    let key = String(line[..<firstColonIndex])
                    let value = String(line[line.index(after: firstColonIndex)...]).trimmingCharacters(in: .whitespaces)
                    headers[key] = value
                }
            }
        }
        
        // 默认 404
        var statusCode = 404
        var responseBody = "{\n  \"error\": \"Not Found\"\n}"
        var contentType = "application/json"
        var wsOptions: WSOptions? = nil
        
        if let handler = requestHandler {
            let result = handler(method, requestTarget, headers, bodyString)
            statusCode = result.0
            responseBody = result.1
            contentType = result.2
            wsOptions = result.3
        }
        
        if wsOptions != nil && statusCode == 101 {
            let clientKey = headers.first(where: { $0.key.lowercased() == "sec-websocket-key" })?.value ?? ""
            let magicString = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
            let hash = Insecure.SHA1.hash(data: (clientKey + magicString).data(using: .utf8)!)
            let acceptKey = Data(hash).base64EncodedString()
            
            let responseString = """
            HTTP/1.1 101 Switching Protocols\r
            Upgrade: websocket\r
            Connection: Upgrade\r
            Sec-WebSocket-Accept: \(acceptKey)\r
            \r\n
            """
            
            let responseData = responseString.data(using: .utf8)!
            
            connection.send(content: responseData, completion: .contentProcessed({ [weak self] error in
                guard let self = self else { return }
                if error == nil {
                    let connId = ObjectIdentifier(connection)
                    
                    if wsOptions?.strategy == "periodic" {
                        let interval = wsOptions?.interval ?? 5.0
                        let timer = DispatchSource.makeTimerSource(queue: self.queue)
                        timer.schedule(deadline: .now(), repeating: interval)
                        timer.setEventHandler { [weak self, weak connection] in
                            guard let self = self, let conn = connection else { return }
                            let msg = wsOptions?.dynamicBody?() ?? responseBody
                            self.sendWebSocketMessage(msg, on: conn)
                        }
                        self.wsTimers[connId] = timer
                        timer.resume()
                        
                        // 连接时也立刻发一次
                        let msg = wsOptions?.dynamicBody?() ?? responseBody
                        if !msg.isEmpty {
                            self.sendWebSocketMessage(msg, on: connection)
                        }
                    } else {
                        // 默认策略: 连接时发送固定消息
                        if !responseBody.isEmpty {
                            self.sendWebSocketMessage(responseBody, on: connection)
                        }
                    }
                    
                    self.receiveWSFrame(on: connection)
                } else {
                    connection.cancel()
                    self.removeConnection(connection)
                }
            }))
            return
        }
        
        let bodyData = responseBody.data(using: .utf8) ?? Data()
        
        // 构造标准的 HTTP 1.1 响应头
        let responseString = """
        HTTP/1.1 \(statusCode) OK\r
        Content-Type: \(contentType); charset=utf-8\r
        Content-Length: \(bodyData.count)\r
        Access-Control-Allow-Origin: *\r
        Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS\r
        Access-Control-Allow-Headers: *\r
        Connection: close\r
        \r\n
        """
        
        var responseData = responseString.data(using: .utf8)!
        responseData.append(bodyData)
        
        connection.send(content: responseData, completion: .contentProcessed({ [weak self] error in
            connection.cancel()
            if let self = self { self.removeConnection(connection) }
        }))
    }
    
    private func sendWebSocketMessage(_ message: String, on connection: NWConnection) {
        let messageData = message.data(using: .utf8) ?? Data()
        var frame = Data()
        frame.append(0x81) // FIN + Text Opcode
        
        let count = messageData.count
        if count < 126 {
            frame.append(UInt8(count))
        } else if count <= 65535 {
            frame.append(126)
            var length = UInt16(count).bigEndian
            withUnsafeBytes(of: &length) { frame.append(contentsOf: $0) }
        } else {
            frame.append(127)
            var length = UInt64(count).bigEndian
            withUnsafeBytes(of: &length) { frame.append(contentsOf: $0) }
        }
        frame.append(messageData)
        connection.send(content: frame, completion: .contentProcessed({ _ in }))
    }
    
    private func receiveWSFrame(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            if data != nil {
                // Mock API 暂不处理客户端的后续消息，仅保持长连接心跳存活
                self.receiveWSFrame(on: connection)
            } else if isComplete || error != nil {
                connection.cancel()
                self.removeConnection(connection)
            } else {
                self.receiveWSFrame(on: connection)
            }
        }
    }
    
    private func removeConnection(_ connection: NWConnection) {
        let connId = ObjectIdentifier(connection)
        wsTimers[connId]?.cancel()
        wsTimers.removeValue(forKey: connId)
        connections.removeAll { $0 === connection }
    }
}
