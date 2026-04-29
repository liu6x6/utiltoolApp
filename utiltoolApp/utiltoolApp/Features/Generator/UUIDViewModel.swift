import Foundation

@Observable
class UUIDViewModel {
    var count: Int = 1 {
        didSet { generate() }
    }
    
    var uppercase: Bool = true {
        didSet { generate() }
    }
    
    var removeHyphens: Bool = false {
        didSet { generate() }
    }
    
    var outputText: String = ""
    
    func generate() {
        // 防止意外大数量导致卡顿，限制最大 1000 个
        let safeCount = max(1, min(count, 1000))
        
        var results: [String] = []
        
        for _ in 0..<safeCount {
            var uuidStr = UUID().uuidString
            
            if removeHyphens {
                uuidStr = uuidStr.replacingOccurrences(of: "-", with: "")
            }
            
            if !uppercase {
                uuidStr = uuidStr.lowercased()
            }
            
            results.append(uuidStr)
        }
        
        outputText = results.joined(separator: "\n")
    }
}
