import SwiftUI

struct BaseToolView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                Text("文本编解码").tag(0)
                Text("图片互转 (Base64)").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            
            if selectedTab == 0 {
                BaseEncodeView()
            } else {
                Base64ImageView()
            }
        }
        .navigationTitle("Base 编解码")
    }
}

#Preview {
    BaseToolView()
}
