import SwiftUI

struct URLToolView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                Text("参数解析").tag(0)
                Text("URL 编解码").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            
            if selectedTab == 0 {
                URLParserView()
            } else {
                URLEncodeView()
            }
        }
        .navigationTitle("URL 工具")
    }
}

#Preview {
    URLToolView()
}
