import Foundation

/// RFC 4648 标准的 Base32 编解码实现
enum Base32 {
    private static let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")
    
    static func encode(_ data: Data) -> String {
        var result = ""
        var buffer: UInt32 = 0
        var bitsLeft = 0
        
        for byte in data {
            buffer = (buffer << 8) | UInt32(byte)
            bitsLeft += 8
            while bitsLeft >= 5 {
                let index = Int((buffer >> (bitsLeft - 5)) & 0x1F)
                result.append(alphabet[index])
                bitsLeft -= 5
            }
        }
        
        if bitsLeft > 0 {
            let index = Int((buffer << (5 - bitsLeft)) & 0x1F)
            result.append(alphabet[index])
        }
        
        let padCount = (8 - (result.count % 8)) % 8
        result.append(String(repeating: "=", count: padCount))
        return result
    }
    
    static func decode(_ string: String) -> Data? {
        var result = Data()
        var buffer: UInt32 = 0
        var bitsLeft = 0
        
        let cleanString = string.uppercased().replacingOccurrences(of: "=", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        
        for char in cleanString {
            guard let index = alphabet.firstIndex(of: char) else { return nil }
            buffer = (buffer << 5) | UInt32(index)
            bitsLeft += 5
            
            if bitsLeft >= 8 {
                let byte = UInt8((buffer >> (bitsLeft - 8)) & 0xFF)
                result.append(byte)
                bitsLeft -= 8
            }
        }
        return result
    }
}
