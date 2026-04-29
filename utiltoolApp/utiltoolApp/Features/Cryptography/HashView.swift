import SwiftUI

struct HashView: View {
    @State private var viewModel = HashViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // 控制栏
            HStack {
                Picker("算法", selection: $viewModel.hashType) {
                    ForEach(HashViewModel.HashType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .frame(width: 150)
                
                Toggle("大写", isOn: $viewModel.uppercase)
                    .toggleStyle(.checkbox)
                    .padding(.leading, 20)
                
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
                outputTitle: "\(viewModel.hashType.rawValue) 摘要"
            )
        }
        .navigationTitle("哈希摘要")
    }
}

#Preview {
    HashView()
}
