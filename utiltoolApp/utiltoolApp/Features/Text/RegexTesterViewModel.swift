import Foundation

struct RegexMatch: Identifiable {
    let id = UUID()
    let fullMatch: String
    let range: NSRange
    let groups: [String]
}

@Observable
class RegexTesterViewModel {
    var pattern: String = "" {
        didSet { test() }
    }
    var inputText: String = "" {
        didSet { test() }
    }
    
    var matches: [RegexMatch] = []
    var errorMessage: String? = nil
    
    // 选项
    var caseInsensitive: Bool = false {
        didSet { test() }
    }
    var dotMatchesLineSeparators: Bool = false {
        didSet { test() }
    }
    
    func test() {
        guard !pattern.isEmpty else {
            matches = []
            errorMessage = nil
            return
        }
        
        var options: NSRegularExpression.Options = []
        if caseInsensitive { options.insert(.caseInsensitive) }
        if dotMatchesLineSeparators { options.insert(.dotMatchesLineSeparators) }
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: options)
            let nsString = inputText as NSString
            let results = regex.matches(in: inputText, options: [], range: NSRange(location: 0, length: nsString.length))
            
            matches = results.map { result in
                let fullMatch = nsString.substring(with: result.range)
                var groups: [String] = []
                if result.numberOfRanges > 1 {
                    for i in 1..<result.numberOfRanges {
                        let groupRange = result.range(at: i)
                        if groupRange.location != NSNotFound {
                            groups.append(nsString.substring(with: groupRange))
                        } else {
                            groups.append("(未匹配)")
                        }
                    }
                }
                return RegexMatch(fullMatch: fullMatch, range: result.range, groups: groups)
            }
            errorMessage = nil
        } catch {
            matches = []
            errorMessage = "正则语法错误: \(error.localizedDescription)"
        }
    }
}
