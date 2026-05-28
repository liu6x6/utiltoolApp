import SwiftUI
import AppKit
import CodeEditor

enum CodeTextLanguage {
    case plainText
    case json
    case xml
    case yaml
    case swift
    case typescript
    case go
    case python
    case javascript
    case shell
    case markdown
    case sql
    case http
    case html
    case diff
    case csv
    
    var codeEditorLanguage: CodeEditor.Language? {
        switch self {
        case .plainText, .csv:
            return nil
        case .json:
            return .json
        case .xml, .html:
            return .xml
        case .yaml:
            return .yaml
        case .swift:
            return .swift
        case .typescript:
            return .typescript
        case .go:
            return .go
        case .python:
            return .python
        case .javascript:
            return .javascript
        case .shell:
            return .shell
        case .markdown:
            return .markdown
        case .sql:
            return .sql
        case .http:
            return .http
        case .diff:
            return .diff
        }
    }
}

struct CodeTextView: View {
    @Binding var text: String
    
    var language: CodeTextLanguage? = nil
    var isEditable: Bool = true
    var showsLineNumbers: Bool = true
    
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("codeTextEditor.fontSize") private var storedFontSize: Double = 13
    
    var body: some View {
        HStack(spacing: 0) {
            if showsLineNumbers {
                lineNumberGutter
            }
            
            CodeEditor(
                source: $text,
                language: language?.codeEditorLanguage,
                theme: editorTheme,
                fontSize: Binding(
                    get: { CGFloat(storedFontSize) },
                    set: { storedFontSize = Double($0) }
                ),
                flags: isEditable ? .defaultEditorFlags : .defaultViewerFlags,
                indentStyle: .softTab(width: 2),
                inset: CGSize(width: 12, height: 10)
            )
        }
        .background(Color(NSColor.textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var editorTheme: CodeEditor.ThemeName {
        colorScheme == .dark ? .agate : .atelierSavannaLight
    }
    
    private var lineNumberGutter: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .trailing, spacing: 0) {
                ForEach(1...lineCount, id: \.self) { line in
                    Text("\(line)")
                        .font(.system(size: CGFloat(storedFontSize), weight: .regular, design: .monospaced))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, 8)
                        .frame(height: gutterLineHeight, alignment: .topTrailing)
                }
            }
            .padding(.vertical, 10)
        }
        .frame(width: gutterWidth)
        .background(Color(NSColor.controlBackgroundColor))
        .allowsHitTesting(false)
    }
    
    private var lineCount: Int {
        max(text.components(separatedBy: .newlines).count, 1)
    }
    
    private var gutterWidth: CGFloat {
        CGFloat(max(String(lineCount).count, 2)) * 10 + 20
    }
    
    private var gutterLineHeight: CGFloat {
        max(CGFloat(storedFontSize) * 1.45, 18)
    }
}
