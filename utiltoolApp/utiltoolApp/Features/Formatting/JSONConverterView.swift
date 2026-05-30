import SwiftUI

struct JSONConverterView: View {
    @State private var viewModel = JSONConverterViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // 控制栏
            HStack(spacing: 20) {
                Picker("目标格式", selection: $viewModel.targetFormat) {
                    ForEach(JSONConverterViewModel.TargetFormat.allCases) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 250)
                
                Spacer()
                
                Button("转换") {
                    viewModel.convert()
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
                outputTitle: viewModel.targetFormat.rawValue,
                inputLanguage: .json,
                outputLanguage: outputLanguage
            )
        }
        .navigationTitle("JSON 数据转换")
    }
    
    private var outputLanguage: CodeTextLanguage? {
        switch viewModel.targetFormat {
        case .yaml:
            return .yaml
        case .csv:
            return .csv
        }
    }
}

#Preview {
    JSONConverterView()
}
