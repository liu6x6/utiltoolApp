import SwiftUI

struct MockServerWorkspaceView: View {
    @Environment(MockAPIViewModel.self) private var viewModel
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部服务器控制栏
            HStack(spacing: 20) {
                // 状态指示灯
                Circle()
                    .fill(viewModel.isRunning ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                    .shadow(color: viewModel.isRunning ? .green.opacity(0.5) : .clear, radius: 4)
                
                Text(viewModel.isRunning ? "服务器运行中" : "服务器已停止")
                    .font(.headline)
                    .foregroundColor(viewModel.isRunning ? .primary : .secondary)
                
                Divider().frame(height: 20)
                
                Text("本地端口:")
                TextField("8080", text: Bindable(viewModel).port)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                    .disabled(viewModel.isRunning) // 运行中禁止修改端口
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Spacer()
                
                Button(action: {
                    selectConfigFile()
                }) {
                    HStack {
                        Image(systemName: "folder.badge.plus")
                        Text("导入配置 (YAML)")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isRunning)
                
                Button(action: {
                    openWindow(id: "mock-api-logs")
                }) {
                    HStack {
                        Image(systemName: "doc.text.magnifyingglass")
                        Text("请求日志")
                    }
                }
                .buttonStyle(.bordered)
                
                Button(action: { viewModel.toggleServer() }) {
                    HStack {
                        Image(systemName: viewModel.isRunning ? "stop.fill" : "play.fill")
                        Text(viewModel.isRunning ? "停止服务" : "启动服务")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(viewModel.isRunning ? .red : .accentColor)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // 主体：TabView 作为多标签工作区
            if viewModel.endpoints.isEmpty {
                VStack {
                    Image(systemName: "server.rack")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("尚未配置任何接口，请点击右上角添加或导入配置")
                        .foregroundColor(.secondary)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                TabView(selection: Bindable(viewModel).selectedEndpointId) {
                    ForEach(Bindable(viewModel).endpoints) { $endpoint in
                        MockEndpointEditor(
                            endpoint: $endpoint,
                            isServerRunning: viewModel.isRunning,
                            port: viewModel.port,
                            onClose: {
                                viewModel.removeEndpoint(id: endpoint.id)
                            }
                        )
                            .tabItem {
                                Text("\(endpoint.method) \(endpoint.path.isEmpty ? "New" : endpoint.path)")
                            }
                            .tag(endpoint.id as UUID?)
                    }
                }
                .padding(.top, 8)
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: { viewModel.addEndpoint() }) {
                    Label("新建接口标签", systemImage: "plus")
                }
            }
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    if let selectedId = viewModel.selectedEndpointId {
                        viewModel.removeEndpoint(id: selectedId)
                    }
                }) {
                    Label("移除当前接口", systemImage: "minus")
                }
                .disabled(viewModel.selectedEndpointId == nil)
            }
        }
    }
    
    private func selectConfigFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.message = "请选择 YAML 配置文件 (或其所在的文件夹以获取读取响应 JSON 的权限)"
        
        if panel.runModal() == .OK, let url = panel.url {
            var configURL = url
            
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue {
                let yaml = url.appendingPathComponent("mock.yaml")
                let yml = url.appendingPathComponent("mock.yml")
                if FileManager.default.fileExists(atPath: yaml.path) {
                    configURL = yaml
                } else if FileManager.default.fileExists(atPath: yml.path) {
                    configURL = yml
                }
            }
            
            viewModel.loadConfig(from: configURL)
        }
    }
}

struct MockEndpointEditor: View {
    @Binding var endpoint: MockEndpoint
    var isServerRunning: Bool
    var port: String
    var onClose: () -> Void
    
    let availableMethods = ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS", "WS"]
    let availableContentTypes = ["application/json", "text/plain", "text/html", "application/xml"]
    let wsStrategies = ["on_connect", "periodic"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 开关和基础配置
            HStack(spacing: 12) {
                Toggle("启用此接口", isOn: $endpoint.isActive)
                    .toggleStyle(.switch)
                
                Spacer()
                
                if isServerRunning {
                    let proto = endpoint.method == "WS" ? "ws" : "http"
                    Button(action: {
                        let urlStr = "\(proto)://127.0.0.1:\(port)\(endpoint.path)"
                        if let url = URL(string: urlStr) {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        Label("浏览器预览", systemImage: "safari")
                    }
                    .buttonStyle(.link)
                }
                
                // 关闭按钮 (x)
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary.opacity(0.8))
                }
                .buttonStyle(.plain)
                .help("关闭此标签")
            }
            
            Divider()
            
            // 路由配置
            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Method").font(.caption).foregroundColor(.secondary)
                    Picker("", selection: $endpoint.method) {
                        ForEach(availableMethods, id: \.self) { method in
                            Text(method).tag(method)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 100)
                }
                
                VStack(alignment: .leading) {
                    Text("Path (必须以 / 开头)").font(.caption).foregroundColor(.secondary)
                    TextField("/api/user", text: $endpoint.path)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                }
                
                VStack(alignment: .leading) {
                    Text("响应数据文件 (相对路径)").font(.caption).foregroundColor(.secondary)
                    TextField("如: data.json (可选)", text: Binding(
                        get: { endpoint.responseFilePath ?? "" },
                        set: { endpoint.responseFilePath = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                }
            }
            
            // WS / HTTP 特定配置
            if endpoint.method == "WS" {
                HStack(spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("WebSocket 策略").font(.caption).foregroundColor(.secondary)
                        Picker("", selection: $endpoint.wsStrategy) {
                            Text("仅连接时发送一次").tag("on_connect")
                            Text("定时循环推送 (心跳/行情)").tag("periodic")
                        }
                        .labelsHidden()
                        .frame(width: 200)
                    }
                    
                    if endpoint.wsStrategy == "periodic" {
                        VStack(alignment: .leading) {
                            Text("推送间隔 (秒)").font(.caption).foregroundColor(.secondary)
                            TextField("5.0", value: $endpoint.wsInterval, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                        }
                    }
                }
            } else {
                HStack(spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("状态码 (Status Code)").font(.caption).foregroundColor(.secondary)
                        TextField("200", value: $endpoint.statusCode, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Content-Type").font(.caption).foregroundColor(.secondary)
                        Picker("", selection: $endpoint.contentType) {
                            ForEach(availableContentTypes, id: \.self) { type in
                                Text(type).tag(type)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 200)
                    }
                }
            }
            
            // 响应体编辑
            VStack(alignment: .leading, spacing: 8) {
                Text(endpoint.method == "WS" ? "推送内容 (Message Body)" : "响应体 (Response Body)")
                    .font(.headline)
                
                if endpoint.responseFilePath != nil {
                    Text("💡 当前已配置了外部响应数据文件，这里显示的可能是默认文本或预加载内容，实际请求会尝试热读取文件内容。")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                TextEditor(text: $endpoint.responseBody)
                    .font(.system(.body, design: .monospaced))
                    .padding(4)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
