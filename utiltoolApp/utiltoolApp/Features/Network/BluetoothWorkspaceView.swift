import SwiftUI
import CoreBluetooth

struct BluetoothWorkspaceView: View {
    @State private var viewModel = BluetoothViewModel()
    @State private var selectedTab: Int = 0 // 0: Central, 1: Peripheral
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                Text("作为客户端扫描设备 (Central)").tag(0)
                Text("作为服务端广播 (Peripheral)").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            if selectedTab == 0 {
                centralView
            } else {
                peripheralView
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
    
    // MARK: - Central View
    private var centralView: some View {
        HStack(spacing: 0) {
            // Left: Device List
            VStack(spacing: 0) {
                HStack {
                    Text("状态: \(viewModel.centralStateStr)")
                        .font(.caption)
                        .foregroundColor(viewModel.centralStateStr == "Powered On" ? .green : .red)
                    Spacer()
                    Button(action: { viewModel.toggleScan() }) {
                        Text(viewModel.isCentralScanning ? "停止扫描" : "开始扫描")
                    }
                    .disabled(viewModel.centralStateStr != "Powered On")
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                List(viewModel.discoveredPeripherals) { p in
                    Button(action: {
                        if viewModel.connectedPeripheral?.identifier == p.id {
                            viewModel.disconnect()
                        } else {
                            viewModel.connect(to: p.peripheral)
                        }
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(p.name ?? "Unknown Device").font(.headline)
                                Text(p.id.uuidString).font(.caption2).foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("\(p.rssi) dBm").font(.caption).foregroundColor(.secondary)
                            if viewModel.connectedPeripheral?.identifier == p.id {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(width: 300)
            
            Divider()
            
            // Right: Connected Device details
            if let connected = viewModel.connectedPeripheral {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("已连接: \(connected.name ?? "Unknown")")
                            .font(.title3.bold())
                        Spacer()
                        Button("断开连接") {
                            viewModel.disconnect()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                    .padding()
                    
                    Divider()
                    
                    List(viewModel.discoveredCharacteristics) { dc in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("特征 UUID: \(dc.characteristic.uuid.uuidString)")
                                .font(.headline)
                            
                            if let valStr = dc.valueStr {
                                Text("当前值: \(valStr)")
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.blue)
                            } else {
                                Text("当前值: (空)")
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                if dc.characteristic.properties.contains(.read) {
                                    Button("读取") {
                                        viewModel.read(characteristic: dc.characteristic)
                                    }
                                }
                                if dc.characteristic.properties.contains(.write) || dc.characteristic.properties.contains(.writeWithoutResponse) {
                                    Button("写入测试数据 (Hello)") {
                                        if let d = "Hello".data(using: .utf8) {
                                            viewModel.write(data: d, to: dc.characteristic)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            } else {
                VStack {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("请在左侧选择一个设备并连接")
                        .foregroundColor(.secondary)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    // MARK: - Peripheral View
    private var peripheralView: some View {
        HStack(spacing: 0) {
            // Left: Config
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("状态: \(viewModel.peripheralStateStr)")
                        .font(.caption)
                        .foregroundColor(viewModel.peripheralStateStr == "Powered On" ? .green : .red)
                    Spacer()
                }
                
                Text("广播配置")
                    .font(.headline)
                
                VStack(alignment: .leading) {
                    Text("服务 UUID (Service)").font(.caption).foregroundColor(.secondary)
                    TextField("FFE0", text: $viewModel.serverServiceUUIDStr)
                        .textFieldStyle(.roundedBorder)
                        .disabled(viewModel.isPeripheralAdvertising)
                }
                
                VStack(alignment: .leading) {
                    Text("特征 UUID (Characteristic)").font(.caption).foregroundColor(.secondary)
                    TextField("FFE1", text: $viewModel.serverCharacteristicUUIDStr)
                        .textFieldStyle(.roundedBorder)
                        .disabled(viewModel.isPeripheralAdvertising)
                }
                
                VStack(alignment: .leading) {
                    Text("被读取时的返回数据 (Mock Response)").font(.caption).foregroundColor(.secondary)
                    TextEditor(text: $viewModel.serverMockResponse)
                        .font(.system(.body, design: .monospaced))
                        .frame(height: 100)
                        .padding(4)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2)))
                }
                
                Button(action: { viewModel.toggleAdvertising() }) {
                    HStack {
                        Image(systemName: viewModel.isPeripheralAdvertising ? "stop.fill" : "play.fill")
                        Text(viewModel.isPeripheralAdvertising ? "停止广播" : "开始广播服务")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(viewModel.isPeripheralAdvertising ? .red : .accentColor)
                .disabled(viewModel.peripheralStateStr != "Powered On")
                .padding(.top, 10)
                
                Spacer()
            }
            .padding()
            .frame(width: 300)
            
            Divider()
            
            // Right: Logs
            VStack(alignment: .leading, spacing: 0) {
                Text("客户端通信日志")
                    .font(.headline)
                    .padding()
                
                Divider()
                
                List(viewModel.receivedMessagesLogs, id: \.self) { log in
                    Text(log)
                        .font(.system(.caption, design: .monospaced))
                        .padding(.vertical, 2)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    BluetoothWorkspaceView()
}
