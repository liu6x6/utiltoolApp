import SwiftUI

struct BaseEncodeView: View {
    @State private var viewModel = BaseEncodeViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // 控制栏
            HStack(spacing: 30) {
                Picker("编码类型", selection: $viewModel.baseType) {
                    ForEach(BaseEncodeViewModel.BaseType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
                
                Picker("操作模式", selection: $viewModel.mode) {
                    Text("编码 (Encode)").tag(BaseEncodeViewModel.Mode.encode)
                    Text("解码 (Decode)").tag(BaseEncodeViewModel.Mode.decode)
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
                outputHexText: $viewModel.outputHexText,
                layout: .horizontal,
                inputTitle: viewModel.mode == .encode ? "明文" : "\(viewModel.baseType.rawValue) 密文",
                outputTitle: viewModel.mode == .encode ? "\(viewModel.baseType.rawValue) 密文" : "明文"
            )
        }
        .navigationTitle("Base 编解码")
    }
}

#Preview {
    BaseEncodeView()
}
