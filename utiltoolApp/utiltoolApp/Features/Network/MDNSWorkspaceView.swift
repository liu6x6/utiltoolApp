import SwiftUI

struct MDNSWorkspaceView: View {
    @State private var viewModel = MDNSViewModel()
    @State private var selectedTab: Int = 0 // 0: Scanner, 1: Publisher
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                Text("作为客户端扫描服务 (Browser)").tag(0)
                Text("作为服务端广播 (Publisher)").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            if selectedTab == 0 {
                scannerView
            } else {
                publisherView
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
    
    // MARK: - Scanner View
    @State private var radarScale: CGFloat = 0.5
    @State private var radarOpacity: Double = 1.0
    
    private var scannerView: some View {
        HStack(spacing: 0) {
            // Left: Device/Service List
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    HStack {
                        Text("服务类型").font(.caption).foregroundColor(.secondary)
                        TextField("空表示扫描全网所有类型", text: $viewModel.scanType)
                            .textFieldStyle(.roundedBorder)
                            .disabled(viewModel.isScanning)
                    }
                    
                    HStack {
                        Text("搜索域").font(.caption).foregroundColor(.secondary)
                        TextField("空表示扫描所有域 (包含本机)", text: $viewModel.scanDomain)
                            .textFieldStyle(.roundedBorder)
                            .disabled(viewModel.isScanning)
                    }
                    
                    Button(action: {
                        viewModel.toggleScan()
                        if viewModel.isScanning {
                            startRadarAnimation()
                        }
                    }) {
                        HStack {
                            if viewModel.isScanning {
                                // Radar animation icon
                                ZStack {
                                    Circle()
                                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                        .frame(width: 14, height: 14)
                                        .scaleEffect(radarScale)
                                        .opacity(radarOpacity)
                                    
                                    Image(systemName: "antenna.radiowaves.left.and.right")
                                }
                            } else {
                                Image(systemName: "magnifyingglass")
                            }
                            Text(viewModel.isScanning ? "停止扫描" : "开始扫描附近服务")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(viewModel.isScanning ? .red : .accentColor)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                if viewModel.isScanning && viewModel.discoveredServices.isEmpty {
                    VStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .stroke(Color.accentColor.opacity(0.3), lineWidth: 2)
                                .frame(width: 80, height: 80)
                                .scaleEffect(radarScale * 2)
                                .opacity(radarOpacity)
                            
                            Image(systemName: "bonjour")
                                .font(.system(size: 40))
                                .foregroundColor(.accentColor)
                        }
                        .padding(.bottom, 16)
                        
                        Text("正在搜索局域网中的 mDNS 服务...")
                            .font(.callout)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(selection: $viewModel.selectedServiceId) {
                        ForEach(viewModel.discoveredServices) { svc in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(svc.service.name).font(.headline)
                                    Text(svc.service.type).font(.caption2).foregroundColor(.secondary)
                                }
                                Spacer()
                                if svc.isResolved {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                                } else if svc.resolveError != nil {
                                    Image(systemName: "exclamationmark.circle.fill").foregroundColor(.red)
                                } else {
                                    ProgressView().controlSize(.small)
                                }
                            }
                            .tag(svc.id as UUID?)
                        }
                    }
                    .listStyle(.sidebar)
                }
            }
            .frame(width: 300)
            
            Divider()
            
            // Right: Connected Service details
            if let selectedId = viewModel.selectedServiceId,
               let svc = viewModel.discoveredServices.first(where: { $0.id == selectedId }) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("服务详情")
                        .font(.title2.bold())
                    
                    Divider()
                    
                    Group {
                        detailRow(title: "服务名称", value: svc.service.name)
                        detailRow(title: "服务类型", value: svc.service.type)
                        detailRow(title: "所在域", value: svc.service.domain)
                    }
                    
                    Divider()
                    
                    if svc.isResolved {
                        detailRow(title: "目标主机名", value: svc.service.hostName ?? "Unknown")
                        detailRow(title: "端口号", value: "\(svc.service.port)")
                        
                        Text("解析 IP 地址")
                            .font(.headline)
                            .padding(.top, 8)
                        if svc.ipAddresses.isEmpty {
                            Text("无")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(svc.ipAddresses, id: \.self) { ip in
                                Text(ip).font(.system(.body, design: .monospaced))
                            }
                        }
                        
                        Divider()
                        
                        Text("TXT 记录 (配置参数)")
                            .font(.headline)
                            .padding(.top, 8)
                        
                        if svc.txtRecords.isEmpty {
                            Text("未携带任何 TXT 记录")
                                .foregroundColor(.secondary)
                        } else {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(Array(svc.txtRecords.keys.sorted()), id: \.self) { key in
                                        HStack(alignment: .top) {
                                            Text(key + ":").bold()
                                            Text(svc.txtRecords[key] ?? "")
                                        }
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(NSColor.textBackgroundColor))
                                .cornerRadius(6)
                            }
                        }
                    } else if let error = svc.resolveError {
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 40))
                                .foregroundColor(.red)
                            Text("解析失败")
                                .font(.headline)
                                .padding(.top, 4)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.bottom, 8)
                            Button("重试解析") {
                                viewModel.resolveService(id: selectedId)
                            }
                            .buttonStyle(.bordered)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        VStack {
                            ProgressView()
                            Text("正在尝试解析服务目标地址和 TXT 记录...")
                                .foregroundColor(.secondary)
                                .padding()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    
                    Spacer()
                }
                .padding()
                .onAppear {
                    if !svc.isResolved && svc.resolveError == nil {
                        viewModel.resolveService(id: selectedId)
                    }
                }
                .onChange(of: selectedId) { oldId, newId in
                    let newSvc = viewModel.discoveredServices.first(where: { $0.id == newId })
                    if let newSvc = newSvc {
                        if !newSvc.isResolved && newSvc.resolveError == nil {
                            viewModel.resolveService(id: newId)
                        }
                    }
                }
            } else {
                VStack {
                    Image(systemName: "bonjour")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("请在左侧选择一个发现的服务以查看参数详情")
                        .foregroundColor(.secondary)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    // MARK: - Publisher View
    private var publisherView: some View {
        HStack(spacing: 0) {
            // Left: Config
            VStack(alignment: .leading, spacing: 16) {
                Text("广播配置")
                    .font(.headline)
                
                VStack(alignment: .leading) {
                    Text("服务名称 (Service Name)").font(.caption).foregroundColor(.secondary)
                    TextField("MyCustomService", text: $viewModel.pubName)
                        .textFieldStyle(.roundedBorder)
                        .disabled(viewModel.isPublishing)
                }
                
                VStack(alignment: .leading) {
                    Text("服务类型 (Service Type)").font(.caption).foregroundColor(.secondary)
                    TextField("_http._tcp.", text: $viewModel.pubType)
                        .textFieldStyle(.roundedBorder)
                        .disabled(viewModel.isPublishing)
                }
                
                VStack(alignment: .leading) {
                    Text("服务端口 (Port)").font(.caption).foregroundColor(.secondary)
                    TextField("8080", text: $viewModel.pubPort)
                        .textFieldStyle(.roundedBorder)
                        .disabled(viewModel.isPublishing)
                }
                
                HStack {
                    Text("TXT 记录配置").font(.caption).foregroundColor(.secondary)
                    Spacer()
                    Button(action: { viewModel.addTxtRecord() }) {
                        Image(systemName: "plus.circle")
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isPublishing)
                }
                
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach($viewModel.pubTxtRecords) { $record in
                            HStack {
                                TextField("Key", text: $record.key)
                                    .textFieldStyle(.roundedBorder)
                                TextField("Value", text: $record.value)
                                    .textFieldStyle(.roundedBorder)
                                Button(action: { viewModel.removeTxtRecord(id: record.id) }) {
                                    Image(systemName: "minus.circle.fill").foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                            .disabled(viewModel.isPublishing)
                        }
                    }
                }
                .frame(height: 150)
                
                Button(action: { viewModel.togglePublish() }) {
                    HStack {
                        Image(systemName: viewModel.isPublishing ? "stop.fill" : "play.fill")
                        Text(viewModel.isPublishing ? "停止广播" : "开始广播服务")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(viewModel.isPublishing ? .red : .accentColor)
                .padding(.top, 10)
                
                Spacer()
            }
            .padding()
            .frame(width: 350)
            
            Divider()
            
            // Right: Logs
            VStack(alignment: .leading, spacing: 0) {
                Text("服务广播日志")
                    .font(.headline)
                    .padding()
                
                Divider()
                
                List(viewModel.pubLogs, id: \.self) { log in
                    Text(log)
                        .font(.system(.caption, design: .monospaced))
                        .padding(.vertical, 2)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            Text(value)
                .bold()
        }
    }
    
    private func startRadarAnimation() {
        radarScale = 0.5
        radarOpacity = 1.0
        
        withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
            radarScale = 2.0
            radarOpacity = 0.0
        }
    }
}

#Preview {
    MDNSWorkspaceView()
}
