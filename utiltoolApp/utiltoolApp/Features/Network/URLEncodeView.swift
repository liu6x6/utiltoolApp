import SwiftUI

struct URLEncodeView: View {
    @State private var viewModel = URLEncodeViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // 控制栏
            HStack {
                Picker("操作模式", selection: $viewModel.mode) {
                    Text("编码 (Encode)").tag(URLEncodeViewModel.Mode.encode)
                    Text("解码 (Decode)").tag(URLEncodeViewModel.Mode.decode)
                }
                .pickerStyle(.segmented)
                .frame(width: 250)
                
                Spacer()
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
                inputTitle: viewModel.mode == .encode ? "原始 URL" : "编码 URL",
                outputTitle: viewModel.mode == .encode ? "编码 URL" : "原始 URL"
            )
        }
        .navigationTitle("URL 编解码")
    }
}

#Preview {
    URLEncodeView()
}
