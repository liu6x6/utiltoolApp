import SwiftUI

struct CaseConverterView: View {
    @State private var viewModel = CaseConverterViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // 控制栏
            HStack {
                Text("目标风格:")
                Picker("", selection: $viewModel.targetCase) {
                    ForEach(CaseConverterViewModel.CaseType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 200)
                
                Spacer()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            // I/O 面板
            IOTextPanel(
                inputText: $viewModel.inputText,
                outputText: $viewModel.outputText,
                layout: .horizontal,
                inputTitle: "原始文本",
                outputTitle: "转换结果"
            )
        }
        .navigationTitle("命名风格转换")
    }
}

#Preview {
    CaseConverterView()
}
