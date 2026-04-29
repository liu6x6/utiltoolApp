import SwiftUI

struct JWTDecoderView: View {
    @State private var viewModel = JWTDecoderViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // 输入区 (全宽)
            VStack(alignment: .leading, spacing: 8) {
                Text("粘贴 JWT Token")
                    .font(.headline)
                
                TextEditor(text: $viewModel.inputText)
                    .font(.system(.body, design: .monospaced))
                    .frame(height: 100)
                    .padding(4)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            }
            .padding()
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(Color.red.opacity(0.8))
            }
            
            Divider()
            
            // 输出区 (双栏展示 Header 和 Payload)
            HStack(spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Header")
                            .font(.headline)
                        Spacer()
                        Button(action: { copyToClipboard(text: viewModel.headerText) }) {
                            Image(systemName: "doc.on.doc")
                        }
                        .buttonStyle(.plain)
                    }
                    
                    TextEditor(text: .constant(viewModel.headerText))
                        .font(.system(.body, design: .monospaced))
                        .padding(4)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                }
                
                // Payload
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Payload")
                            .font(.headline)
                        Spacer()
                        Button(action: { copyToClipboard(text: viewModel.payloadText) }) {
                            Image(systemName: "doc.on.doc")
                        }
                        .buttonStyle(.plain)
                    }
                    
                    TextEditor(text: .constant(viewModel.payloadText))
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
        }
        .navigationTitle("JWT 解析器")
    }
    
    private func copyToClipboard(text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

#Preview {
    JWTDecoderView()
}
