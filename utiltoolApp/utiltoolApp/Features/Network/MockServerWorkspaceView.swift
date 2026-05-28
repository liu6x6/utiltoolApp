import SwiftUI
import UniformTypeIdentifiers

struct MockServerWorkspaceView: View {
    @Environment(MockAPIViewModel.self) private var viewModel
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        VStack(spacing: 0) {
            controlBar
            Divider()
            
            if viewModel.endpoints.isEmpty {
                emptyStateView
            } else {
                HSplitView {
                    endpointListPane
                    endpointDetailPane
                }
            }
        }
        .onDeleteCommand(perform: deleteSelectedEndpoint)
    }
    
    private var controlBar: some View {
        HStack(spacing: 20) {
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
                .disabled(viewModel.isRunning)
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button(action: {
                selectConfigFile()
            }) {
                HStack {
                    Image(systemName: "folder.badge.plus")
                    Text("导入配置")
                }
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isRunning)
            .help("支持 mock.json、mock.yaml、mock.yml，或直接选择具体配置文件")
            
            Button(action: {
                saveConfigFile()
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("保存配置")
                }
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.endpoints.isEmpty)
            .help("将当前手动配置的 URL 与响应内容导出为 JSON 配置文件")
            
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
    }
    
    private var emptyStateView: some View {
        VStack {
            Image(systemName: "server.rack")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))
            Text("尚未配置任何 mock 规则，请点击右上角添加或导入配置")
                .foregroundColor(.secondary)
                .padding(.top, 8)
            Text("支持直接导入 JSON 列表配置文件")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var endpointListPane: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Mock 列表")
                    .font(.headline)
                
                Button(action: addEndpoint) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .help("新建接口")
                
                Button(action: deleteSelectedEndpoint) {
                    Image(systemName: "minus")
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.selectedEndpointId == nil)
                .help("删除当前选中接口")
                
                Spacer()
                
                Text("\(viewModel.endpoints.count) 条")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(NSColor.controlBackgroundColor))
            
            List(selection: Bindable(viewModel).selectedEndpointId) {
                ForEach(viewModel.endpoints) { endpoint in
                    MockEndpointListRow(endpoint: endpoint)
                        .tag(endpoint.id as UUID?)
                        .contextMenu {
                            Button(role: .destructive) {
                                deleteEndpoint(endpoint.id)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                }
            }
            .listStyle(.sidebar)
        }
        .frame(minWidth: 260, idealWidth: 300, maxWidth: 360)
    }
    
    @ViewBuilder
    private var endpointDetailPane: some View {
        if let binding = selectedEndpointBinding {
            MockEndpointEditor(
                endpoint: binding,
                isServerRunning: viewModel.isRunning,
                port: viewModel.port,
                onClose: {
                    let closingId = binding.wrappedValue.id
                    viewModel.removeEndpoint(id: closingId)
                }
            )
        } else {
            VStack {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 54))
                    .foregroundColor(.secondary.opacity(0.5))
                Text("请在左侧选择一条 mock 规则")
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private var selectedEndpointBinding: Binding<MockEndpoint>? {
        guard let selectedId = viewModel.selectedEndpointId,
              let selectedIndex = viewModel.endpoints.firstIndex(where: { $0.id == selectedId }) else {
            return nil
        }
        
        return Binding(
            get: { viewModel.endpoints[selectedIndex] },
            set: { updated in
                viewModel.endpoints[selectedIndex] = updated
                viewModel.save()
            }
        )
    }
    
    private func selectConfigFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowedContentTypes = [
            UTType.json,
            UTType(filenameExtension: "yaml"),
            UTType(filenameExtension: "yml")
        ].compactMap { $0 }
        panel.message = "请选择 JSON/YAML 配置文件，或直接选择包含 mock.json/mock.yaml/mock.yml 的文件夹"
        
        if panel.runModal() == .OK, let url = panel.url {
            var configURL = url
            
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue {
                if let discoveredConfig = preferredConfigFile(in: url) {
                    configURL = discoveredConfig
                } else {
                    viewModel.errorMessage = "目录中未找到 mock.json / mock.yaml / mock.yml"
                    return
                }
            }
            
            viewModel.loadConfig(from: configURL)
        }
    }
    
    private func saveConfigFile() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.json]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = viewModel.lastConfigFileURL?.lastPathComponent ?? "mock.json"
        panel.directoryURL = viewModel.lastConfigFileURL?.deletingLastPathComponent()
        
        if panel.runModal() == .OK, let url = panel.url {
            let targetURL = url.pathExtension.lowercased() == "json" ? url : url.appendingPathExtension("json")
            viewModel.saveConfig(to: targetURL)
        }
    }
    
    private func preferredConfigFile(in directory: URL) -> URL? {
        let candidates = ["mock.json", "mock.yaml", "mock.yml"]
        return candidates
            .map { directory.appendingPathComponent($0) }
            .first(where: { FileManager.default.fileExists(atPath: $0.path) })
    }
    
    private func addEndpoint() {
        viewModel.addEndpoint()
    }
    
    private func deleteSelectedEndpoint() {
        guard let selectedId = viewModel.selectedEndpointId else { return }
        deleteEndpoint(selectedId)
    }
    
    private func deleteEndpoint(_ id: UUID) {
        viewModel.selectedEndpointId = id
        viewModel.removeEndpoint(id: id)
    }
}

