import SwiftUI

struct TextDiffView: View {
    @State private var viewModel = TextDiffViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // 控制栏
            HStack {
                Text("输入左右两侧文本进行对比")
                    .foregroundColor(.secondary)
                Spacer()
                Button("清空全部") {
                    viewModel.clear()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            // 输入面板
            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("左侧文本 (旧)")
                        .font(.headline)
                    TextEditor(text: $viewModel.leftText)
                        .font(.system(.body, design: .monospaced))
                        .padding(4)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2)))
                }
                
                VStack(alignment: .leading) {
                    Text("右侧文本 (新)")
                        .font(.headline)
                    TextEditor(text: $viewModel.rightText)
                        .font(.system(.body, design: .monospaced))
                        .padding(4)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2)))
                }
            }
            .padding()
            .frame(height: 250)
            
            Divider()
            
            // 结果面板
            VStack(alignment: .leading) {
                Text("对比结果")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if viewModel.diffResult.isEmpty {
                            Text("等待输入内容...")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            ForEach(viewModel.diffResult) { chunk in
                                HStack(spacing: 0) {
                                    Text(icon(for: chunk.type))
                                        .frame(width: 30, alignment: .center)
                                        .foregroundColor(color(for: chunk.type))
                                    
                                    Text(chunk.text.isEmpty ? " " : chunk.text)
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundColor(color(for: chunk.type))
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 2)
                                .background(backgroundColor(for: chunk.type))
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2)))
                .padding()
            }
        }
        .navigationTitle("文本对比")
    }
    
    private func icon(for type: DiffChunk.DiffType) -> String {
        switch type {
        case .added: return "+"
        case .removed: return "-"
        case .unchanged: return " "
        }
    }
    
    private func color(for type: DiffChunk.DiffType) -> Color {
        switch type {
        case .added: return .green
        case .removed: return .red
        case .unchanged: return .primary
        }
    }
    
    private func backgroundColor(for type: DiffChunk.DiffType) -> Color {
        switch type {
        case .added: return .green.opacity(0.1)
        case .removed: return .red.opacity(0.1)
        case .unchanged: return .clear
        }
    }
}

#Preview {
    TextDiffView()
}
