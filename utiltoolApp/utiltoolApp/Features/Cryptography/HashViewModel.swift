import Foundation
import CryptoKit

@Observable
class HashViewModel {
    enum HashType: String, CaseIterable, Identifiable {
        case md5 = "MD5"
        case sha1 = "SHA-1"
        case sha256 = "SHA-256"
        case sha512 = "SHA-512"
        var id: String { self.rawValue }
    }
    
    var hashType: HashType = .md5 {
        didSet { process() }
    }
    
    var uppercase: Bool = false {
        didSet { process() }
    }
    
    var inputText: String = "" {
        didSet { process() }
    }
    
    var outputText: String = ""
    
    func process() {
        guard !inputText.isEmpty else {
            outputText = ""
            return
        }
        
        guard let data = inputText.data(using: .utf8) else {
            outputText = "编码错误"
            return
        }
        
        var hashString = ""
        
        switch hashType {
        case .md5:
            let digest = Insecure.MD5.hash(data: data)
            hashString = digest.map { String(format: "%02x", $0) }.joined()
        case .sha1:
            let digest = Insecure.SHA1.hash(data: data)
            hashString = digest.map { String(format: "%02x", $0) }.joined()
        case .sha256:
            let digest = SHA256.hash(data: data)
            hashString = digest.map { String(format: "%02x", $0) }.joined()
        case .sha512:
            let digest = SHA512.hash(data: data)
            hashString = digest.map { String(format: "%02x", $0) }.joined()
        }
        
        outputText = uppercase ? hashString.uppercased() : hashString
    }
}
