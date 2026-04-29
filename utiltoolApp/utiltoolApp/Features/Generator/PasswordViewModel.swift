import Foundation

@Observable
class PasswordViewModel {
    var length: Double = 16 {
        didSet { generate() }
    }
    var includeUppercase: Bool = true {
        didSet { generate() }
    }
    var includeLowercase: Bool = true {
        didSet { generate() }
    }
    var includeNumbers: Bool = true {
        didSet { generate() }
    }
    var includeSymbols: Bool = true {
        didSet { generate() }
    }
    
    var password: String = ""
    
    func generate() {
        let uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let lowercase = "abcdefghijklmnopqrstuvwxyz"
        let numbers = "0123456789"
        let symbols = "!@#$%^&*()_+-=[]{}|;:,.<>?"
        
        var charset = ""
        if includeUppercase { charset += uppercase }
        if includeLowercase { charset += lowercase }
        if includeNumbers { charset += numbers }
        if includeSymbols { charset += symbols }
        
        guard !charset.isEmpty else {
            password = ""
            return
        }
        
        var result = ""
        for _ in 0..<Int(length) {
            let randomIndex = Int.random(in: 0..<charset.count)
            let char = charset[charset.index(charset.startIndex, offsetBy: randomIndex)]
            result.append(char)
        }
        
        password = result
    }
}
