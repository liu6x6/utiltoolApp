//
//  utiltoolAppApp.swift
//  utiltoolApp
//
//  Created by SPxT666 on 2026/4/24.
//

import SwiftUI

@main
struct utiltoolAppApp: App {
    @StateObject private var navState = NavigationState()
    @State private var mockAPIViewModel = MockAPIViewModel()
    
    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                // 为 Mac App 设置一个舒适的默认启动尺寸和最小限制
                .frame(minWidth: 800, idealWidth: 1000, minHeight: 600, idealHeight: 700)
                .environmentObject(navState)
                .environment(mockAPIViewModel)
        }
        // 提供系统级侧边栏切换快捷键 (Cmd + S) 和菜单项
        .commands {
            SidebarCommands()
        }
        
        // 状态栏菜单
        MenuBarExtra("UtilTool", systemImage: "hammer.fill") {
            MenuBarView()
                .environmentObject(navState)
        }
        
        // Mock API 独立工作区窗口
        WindowGroup("Mock API 工作区", id: "mock-api-workspace") {
            MockServerWorkspaceView()
                .environment(mockAPIViewModel)
                .frame(minWidth: 800, idealWidth: 1000, minHeight: 600, idealHeight: 800)
        }
        
        // Mock API 日志窗口
        WindowGroup("Mock API 请求日志", id: "mock-api-logs") {
            MockAPILogView()
                .environment(mockAPIViewModel)
                .frame(minWidth: 600, idealWidth: 800, minHeight: 400, idealHeight: 500)
        }
        
        // 蓝牙工作区窗口
        WindowGroup("蓝牙调试工具", id: "bluetooth-workspace") {
            BluetoothWorkspaceView()
                .frame(minWidth: 800, idealWidth: 1000, minHeight: 600, idealHeight: 700)
        }
        
        // mDNS 工作区窗口
        WindowGroup("mDNS 调试工具", id: "mdns-workspace") {
            MDNSWorkspaceView()
                .frame(minWidth: 800, idealWidth: 1000, minHeight: 600, idealHeight: 700)
        }
    }
}
