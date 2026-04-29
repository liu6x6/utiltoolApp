import SwiftUI

struct SidebarView: View {
    @Binding var selection: ToolItem?
    
    var body: some View {
        List(selection: $selection) {
            Section("编解码与加密") {
                SidebarLabel(.hash)
                SidebarLabel(.baseEncode)
                SidebarLabel(.jwt)
            }
            
            Section("格式化") {
                SidebarLabel(.jsonFormat)
                SidebarLabel(.xmlFormat)
                SidebarLabel(.jsonToCode)
                SidebarLabel(.jsonConvert)
            }
            
            Section("转换") {
                SidebarLabel(.timestamp)
                SidebarLabel(.baseConvert)
                SidebarLabel(.caseConvert)
                SidebarLabel(.textDiff)
                SidebarLabel(.regex)
            }
            
            Section("Web 与网络") {
                SidebarLabel(.mockApi)
                SidebarLabel(.urlTool)
                SidebarLabel(.cron)
                SidebarLabel(.bluetooth)
                SidebarLabel(.mdns)
            }
            
            Section("生成与视觉") {
                SidebarLabel(.qrcode)
                SidebarLabel(.colorConvert)
                SidebarLabel(.uuid)
                SidebarLabel(.password)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("工具箱")
    }
    
    // 辅助 View 构建器，保持代码整洁
    private func SidebarLabel(_ item: ToolItem) -> some View {
        NavigationLink(value: item) {
            Label(item.rawValue, systemImage: item.systemImage)
        }
    }
}

#Preview {
    SidebarView(selection: .constant(.jsonFormat))
}
