import SwiftUI

struct RegexTesterView: View {
    @State private var viewModel = RegexTesterViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // 正则表达式输入区
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("正则表达式 (Pattern)")
                        .font(.headline)
                    Spacer()
                    Toggle("忽略大小写", isOn: $viewModel.caseInsensitive)
                        .toggleStyle(.checkbox)
                    Toggle("点号匹配换行", isOn: $viewModel.dotMatchesLineSeparators)
                        .toggleStyle(.checkbox)
                }
                
                TextField("在此输入正则表达式, 例如: \\d+", text: $viewModel.pattern)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(Color.red.opacity(0.8))
            }
            
            HStack(spacing: 0) {
                // 测试文本输入
                VStack(alignment: .leading, spacing: 8) {
                    Text("测试文本 (Test String)")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    TextEditor(text: $viewModel.inputText)
                        .font(.system(.body, design: .monospaced))
                        .padding(4)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                
                // 匹配结果列表
                VStack(alignment: .leading, spacing: 8) {
                    Text("匹配结果 (\(viewModel.matches.count))")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    List(viewModel.matches) { match in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("全文匹配: ")
                                .font(.caption)
                                .foregroundColor(.secondary) +
                            Text(match.fullMatch)
                                .font(.system(.body, design: .monospaced))
                                .bold()
                            
                            if !match.groups.isEmpty {
                                ForEach(0..<match.groups.count, id: \.self) { index in
                                    HStack {
                                        Text("Group \(index + 1):")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(match.groups[index])
                                            .font(.system(.body, design: .monospaced))
                                    }
                                    .padding(.leading, 10)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        Divider()
                    }
                    .listStyle(.plain)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical)
        }
        .navigationTitle("正则表达式测试")
    }
}

#Preview {
    RegexTesterView()
}
