import SwiftUI
import Combine

class NavigationState: ObservableObject {
    @Published var selectedItem: ToolItem? = .jsonFormat
}
