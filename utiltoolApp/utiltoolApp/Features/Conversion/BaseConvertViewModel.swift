import Foundation

@Observable
class BaseConvertViewModel {
    var binary: String = "" {
        didSet { if !isUpdating { update(from: binary, radix: 2) } }
    }
    
    var octal: String = "" {
        didSet { if !isUpdating { update(from: octal, radix: 8) } }
    }
    
    var decimal: String = "" {
        didSet { if !isUpdating { update(from: decimal, radix: 10) } }
    }
    
    var hex: String = "" {
        didSet { if !isUpdating { update(from: hex, radix: 16) } }
    }
    
    var errorMessage: String? = nil
    
    private var isUpdating = false
    
    func clear() {
        isUpdating = true
        binary = ""
        octal = ""
        decimal = ""
        hex = ""
        errorMessage = nil
        isUpdating = false
    }
    
    private func update(from string: String, radix: Int) {
        isUpdating = true
        defer { isUpdating = false }
        
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            clear()
            return
        }
        
        if let value = Int64(trimmed, radix: radix) {
            if radix != 2 { binary = String(value, radix: 2).uppercased() }
            if radix != 8 { octal = String(value, radix: 8).uppercased() }
            if radix != 10 { decimal = String(value, radix: 10).uppercased() }
            if radix != 16 { hex = String(value, radix: 16).uppercased() }
            errorMessage = nil
        } else {
            errorMessage = "在 \(radix) 进制中输入了无效数值"
            // 清空其他框，表示错误状态
            if radix != 2 { binary = "" }
            if radix != 8 { octal = "" }
            if radix != 10 { decimal = "" }
            if radix != 16 { hex = "" }
        }
    }
}
