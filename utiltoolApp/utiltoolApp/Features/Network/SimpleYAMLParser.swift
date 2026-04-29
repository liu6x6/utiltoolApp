import Foundation

struct SimpleYAMLParser {
    static func parse(yaml: String) -> [String: Any] {
        let lines = yaml.components(separatedBy: .newlines)
        var result: [String: Any] = [:]
        
        var currentList: [[String: Any]] = []
        var currentListDict: [String: Any] = [:]
        var inListForKey: String? = nil
        var inDictForKey: String? = nil
        var currentDict: [String: Any] = [:]
        
        for rawLine in lines {
            let trimmed = rawLine.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
            
            let isListItem = trimmed.hasPrefix("- ")
            let indent = rawLine.prefix(while: { $0 == " " }).count
            
            if isListItem {
                if !currentListDict.isEmpty {
                    currentList.append(currentListDict)
                    currentListDict = [:]
                }
                
                let content = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                if let colonIndex = content.firstIndex(of: ":") {
                    let key = String(content[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                    let val = String(content[content.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "\"", with: "")
                    currentListDict[key] = val
                }
            } else if let colonIndex = rawLine.firstIndex(of: ":") {
                let key = String(rawLine[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                let val = String(rawLine[rawLine.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "\"", with: "")
                
                if indent == 0 {
                    // Save previous state
                    if let listKey = inListForKey {
                        if !currentListDict.isEmpty {
                            currentList.append(currentListDict)
                            currentListDict = [:]
                        }
                        result[listKey] = currentList
                        currentList = []
                        inListForKey = nil
                    }
                    if let dictKey = inDictForKey {
                        result[dictKey] = currentDict
                        currentDict = [:]
                        inDictForKey = nil
                    }
                    
                    if val.isEmpty {
                        // Look ahead to see if it's a list or dict
                        let nextLineIsList = lines.drop(while: { $0 != rawLine }).dropFirst().first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty })?.trimmingCharacters(in: .whitespaces).hasPrefix("- ") ?? false
                        
                        if nextLineIsList {
                            inListForKey = key
                        } else {
                            inDictForKey = key
                        }
                    } else {
                        result[key] = val
                    }
                } else {
                    // indented block
                    if inListForKey != nil {
                        currentListDict[key] = val
                    } else if inDictForKey != nil {
                        currentDict[key] = val
                    }
                }
            }
        }
        
        if let listKey = inListForKey {
            if !currentListDict.isEmpty {
                currentList.append(currentListDict)
            }
            result[listKey] = currentList
        }
        if let dictKey = inDictForKey {
            result[dictKey] = currentDict
        }
        
        return result
    }
}
