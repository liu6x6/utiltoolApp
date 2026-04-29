import SwiftUI

struct ContentView: View {
    // 默认选中 JSON 格式化
    @EnvironmentObject var navState: NavigationState
    
    var body: some View {
        NavigationSplitView {
            // 左侧边栏
            SidebarView(selection: $navState.selectedItem)
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 300)
        } detail: {
            // 右侧主内容区，根据选中的工具切换 View
            if let selectedItem = navState.selectedItem {
                detailView(for: selectedItem)
            } else {
                Text("请在左侧选择一个工具")
                    .font(.title)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // 路由分发逻辑
    @ViewBuilder
    private func detailView(for item: ToolItem) -> some View {
        switch item {
        case .jsonFormat:
            JSONFormatterView()
        case .xmlFormat:
            XMLFormatterView()
        case .jsonToCode:
            JSONToCodeView()
        case .jsonConvert:
            JSONConverterView()
        case .baseEncode:
            BaseToolView()
        case .jwt:
            JWTDecoderView()
        case .mockApi:
            MockAPIView()
        case .urlTool:
            URLToolView()
        case .cron:
            CronView()
        case .bluetooth:
            BluetoothLaunchView()
        case .mdns:
            MDNSLaunchView()
        case .hash:
            HashView()
        case .timestamp:
            TimestampView()
        case .baseConvert:
            BaseConvertView()
        case .uuid:
            UUIDView()
        case .caseConvert:
            CaseConverterView()
        case .textDiff:
            TextDiffView()
        case .regex:
            RegexTesterView()
        case .qrcode:
            QRCodeView()
        case .colorConvert:
            ColorConvertView()
        case .password:
            PasswordView()
        default:
            // TODO: 其他模块占位符
            VStack {
                Image(systemName: item.systemImage)
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                    .padding(.bottom, 20)
                
                Text("\(item.rawValue) 模块正在开发中...")
                    .font(.title2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle(item.rawValue)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(NavigationState())
}
