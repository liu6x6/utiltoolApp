import SwiftUI

struct MockAPILogView: View {
    @Environment(MockAPIViewModel.self) private var viewModel
    
    var body: some View {
        NavigationSplitView {
            // 左侧日志列表
            VStack(spacing: 0) {
                List(selection: Bindable(viewModel).selectedLogId) {
                    ForEach(viewModel.requestLogs) { log in
                        HStack {
                            Text(log.method)
                                .font(.caption.bold())
                                .foregroundColor(methodColor(log.method))
                                .frame(width: 45, alignment: .leading)
                            
                            Text(log.path)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            
                            Spacer()
                            
                            Text("\(log.responseStatusCode ?? 0)")
                                .foregroundColor((log.responseStatusCode ?? 0) < 400 ? .green : .red)
                                .font(.caption)
                        }
                        .tag(log.id)
                    }
                }
                .listStyle(.sidebar)
                
                // 底部清空按钮
                HStack {
                    Button(action: { viewModel.clearLogs() }) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.plain)
                    .padding(8)
                    Spacer()
                }
                .background(Color(NSColor.controlBackgroundColor))
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
        } detail: {
            // 右侧详情视图
            if let selectedLogId = viewModel.selectedLogId,
               let log = viewModel.requestLogs.first(where: { $0.id == selectedLogId }) {
                logViewer(for: log)
            } else {
                VStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("请选择一条请求记录以查看详情")
                        .foregroundColor(.secondary)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private func logViewer(for log: MockRequestLog) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(log.method)
                    .font(.headline)
                    .foregroundColor(methodColor(log.method))
                Text(log.path)
                    .font(.title3)
                Spacer()
                Text("\(log.responseStatusCode ?? 0)")
                    .font(.headline)
                    .foregroundColor((log.responseStatusCode ?? 0) < 400 ? .green : .red)
            }
            
            Text("时间: \(log.timestamp.formatted())")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
            
            Text("Headers")
                .font(.headline)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(log.headers.keys.sorted()), id: \.self) { key in
                        HStack(alignment: .top) {
                            Text(key + ":").bold()
                            Text(log.headers[key] ?? "")
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(6)
            }
            .frame(maxHeight: 150)
            
            Text("Body")
                .font(.headline)
            
            ScrollView {
                Text(log.body.isEmpty ? "(无内容)" : log.body)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(6)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    private func methodColor(_ method: String) -> Color {
        switch method {
        case "GET": return .blue
        case "POST": return .green
        case "PUT", "PATCH": return .orange
        case "DELETE": return .red
        case "WS": return .purple
        default: return .secondary
        }
    }
}

#Preview {
    MockAPILogView()
        .environment(MockAPIViewModel())
}
