import SwiftUI

/// 定义侧边栏菜单支持的所有工具类型
enum ToolItem: String, CaseIterable, Identifiable {
    // 编解码与加密
    case hash = "哈希摘要"
    case baseEncode = "Base 编解码"
    case jwt = "JWT 解析"
    
    // 格式化
    case jsonFormat = "JSON 格式化"
    case xmlFormat = "XML 格式化"
    case jsonToCode = "JSON 转代码"
    case jsonConvert = "JSON 转数据"
    
    // 转换
    case timestamp = "时间戳转换"
    case baseConvert = "进制转换"
    case caseConvert = "命名风格转换"
    case textDiff = "文本对比"
    case regex = "正则表达式"
    
    // Web 与网络
    case mockApi = "Mock API"
    case urlTool = "URL 工具"
    case cron = "Crontab 解析"
    case bluetooth = "蓝牙调试"
    case mdns = "mDNS (Bonjour)"
    
    // 生成与视觉
    case qrcode = "二维码"
    case colorConvert = "颜色转换"
    case uuid = "UUID 生成"
    case password = "随机密码"
    
    var id: String { self.rawValue }
    
    var systemImage: String {
        switch self {
        case .hash: return "number.square"
        case .baseEncode: return "arrow.left.and.right.text.vertical"
        case .jwt: return "key.horizontal"
            
        case .jsonFormat: return "curlybraces"
        case .xmlFormat: return "chevron.left.forwardslash.chevron.right"
        case .jsonToCode: return "chevron.left.chevron.right"
        case .jsonConvert: return "arrow.triangle.2.circlepath.doc.on.clipboard"
            
        case .timestamp: return "clock.arrow.circlepath"
        case .baseConvert: return "123.rectangle"
        case .caseConvert: return "textformat.size"
        case .textDiff: return "arrow.left.and.right.righttriangle.left.righttriangle.right"
        case .regex: return "magnifyingglass.circle"
            
        case .mockApi: return "server.rack"
        case .urlTool: return "link"
        case .cron: return "calendar.badge.clock"
        case .bluetooth: return "wave.3.left.circle"
        case .mdns: return "bonjour"
            
        case .qrcode: return "qrcode"
        case .colorConvert: return "paintpalette"
        case .uuid: return "tag"
        case .password: return "lock.rotation"
        }
    }
}
