import SwiftUI
import AppKit

struct TimestampView: View {
    @State private var viewModel = TimestampViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            // 控制栏
            HStack(spacing: 20) {
                Toggle("毫秒 (Milliseconds)", isOn: $viewModel.isMilliseconds)
                    .toggleStyle(.checkbox)
                
                Toggle("浮点数 (Float)", isOn: $viewModel.isFloat)
                    .toggleStyle(.checkbox)
                
                Divider()
                    .frame(height: 20)
                
                Text("日期格式:")
                    .foregroundColor(.secondary)
                
                // 预设格式选择器
                Picker("", selection: $viewModel.customFormat) {
                    ForEach(viewModel.presetFormats, id: \.self) { format in
                        Text(format).tag(format)
                    }
                }
                .frame(width: 200)
                .labelsHidden()
                
                // 自定义格式输入框
                TextField("自定义格式 (例如: yyyy-MM-dd)", text: $viewModel.customFormat)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 220)
                    .font(.system(.body, design: .monospaced))
                
                Spacer()
                
                Button("填充当前时间") {
                    viewModel.setCurrentTime()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            // 内容区
            VStack(alignment: .leading, spacing: 40) {
                
                // Section 1: Timestamp to Date
                VStack(alignment: .leading, spacing: 15) {
                    Text("时间戳 转 日期")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        TextField("输入时间戳", text: $viewModel.timestampInput)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 250)
                            .font(.system(.body, design: .monospaced))
                        
                        Image(systemName: "arrow.right")
                            .foregroundColor(.secondary)
                        
                        TextField("结果", text: .constant(viewModel.dateOutput))
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 300)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.accentColor)
                        
                        Button {
                            copyToClipboard(text: viewModel.dateOutput)
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                        .buttonStyle(.plain)
                        .help("复制结果")
                    }
                }
                
                Divider()
                
                // Section 2: Date to Timestamp
                VStack(alignment: .leading, spacing: 15) {
                    Text("日期 转 时间戳")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        TextField(viewModel.customFormat.isEmpty ? "YYYY-MM-DD HH:mm:ss" : viewModel.customFormat, text: $viewModel.dateInput)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 250)
                            .font(.system(.body, design: .monospaced))
                        
                        Image(systemName: "arrow.right")
                            .foregroundColor(.secondary)
                        
                        TextField("结果", text: .constant(viewModel.timestampOutput))
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 300)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.accentColor)
                        
                        Button {
                            copyToClipboard(text: viewModel.timestampOutput)
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                        .buttonStyle(.plain)
                        .help("复制结果")
                    }
                }
            }
            .padding(.horizontal, 30)
            .padding(.top, 20)
            
            Spacer()
        }
        .navigationTitle("时间戳转换")
        .onAppear {
            if viewModel.timestampInput.isEmpty {
                viewModel.setCurrentTime()
            }
        }
    }
    
    private func copyToClipboard(text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

#Preview {
    TimestampView()
}
