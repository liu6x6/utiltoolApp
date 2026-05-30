import SwiftUI
import AppKit

/// 通用的双栏文本输入/输出面板
/// 支持：单面板(只读/只写)、双面板(上下或左右布局)
struct IOTextPanel: View {
    
    enum LayoutMode {
        case horizontal // 左右布局
        case vertical   // 上下布局
        case single     // 仅显示一个面板 (通常用于只读输出或全屏输入)
    }
    
    // 状态绑定
    @Binding var inputText: String
    @Binding var outputText: String
    @Binding var outputHexText: String?
    
    // 配置项
    var layout: LayoutMode = .horizontal
    var inputTitle: String = "输入"
    var outputTitle: String = "输出"
    var isOutputReadOnly: Bool = true
    
    init(inputText: Binding<String>,
            outputText: Binding<String>,
            outputHexText: Binding<String?>? = nil,
            layout: LayoutMode = .horizontal,
            inputTitle: String = "输入",
            outputTitle: String = "输出",
            isOutputReadOnly: Bool = true) {
           self._inputText = inputText
           self._outputText = outputText
           self._outputHexText = outputHexText ?? .constant(nil)
           self.layout = layout
           self.inputTitle = inputTitle
           self.outputTitle = outputTitle
           self.isOutputReadOnly = isOutputReadOnly
       }
    
    var body: some View {
        Group {
            switch layout {
            case .horizontal:
                HStack(spacing: 16) {
                    inputSection
                    outputSection
                }
            case .vertical:
                VStack(spacing: 16) {
                    inputSection
                    outputSection
                }
            case .single:
                outputSection
            }
        }
        .padding()
    }
    
    // MARK: - Subviews
    
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(inputTitle)
                    .font(.headline)
                Spacer()
                Button(action: { pasteFromClipboard() }) {
                    Label("粘贴", systemImage: "doc.on.clipboard")
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
                
                Button(action: { inputText = "" }) {
                    Label("清空", systemImage: "trash")
                }
                .buttonStyle(.plain)
                .foregroundColor(.red)
            }
            
            TextEditor(text: $inputText)
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
    
    private var outputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(outputTitle)
                    .font(.headline)
                Spacer()
                Button(action: { copyToClipboard(text: outputText) }) {
                    Label("复制", systemImage: "doc.on.doc")
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
            }
            
            TextEditor(text: .init(
                get: { outputText },
                set: { if !isOutputReadOnly { outputText = $0 } }
            ))
            .font(.system(.body, design: .monospaced))
            .padding(4)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
            if let _ = outputHexText {
                HStack {
                    Text("Hex")
                        .font(.headline)
                    Spacer()
                    Button(action: { copyToClipboard(text: outputHexText ?? "") }) {
                        Label("复制", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                }
                TextEditor(text: .init(
                    get: { outputHexText ?? "" },
                    set: { if !isOutputReadOnly { outputHexText = $0 } }
                ))
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
    }
    
    // MARK: - Actions
    
    private func copyToClipboard(text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    private func pasteFromClipboard() {
        let pasteboard = NSPasteboard.general
        if let string = pasteboard.string(forType: .string) {
            inputText = string
        }
    }
}

#Preview {
    IOTextPanel(
        inputText: .constant("{\"name\":\"test\"}"),
        outputText: .constant("{\n  \"name\": \"test\"\n}"),
        outputHexText: .constant("{\n  \"hex name\": \"test\"\n}"),
        layout: .horizontal,
        inputTitle: "JSON 源码",
        outputTitle: "格式化结果"
    )
    .frame(width: 800, height: 400)
}
