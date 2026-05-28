import SwiftUI

struct XMLFormatterView: View {
    @State private var viewModel = XMLFormatterViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // 控制栏
            HStack {
                Spacer()
                
                Button("美化 (Format)") {
                    viewModel.formatXML()
                }
                .buttonStyle(.bordered)
                
                Button("压缩 (Minify)") {
                    viewModel.compressXML()
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
                inputTitle: "XML 源码",
                outputTitle: "处理结果",
                inputLanguage: .xml,
                outputLanguage: .xml
            )
        }
        .navigationTitle("XML 格式化")
    }
}

#Preview {
    XMLFormatterView()
}
