import SwiftUI

struct PasswordView: View {
    @State private var viewModel = PasswordViewModel()
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(alignment: .leading, spacing: 20) {
                Text("配置选项")
                    .font(.headline)
                
                VStack(spacing: 15) {
                    HStack {
                        Text("长度: \(Int(viewModel.length))")
                            .frame(width: 80, alignment: .leading)
                        Slider(value: $viewModel.length, in: 4...64, step: 1)
                    }
                    
                    HStack(spacing: 30) {
                        Toggle("大写 (A-Z)", isOn: $viewModel.includeUppercase)
                        Toggle("小写 (a-z)", isOn: $viewModel.includeLowercase)
                        Toggle("数字 (0-9)", isOn: $viewModel.includeNumbers)
                        Toggle("符号 (!@#$)", isOn: $viewModel.includeSymbols)
                    }
                    .toggleStyle(.checkbox)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 15) {
                Text("生成的密码")
                    .font(.headline)
                
                HStack {
                    Text(viewModel.password)
                        .font(.system(.title2, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                    
                    Button {
                        viewModel.generate()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                    .help("重新生成")
                    
                    Button {
                        copyToClipboard(text: viewModel.password)
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                    .help("复制密码")
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top)
        .navigationTitle("随机密码生成")
        .onAppear {
            viewModel.generate()
        }
    }
    
    private func copyToClipboard(text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

#Preview {
    PasswordView()
}
