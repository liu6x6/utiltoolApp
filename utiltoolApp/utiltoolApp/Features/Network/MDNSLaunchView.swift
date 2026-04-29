import SwiftUI

struct MDNSLaunchView: View {
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "bonjour")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            Text("mDNS (Bonjour) 局域网服务调试")
                .font(.largeTitle)
                .bold()
            
            Text("独立的多标签窗口应用程序，\n支持扫描局域网所有相关的 mDNS 服务并显示信息，\n同时也支持自行广播自定义的 mDNS 服务节点 (Publisher)。")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button(action: {
                openWindow(id: "mdns-workspace")
            }) {
                HStack {
                    Image(systemName: "ui.window")
                    Text("打开 mDNS 工作区")
                        .font(.title3)
                }
                .padding()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("mDNS 调试")
    }
}

#Preview {
    MDNSLaunchView()
}
