import SwiftUI
import UniformTypeIdentifiers

struct Base64ImageView: View {
    @State private var viewModel = Base64ImageViewModel()
    
    var body: some View {
        HStack(spacing: 20) {
            
            // 左侧：图片区域
            VStack(alignment: .leading) {
                Text("图片预览 / 拖入图片 (PNG, JPG)")
                    .font(.headline)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [10]))
                        .foregroundColor(.secondary.opacity(0.5))
                        .background(Color(NSColor.controlBackgroundColor))
                    
                    if let image = viewModel.image {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .padding()
                    } else {
                        VStack(spacing: 10) {
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("点击选择或拖入图片")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onTapGesture {
                    viewModel.selectImage()
                }
                .onDrop(of: [.image], isTargeted: nil) { providers in
                    if let provider = providers.first {
                        let type = UTType.image.identifier
                        if provider.hasItemConformingToTypeIdentifier(type) {
                            provider.loadDataRepresentation(forTypeIdentifier: type) { data, error in
                                if let data = data, let image = NSImage(data: data) {
                                    DispatchQueue.main.async {
                                        viewModel.encodeImage(image)
                                    }
                                }
                            }
                            return true
                        }
                    }
                    return false
                }
                
                if viewModel.image != nil {
                    Button("保存解码后的图片...") {
                        viewModel.saveImage()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 10)
                }
            }
            .frame(maxWidth: .infinity)
            
            Divider()
            
            // 右侧：Base64 字符串区域
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Base64 字符串")
                        .font(.headline)
                    Spacer()
                    Button(action: {
                        let pb = NSPasteboard.general
                        pb.clearContents()
                        pb.setString(viewModel.base64Text, forType: .string)
                    }) {
                        Label("复制", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                    
                    Button(action: { viewModel.base64Text = "" }) {
                        Label("清空", systemImage: "trash")
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.red)
                }
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                TextEditor(text: $viewModel.base64Text)
                    .font(.system(.caption, design: .monospaced))
                    .padding(4)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            }
            .frame(maxWidth: .infinity)
            
        }
        .padding()
    }
}

#Preview {
    Base64ImageView()
}
