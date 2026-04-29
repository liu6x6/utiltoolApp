import SwiftUI
import Cocoa
import UniformTypeIdentifiers

struct QRCodeView: View {
    @State private var viewModel = QRCodeViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // 模式选择控制栏
            HStack {
                Picker("操作模式", selection: $viewModel.mode) {
                    Text("生成二维码").tag(QRCodeViewModel.Mode.generate)
                    Text("识别二维码").tag(QRCodeViewModel.Mode.recognize)
                }
                .pickerStyle(.segmented)
                .frame(width: 250)
                
                Spacer()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            // 主内容区
            if viewModel.mode == .generate {
                generateView
            } else {
                recognizeView
            }
        }
        .navigationTitle("二维码工具")
    }
    
    // MARK: - 生成视图
    private var generateView: some View {
        HStack(spacing: 20) {
            // 输入区
            VStack(alignment: .leading) {
                Text("输入文本或 URL")
                    .font(.headline)
                
                TextEditor(text: $viewModel.generateInput)
                    .font(.system(.body, design: .monospaced))
                    .padding(4)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            }
            
            Divider()
            
            // 结果区
            VStack {
                Text("生成的二维码")
                    .font(.headline)
                
                Spacer()
                
                if let image = viewModel.generatedImage {
                    Image(nsImage: image)
                        .interpolation(.none) // 保持像素清晰，防止模糊
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .padding(10)
                        .background(Color.white) // 给二维码加白底
                        .cornerRadius(8)
                        .shadow(radius: 2)
                    
                    Button("保存为图片...") {
                        viewModel.saveGeneratedImage()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 20)
                } else if let error = viewModel.generateError {
                    Text(error)
                        .foregroundColor(.red)
                } else {
                    Text("在左侧输入内容自动生成")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
    }
    
    // MARK: - 识别视图
    private var recognizeView: some View {
        HStack(spacing: 20) {
            // 图片选择区
            VStack {
                Text("选择或拖入包含二维码的图片")
                    .font(.headline)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [10]))
                        .foregroundColor(.secondary.opacity(0.5))
                        .background(Color(NSColor.controlBackgroundColor))
                    
                    if let image = viewModel.recognizeImage {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .padding()
                    } else {
                        VStack(spacing: 10) {
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("点击选择图片")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onTapGesture {
                    viewModel.selectImageToRecognize()
                }
                // 简单的拖拽支持
                .onDrop(of: [.image], isTargeted: nil) { providers in
                    if let provider = providers.first {
                        let type = UTType.image.identifier
                        if provider.hasItemConformingToTypeIdentifier(type) {
                            provider.loadDataRepresentation(forTypeIdentifier: type) { data, error in
                                if let data = data, let image = NSImage(data: data) {
                                    DispatchQueue.main.async {
                                        viewModel.recognizeImage = image
                                    }
                                }
                            }
                            return true
                        }
                    }
                    return false
                }
                .frame(maxWidth: 300)
            }
            
            Divider()
            
            // 解析结果区
            VStack(alignment: .leading) {
                Text("解析结果")
                    .font(.headline)
                
                if let error = viewModel.recognizeError {
                    Text(error)
                        .foregroundColor(.red)
                        .padding(.vertical, 8)
                }
                
                TextEditor(text: .constant(viewModel.recognizedText))
                    .font(.system(.body, design: .monospaced))
                    .padding(4)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            }
        }
        .padding()
    }
}

#Preview {
    QRCodeView()
}