private struct MockEndpointListRow: View {
    let endpoint: MockEndpoint
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(endpoint.method)
                    .font(.caption.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(methodColor.opacity(0.15))
                    .foregroundColor(methodColor)
                    .clipShape(Capsule())
                
                if !endpoint.isActive {
                    Label("禁用", systemImage: "pause.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Text(endpoint.path.isEmpty ? "未配置路径" : endpoint.path)
                .font(.system(.body, design: .monospaced))
                .lineLimit(1)
            
            if let responseFile = endpoint.responseFilePath, !responseFile.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "doc.text")
                    Text(responseFile)
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var methodColor: Color {
        switch endpoint.method {
        case "GET": return .blue
        case "POST": return .green
        case "PUT", "PATCH": return .orange
        case "DELETE": return .red
        case "WS": return .purple
        default: return .secondary
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
                
                if isServerRunning, let previewURLString {
                    Button(action: {
                        if let url = URL(string: previewURLString) {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        Label("浏览器预览", systemImage: "safari")
                    }
                    .buttonStyle(.link)
                    
                    if endpoint.method != "WS", let curlCommand {
                        Button(action: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(curlCommand, forType: .string)
                        }) {
                            Label("Copy cURL", systemImage: "document.on.document")
                        }
                        .buttonStyle(.link)
                    }
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
    
    private var previewURLString: String? {
        let proto = endpoint.method == "WS" ? "ws" : "http"
        let resolvedPath = resolvedPreviewPath(from: endpoint.path)
        return "\(proto)://127.0.0.1:\(port)\(resolvedPath)"
    }
    
    private var curlCommand: String? {
        guard endpoint.method != "WS" else { return nil }
        guard let previewURLString else { return nil }
        
        var components = ["curl", "-i", "-X", endpoint.method]
        
        if endpoint.method != "GET", !endpoint.contentType.isEmpty {
            components.append("-H")
            components.append(shellQuoted("Content-Type: \(endpoint.contentType)"))
        }
        
        components.append(shellQuoted(previewURLString))
        return components.joined(separator: " ")
    }
    
    private func resolvedPreviewPath(from pattern: String) -> String {
        let trimmedPattern = pattern.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPattern.isEmpty, trimmedPattern != "/" else { return "/" }
        
        let components = trimmedPattern
            .split(separator: "/", omittingEmptySubsequences: true)
            .map(String.init)
            .map(resolvePathComponent)
        
        if components.isEmpty {
            return "/"
        }
        
        return "/" + components.joined(separator: "/")
    }
    
    private func resolvePathComponent(_ component: String) -> String {
        if component == "*" || component == "?" {
            return "sample"
        }
        
        if component.hasPrefix("("), component.hasSuffix(")") {
            let start = component.index(after: component.startIndex)
            let end = component.index(before: component.endIndex)
            let options = component[start..<end]
                .split(separator: "|")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            return options.first ?? "sample"
        }
        
        return component
    }
    
    private func shellQuoted(_ text: String) -> String {
        "'\(text.replacingOccurrences(of: "'", with: "'\\''"))'"
    }
}
