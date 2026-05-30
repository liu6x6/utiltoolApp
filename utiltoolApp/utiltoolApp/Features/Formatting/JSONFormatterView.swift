import SwiftUI

struct JSONFormatterView: View {
    @State private var viewModel = JSONFormatterViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // 控制栏
            HStack {
                Toggle("2个空格缩进", isOn: $viewModel.useTwoSpaces)
                    .toggleStyle(.checkbox)
                
                Spacer()
                
                Button("美化 (Format)") {
                    viewModel.formatJSON()
                }
                .buttonStyle(.bordered)
                
                Button("压缩 (Minify)") {
                    viewModel.compressJSON()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            // 错误提示条
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(Color.red.opacity(0.8))
            }
            
            // I/O 面板
            IOTextPanel(
                inputText: $viewModel.inputText,
                outputText: $viewModel.outputText,
                layout: .horizontal,
                inputTitle: "JSON 源码",
                outputTitle: "处理结果",
                inputLanguage: .json,
                outputLanguage: .json
            )
        }
        .navigationTitle("JSON 格式化")
    }
}

#Preview {
    JSONFormatterView()
}
