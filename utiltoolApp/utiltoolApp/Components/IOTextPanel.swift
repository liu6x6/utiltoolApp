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
    
    // 配置项
    var layout: LayoutMode = .horizontal
    var inputTitle: String = "输入"
    var outputTitle: String = "输出"
    var isOutputReadOnly: Bool = true
    var inputLanguage: CodeTextLanguage? = nil
    var outputLanguage: CodeTextLanguage? = nil
    
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
            
            CodeTextView(
                text: $inputText,
                language: inputLanguage,
                isEditable: true
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
            
            CodeTextView(
                text: .init(
                    get: { outputText },
                    set: { if !isOutputReadOnly { outputText = $0 } }
                ),
                language: outputLanguage,
                isEditable: !isOutputReadOnly
            )
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
        layout: .horizontal,
        inputTitle: "JSON 源码",
        outputTitle: "格式化结果",
        inputLanguage: .json,
        outputLanguage: .json
    )
    .frame(width: 800, height: 400)
}
