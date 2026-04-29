import SwiftUI

struct UUIDView: View {
    @State private var viewModel = UUIDViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // 控制栏
            HStack(spacing: 30) {
                Stepper("生成数量: \(viewModel.count)", value: $viewModel.count, in: 1...100)
                    .frame(width: 180)
                
                Toggle("大写", isOn: $viewModel.uppercase)
                    .toggleStyle(.checkbox)
                
                Toggle("移除连字符 (-)", isOn: $viewModel.removeHyphens)
                    .toggleStyle(.checkbox)
                
                Spacer()
                
                Button("重新生成") {
                    viewModel.generate()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            // 单面板输出，复用 IOTextPanel
            IOTextPanel(
                inputText: .constant(""),
                outputText: $viewModel.outputText,
                layout: .single,
                outputTitle: "生成的 UUID 列表"
            )
        }
        .navigationTitle("UUID 生成器")
        .onAppear {
            if viewModel.outputText.isEmpty {
                viewModel.generate()
            }
        }
    }
}

#Preview {
    UUIDView()
}
