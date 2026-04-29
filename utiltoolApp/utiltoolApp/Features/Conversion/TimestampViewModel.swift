import Foundation

@Observable
class TimestampViewModel {
    var timestampInput: String = "" {
        didSet { convertFromTimestamp() }
    }
    var dateInput: String = "" {
        didSet { convertFromDate() }
    }
    
    var timestampOutput: String = ""
    var dateOutput: String = ""
    
    var isMilliseconds: Bool = false {
        didSet {
            convertFromTimestamp()
            convertFromDate()
        }
    }
    
    var isFloat: Bool = false {
        didSet {
            convertFromTimestamp()
            convertFromDate()
        }
    }
    
    // 用户自定义的 DateFormat 字符串
    var customFormat: String = "yyyy-MM-dd HH:mm:ss" {
        didSet {
            formatter.dateFormat = customFormat.isEmpty ? "yyyy-MM-dd HH:mm:ss" : customFormat
            convertFromTimestamp()
            convertFromDate()
        }
    }
    
    // 预设的常用格式
    let presetFormats: [String] = [
        "yyyy-MM-dd HH:mm:ss",
        "yyyy/MM/dd HH:mm:ss",
        "yyyy-MM-dd",
        "HH:mm:ss",
        "yyyy-MM-dd'T'HH:mm:ssZ", // ISO 8601
        "E, d MMM yyyy HH:mm:ss Z" // RFC 2822
    ]
    
    private var isUpdating = false
    
    let formatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return df
    }()
    
    func setCurrentTime() {
        let now = Date()
        isUpdating = true
        
        let interval = now.timeIntervalSince1970
        
        if isFloat {
            let val = isMilliseconds ? interval * 1000 : interval
            timestampInput = String(format: "%.6f", val)
        } else {
            let val = isMilliseconds ? Int64(interval * 1000) : Int64(interval)
            timestampInput = String(val)
        }
        
        dateInput = formatter.string(from: now)
        
        convertFromTimestamp()
        convertFromDate()
        
        isUpdating = false
    }
    
    func convertFromTimestamp() {
        if isUpdating { return }
        guard !timestampInput.isEmpty, let value = Double(timestampInput) else {
            dateOutput = "无效的时间戳"
            return
        }
        
        let interval = isMilliseconds ? value / 1000.0 : value
        let date = Date(timeIntervalSince1970: interval)
        dateOutput = formatter.string(from: date)
    }
    
    func convertFromDate() {
        if isUpdating { return }
        guard !dateInput.isEmpty, let date = formatter.date(from: dateInput) else {
            timestampOutput = "无效的日期格式"
            return
        }
        
        let interval = date.timeIntervalSince1970
        if isFloat {
            let val = isMilliseconds ? interval * 1000 : interval
            timestampOutput = String(format: "%.6f", val)
        } else {
            let val = isMilliseconds ? Int64(interval * 1000) : Int64(interval)
            timestampOutput = String(val)
        }
    }
}
