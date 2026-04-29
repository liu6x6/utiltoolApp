import SwiftUI
import AppKit

struct BaseConvertView: View {
    @State private var viewModel = BaseConvertViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // 控制栏 / 错误提示
            HStack {
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                } else {
                    Text("在任意输入框中输入数值，其他进制将自动同步")
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("清空") {
                    viewModel.clear()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            // 交互区
            ScrollView {
                VStack(spacing: 20) {
                    EditableBaseRow(label: "十进制 (Decimal - 10)", text: $viewModel.decimal)
                    EditableBaseRow(label: "十六进制 (Hexadecimal - 16)", text: $viewModel.hex)
                    EditableBaseRow(label: "二进制 (Binary - 2)", text: $viewModel.binary)
                    EditableBaseRow(label: "八进制 (Octal - 8)", text: $viewModel.octal)
                }
                .padding(30)
            }
        }
        .navigationTitle("进制转换")
    }
}

fileprivate struct EditableBaseRow: View {
    let label: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.plain)
                .help("复制")
            }
            
            TextField("", text: $text, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .font(.system(.title2, design: .monospaced))
                .lineLimit(1...5)
        }
    }
}

#Preview {
    BaseConvertView()
}
