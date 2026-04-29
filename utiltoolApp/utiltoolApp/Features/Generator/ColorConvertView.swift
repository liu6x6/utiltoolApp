import SwiftUI

struct ColorConvertView: View {
    @State private var viewModel = ColorConvertViewModel()
    
    var body: some View {
        VStack(spacing: 30) {
            HStack(spacing: 40) {
                // 颜色预览与选择
                VStack(spacing: 20) {
                    ColorPicker("选择颜色", selection: Binding(
                        get: { viewModel.color },
                        set: { viewModel.updateFromColorPicker($0) }
                    ))
                    .labelsHidden()
                    .scaleEffect(3.0)
                    .frame(width: 150, height: 150)
                    
                    RoundedRectangle(cornerRadius: 12)
                        .fill(viewModel.color)
                        .frame(width: 150, height: 100)
                        .shadow(radius: 4)
                }
                
                // 参数输入区
                VStack(alignment: .leading, spacing: 20) {
                    // HEX
                    HStack {
                        Text("HEX:")
                            .frame(width: 50, alignment: .leading)
                        TextField("", text: $viewModel.hex)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 120)
                            .font(.system(.body, design: .monospaced))
                        
                        Button {
                            copyToClipboard(text: viewModel.hex)
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // RGB
                    VStack(alignment: .leading, spacing: 10) {
                        Text("RGB:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        rgbSlider(label: "R", value: $viewModel.r)
                        rgbSlider(label: "G", value: $viewModel.g)
                        rgbSlider(label: "B", value: $viewModel.b)
                        
                        HStack {
                            Text("CSS:")
                            Text("rgb(\(Int(viewModel.r*255)), \(Int(viewModel.g*255)), \(Int(viewModel.b*255)))")
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                            Spacer()
                            Button {
                                copyToClipboard(text: "rgb(\(Int(viewModel.r*255)), \(Int(viewModel.g*255)), \(Int(viewModel.b*255)))")
                            } label: {
                                Image(systemName: "doc.on.doc")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    Divider()
                    
                    // HSL
                    VStack(alignment: .leading, spacing: 10) {
                        Text("HSL:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 20) {
                            Text("H: \(Int(viewModel.h * 360))°")
                            Text("S: \(Int(viewModel.s * 100))%")
                            Text("L: \(Int(viewModel.l * 100))%")
                        }
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        
                        HStack {
                            Text("CSS:")
                            Text("hsl(\(Int(viewModel.h * 360)), \(Int(viewModel.s * 100))%, \(Int(viewModel.l * 100))%)")
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                            Spacer()
                            Button {
                                copyToClipboard(text: "hsl(\(Int(viewModel.h * 360)), \(Int(viewModel.s * 100))%, \(Int(viewModel.l * 100))%)")
                            } label: {
                                Image(systemName: "doc.on.doc")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    Divider()
                    
                    // CMYK
                    VStack(alignment: .leading, spacing: 10) {
                        Text("CMYK:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 20) {
                            Text("C: \(Int(viewModel.c * 100))%")
                            Text("M: \(Int(viewModel.m * 100))%")
                            Text("Y: \(Int(viewModel.y * 100))%")
                            Text("K: \(Int(viewModel.k * 100))%")
                        }
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                    }
                }
            }
            .padding(40)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            .padding()
            
            Spacer()
        }
        .navigationTitle("颜色转换")
    }
    
    private func rgbSlider(label: String, value: Binding<Double>) -> some View {
        HStack {
            Text(label)
                .frame(width: 20)
            Slider(value: value, in: 0...1) {_ in 
                viewModel.updateFromRGB()
            }
            Text("\(Int(value.wrappedValue * 255))")
                .frame(width: 40, alignment: .trailing)
                .font(.system(.body, design: .monospaced))
        }
    }
    
    private func copyToClipboard(text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

#Preview {
    ColorConvertView()
}
