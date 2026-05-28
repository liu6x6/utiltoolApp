import SwiftUI

struct JSONToCodeView: View {
    @State private var viewModel = JSONToCodeViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // 控制栏
            HStack(spacing: 20) {
                Picker("目标语言", selection: $viewModel.language) {
                    ForEach(JSONToCodeViewModel.TargetLanguage.allCases) { lang in
                        Text(lang.rawValue).tag(lang)
                    }
                }
                .frame(width: 250)
                
                TextField("根类名称 (Root Name)", text: $viewModel.rootClassName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
                
                Spacer()
                
                Button("生成代码") {
                    viewModel.generate()
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
                outputTitle: "生成代码",
                inputLanguage: .json,
                outputLanguage: outputLanguage
            )
        }
        .navigationTitle("JSON 转代码")
    }
    
    private var outputLanguage: CodeTextLanguage {
        switch viewModel.language {
        case .typescript:
            return .typescript
        case .swift:
            return .swift
        case .go:
            return .go
        case .python:
            return .python
        }
    }
}

#Preview {
    JSONToCodeView()
}
