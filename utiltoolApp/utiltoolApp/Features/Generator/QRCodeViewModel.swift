import Foundation
import CoreImage.CIFilterBuiltins
import AppKit
import Vision
import UniformTypeIdentifiers

@Observable
class QRCodeViewModel {
    enum Mode {
        case generate
        case recognize
    }
    
    var mode: Mode = .generate
    
    // MARK: - Generate State
    var generateInput: String = "" {
        didSet { generate() }
    }
    var generatedImage: NSImage?
    var generateError: String?
    
    // MARK: - Recognize State
    var recognizeImage: NSImage? {
        didSet { recognize() }
    }
    var recognizedText: String = ""
    var recognizeError: String?
    
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()
    
    // MARK: - Actions
    func generate() {
        guard !generateInput.isEmpty else {
            generatedImage = nil
            generateError = nil
            return
        }
        
        let data = Data(generateInput.utf8)
        filter.setValue(data, forKey: "inputMessage")
        
        if let outputImage = filter.outputImage {
            // 默认生成的图片非常小，需要放大以便清晰显示
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                generatedImage = NSImage(cgImage: cgImage, size: .zero)
                generateError = nil
            } else {
                generateError = "生成图片失败"
            }
        }
    }
    
    func recognize() {
        guard let image = recognizeImage else {
            recognizedText = ""
            recognizeError = nil
            return
        }
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            recognizedText = ""
            recognizeError = "无法读取图片数据"
            return
        }
        
        let request = VNDetectBarcodesRequest { [weak self] request, error in
            guard let self = self else { return }
            
            if let error = error {
                self.recognizeError = "识别错误: \(error.localizedDescription)"
                self.recognizedText = ""
                return
            }
            
            guard let results = request.results as? [VNBarcodeObservation], let first = results.first else {
                self.recognizeError = "未在图片中检测到二维码或条形码"
                self.recognizedText = ""
                return
            }
            
            self.recognizedText = first.payloadStringValue ?? "无法提取内容"
            self.recognizeError = nil
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            recognizeError = "处理请求失败: \(error.localizedDescription)"
            recognizedText = ""
        }
    }
    
    func saveGeneratedImage() {
        guard let image = generatedImage else { return }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.nameFieldStringValue = "QRCode.png"
        
        savePanel.begin { result in
            if result == .OK, let url = savePanel.url {
                if let tiffData = image.tiffRepresentation, let bitmapImage = NSBitmapImageRep(data: tiffData) {
                    let pngData = bitmapImage.representation(using: .png, properties: [:])
                    try? pngData?.write(to: url)
                }
            }
        }
    }
    
    func selectImageToRecognize() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.image]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        
        openPanel.begin { [weak self] result in
            if result == .OK, let url = openPanel.url, let image = NSImage(contentsOf: url) {
                DispatchQueue.main.async {
                    self?.recognizeImage = image
                }
            }
        }
    }
}
