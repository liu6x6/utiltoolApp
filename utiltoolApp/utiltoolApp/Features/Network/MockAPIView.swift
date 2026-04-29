import SwiftUI

struct MockAPIView: View {
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "server.rack")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            Text("高级 Mock API 服务器")
                .font(.largeTitle)
                .bold()
            
            Text("Mock API 已升级为独立的多标签窗口应用程序，\n您可以方便地在多标签页中并发管理 RESTful API 和 WebSocket 服务。")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button(action: {
                openWindow(id: "mock-api-workspace")
            }) {
                HStack {
                    Image(systemName: "ui.window")
                    Text("打开 Mock 工作区")
                        .font(.title3)
                }
                .padding()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("本地 Mock API")
    }
}

#Preview {
    MockAPIView()
}
