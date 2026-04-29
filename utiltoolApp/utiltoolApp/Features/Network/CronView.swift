import SwiftUI

struct CronView: View {
    @State private var viewModel = CronViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Cron 表达式")
                    .font(.headline)
                
                TextField("例如: 0 0 * * *", text: $viewModel.cronExpression)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.title3, design: .monospaced))
                
                Text("格式: [分] [时] [日] [月] [周]")
                    .font(.caption)
                    .foregroundColor(.secondary)
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
            
            VStack(alignment: .leading, spacing: 15) {
                Text("语义解析")
                    .font(.headline)
                
                TextEditor(text: .constant(viewModel.explanation))
                    .font(.system(.body, design: .monospaced))
                    .padding(8)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            }
            .padding()
            
            Spacer()
        }
        .navigationTitle("Crontab 解析")
        .onAppear {
            viewModel.parse()
        }
    }
}

#Preview {
    CronView()
}
