import Foundation
import AppKit
import UniformTypeIdentifiers

@Observable
class Base64ImageViewModel {
    var base64Text: String = "" {
        didSet { if !isEncoding { decodeBase64() } }
    }
    
    var image: NSImage?
    var errorMessage: String?
    
    private var isEncoding = false
    
    // MARK: - Actions
    func encodeImage(_ nsImage: NSImage) {
        isEncoding = true
        self.image = nsImage
        
        if let tiffData = nsImage.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let pngData = bitmap.representation(using: .png, properties: [:]) {
            // 给前端用的格式默认加上 Data URI 前缀
            base64Text = "data:image/png;base64," + pngData.base64EncodedString()
            errorMessage = nil
        } else {
            errorMessage = "图片编码失败，可能不是受支持的格式"
        }
        
        isEncoding = false
    }
    
    func decodeBase64() {
        guard !base64Text.isEmpty else {
            image = nil
            errorMessage = nil
            return
        }
        
        var cleanBase64 = base64Text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 智能剥离可能的 Data URI Scheme, 如: "data:image/png;base64,iVBORw0K..."
        if cleanBase64.hasPrefix("data:") {
            if let commaIndex = cleanBase64.firstIndex(of: ",") {
                cleanBase64 = String(cleanBase64[cleanBase64.index(after: commaIndex)...])
            }
        }
        
        if let data = Data(base64Encoded: cleanBase64),
           let nsImage = NSImage(data: data) {
            self.image = nsImage
            self.errorMessage = nil
        } else {
            self.image = nil
            self.errorMessage = "无效的 Base64 图片数据"
        }
    }
    
    func selectImage() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.image]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        
        openPanel.begin { [weak self] result in
            if result == .OK, let url = openPanel.url, let img = NSImage(contentsOf: url) {
                DispatchQueue.main.async {
                    self?.encodeImage(img)
                }
            }
        }
    }
    
    func saveImage() {
        guard let img = image else { return }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png, .jpeg]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.nameFieldStringValue = "Base64DecodedImage.png"
        
        savePanel.begin { result in
            if result == .OK, let url = savePanel.url {
                DispatchQueue.global(qos: .userInitiated).async {
                    if let tiffData = img.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiffData) {
                        let type: NSBitmapImageRep.FileType = url.pathExtension.lowercased() == "jpeg" ? .jpeg : .png
                        let data = bitmap.representation(using: type, properties: [:])
                        try? data?.write(to: url)
                    }
                }
            }
        }
    }
}
