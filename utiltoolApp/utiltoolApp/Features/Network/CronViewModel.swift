import Foundation

@Observable
class CronViewModel {
    var cronExpression: String = "* * * * *" {
        didSet { parse() }
    }
    
    var explanation: String = ""
    var errorMessage: String? = nil
    
    func parse() {
        let components = cronExpression.trimmingCharacters(in: .whitespaces).components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        guard components.count == 5 else {
            errorMessage = "无效的 Cron 表达式（应包含 5 个部分: 分 时 日 月 周）"
            explanation = ""
            return
        }
        
        errorMessage = nil
        
        let minute = explainComponent(components[0], type: .minute)
        let hour = explainComponent(components[1], type: .hour)
        let dayOfMonth = explainComponent(components[2], type: .dayOfMonth)
        let month = explainComponent(components[3], type: .month)
        let dayOfWeek = explainComponent(components[4], type: .dayOfWeek)
        
        explanation = """
        ● 分钟: \(minute)
        ● 小时: \(hour)
        ● 日期: \(dayOfMonth)
        ● 月份: \(month)
        ● 星期: \(dayOfWeek)
        
        语义总结:
        在 \(month) 的 \(dayOfMonth) (\(dayOfWeek))，当时间为 \(hour):\(minute) 时执行。
        """
    }
    
    enum ComponentType {
        case minute, hour, dayOfMonth, month, dayOfWeek
    }
    
    private func explainComponent(_ component: String, type: ComponentType) -> String {
        if component == "*" {
            switch type {
            case .minute: return "每分钟"
            case .hour: return "每小时"
            case .dayOfMonth: return "每天"
            case .month: return "每月"
            case .dayOfWeek: return "每星期"
            }
        }
        
        if component.contains("/") {
            let parts = component.components(separatedBy: "/")
            if parts.count == 2 {
                let interval = parts[1]
                let start = parts[0] == "*" ? "0" : parts[0]
                switch type {
                case .minute: return "从第 \(start) 分钟起，每隔 \(interval) 分钟"
                case .hour: return "从第 \(start) 小时起，每隔 \(interval) 小时"
                case .dayOfMonth: return "从第 \(start) 日起，每隔 \(interval) 天"
                case .month: return "从第 \(start) 月起，每隔 \(interval) 个月"
                case .dayOfWeek: return "从星期 \(start) 起，每隔 \(interval) 天"
                }
            }
        }
        
        if component.contains(",") {
            return "在第 \(component) 个单位"
        }
        
        if component.contains("-") {
            return "在 \(component) 范围内的每一个单位"
        }
        
        return "在第 \(component) 个单位"
    }
}
