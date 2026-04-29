import SwiftUI
import AppKit

@Observable
class ColorConvertViewModel {
    var hex: String = "#007AFF" {
        didSet { if !isUpdating { updateFromHex() } }
    }
    
    // RGB
    var r: Double = 0
    var g: Double = 122/255
    var b: Double = 255/255
    var a: Double = 1.0
    
    // HSL
    var h: Double = 0.58  // 0~1 (0-360度)
    var s: Double = 1.0   // 0~1 (0-100%)
    var l: Double = 0.5   // 0~1 (0-100%)
    
    // CMYK
    var c: Double = 1.0   // 0~1
    var m: Double = 0.52  // 0~1
    var y: Double = 0.0   // 0~1
    var k: Double = 0.0   // 0~1
    
    var color: Color = .blue
    
    private var isUpdating = false
    
    func updateFromColorPicker(_ newColor: Color) {
        isUpdating = true
        self.color = newColor
        
        if let nsColor = NSColor(newColor).usingColorSpace(.sRGB) {
            r = Double(nsColor.redComponent)
            g = Double(nsColor.greenComponent)
            b = Double(nsColor.blueComponent)
            a = Double(nsColor.alphaComponent)
            
            updateOtherFormatsFromRGB()
        }
        isUpdating = false
    }
    
    func updateFromHex() {
        isUpdating = true
        var cleanHex = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cleanHex.hasPrefix("#") { cleanHex.removeFirst() }
        
        if cleanHex.count == 6 {
            var rgbValue: UInt64 = 0
            Scanner(string: cleanHex).scanHexInt64(&rgbValue)
            
            r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
            g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
            b = Double(rgbValue & 0x0000FF) / 255.0
            a = 1.0
            
            updateOtherFormatsFromRGB()
        }
        isUpdating = false
    }
    
    func updateFromRGB() {
        isUpdating = true
        updateOtherFormatsFromRGB()
        isUpdating = false
    }
    
    // 私有辅助：给定确定的 RGB，更新 HSL, CMYK, HEX, Color
    private func updateOtherFormatsFromRGB() {
        color = Color(red: r, green: g, blue: b, opacity: a)
        hex = String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
        
        // 计算 CMYK
        k = 1.0 - max(r, max(g, b))
        if k == 1.0 {
            c = 0; m = 0; y = 0
        } else {
            c = (1.0 - r - k) / (1.0 - k)
            m = (1.0 - g - k) / (1.0 - k)
            y = (1.0 - b - k) / (1.0 - k)
        }
        
        // 计算 HSL
        let minRGB = min(r, min(g, b))
        let maxRGB = max(r, max(g, b))
        let delta = maxRGB - minRGB
        
        l = (maxRGB + minRGB) / 2.0
        
        if delta == 0 {
            h = 0
            s = 0
        } else {
            s = l < 0.5 ? delta / (maxRGB + minRGB) : delta / (2.0 - maxRGB - minRGB)
            
            let delR = (((maxRGB - r) / 6.0) + (delta / 2.0)) / delta
            let delG = (((maxRGB - g) / 6.0) + (delta / 2.0)) / delta
            let delB = (((maxRGB - b) / 6.0) + (delta / 2.0)) / delta
            
            if r == maxRGB {
                h = delB - delG
            } else if g == maxRGB {
                h = (1.0 / 3.0) + delR - delB
            } else if b == maxRGB {
                h = (2.0 / 3.0) + delG - delR
            }
            
            if h < 0 { h += 1 }
            if h > 1 { h -= 1 }
        }
    }
}
