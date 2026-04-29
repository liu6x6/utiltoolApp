import SwiftUI

struct URLParserView: View {
    @State private var viewModel = URLParserViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // URL 输入区
            VStack(alignment: .leading, spacing: 8) {
                Text("输入完整 URL")
                    .font(.headline)
                
                TextField("例如: https://api.example.com:8080/v1/users?id=123&name=test", text: $viewModel.inputURL)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            // 解析结果展示区
            HStack(alignment: .top, spacing: 20) {
                // 左侧基本信息
                VStack(alignment: .leading, spacing: 15) {
                    Text("基本信息")
                        .font(.headline)
                    
                    VStack(spacing: 0) {
                        InfoRow(label: "Scheme", value: viewModel.scheme)
                        Divider()
                        InfoRow(label: "Host", value: viewModel.host)
                        Divider()
                        InfoRow(label: "Port", value: viewModel.port)
                        Divider()
                        InfoRow(label: "Path", value: viewModel.path)
                    }
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                }
                .frame(width: 300)
                
                // 右侧 Query 参数表
                VStack(alignment: .leading, spacing: 15) {
                    Text("Query 参数 (\(viewModel.queryItems.count))")
                        .font(.headline)
                    
                    if viewModel.queryItems.isEmpty {
                        Text("无参数")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                    } else {
                        Table(viewModel.queryItems) {
                            TableColumn("Key", value: \.key)
                                .width(min: 100, ideal: 150)
                            TableColumn("Value", value: \.value)
                        }
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
}

fileprivate struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            
            Text(value.isEmpty ? "-" : value)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .lineLimit(2)
            
            Spacer()
        }
        .padding(10)
    }
}

#Preview {
    URLParserView()
}
