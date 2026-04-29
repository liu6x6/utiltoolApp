import SwiftUI
import AppKit

struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject var navState: NavigationState
    
    var body: some View {
        Button("显示主界面") {
            openMainWindow()
        }
        
        Divider()
        
        // 常用工具快捷入口
        Menu("快捷工具") {
            Button("JSON 格式化") {
                openTool(.jsonFormat)
            }
            Button("哈希摘要") {
                openTool(.hash)
            }
            Button("时间戳转换") {
                openTool(.timestamp)
            }
            Button("正则表达式") {
                openTool(.regex)
            }
        }
        
        Divider()
        
        Button("退出 utiltool") {
            NSApplication.shared.terminate(nil)
        }
    }
    
    private func openMainWindow() {
        // 唤起主窗口
        NSApp.activate(ignoringOtherApps: true)
        openWindow(id: "main")
    }
    
    private func openTool(_ tool: ToolItem) {
        navState.selectedItem = tool
        openMainWindow()
    }
}

#Preview {
    MenuBarView()
        .environmentObject(NavigationState())
}
