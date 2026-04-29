import SwiftUI

struct BluetoothLaunchView: View {
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "wave.3.left.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            Text("高级蓝牙调试工具")
                .font(.largeTitle)
                .bold()
            
            Text("独立的多标签窗口应用程序，\n支持扫描并连接外部设备 (Central) 和广播模拟外设 (Peripheral)。")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button(action: {
                openWindow(id: "bluetooth-workspace")
            }) {
                HStack {
                    Image(systemName: "ui.window")
                    Text("打开蓝牙工作区")
                        .font(.title3)
                }
                .padding()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("蓝牙调试")
    }
}

#Preview {
    BluetoothLaunchView()
}
