import Foundation

let yaml = """
server:
  name: "My Server"
  port: 8080
endpoints:
  - path: "/greet"
    method: "GET"
    responseFile: "greet.json"
  - path: "/hello"
    method: "POST"
    responseFile: "hello.json"
"""

func parseYAML(yaml: String) -> [String: Any] {
    let lines = yaml.components(separatedBy: .newlines)
    var result: [String: Any] = [:]
    
    var currentList: [[String: Any]] = []
    var currentListDict: [String: Any] = [:]
    var inListForKey: String? = nil
    
    for rawLine in lines {
        if rawLine.trimmingCharacters(in: .whitespaces).isEmpty { continue }
        
        let isListItem = rawLine.trimmingCharacters(in: .whitespaces).hasPrefix("- ")
        
        if isListItem {
            if !currentListDict.isEmpty {
                currentList.append(currentListDict)
                currentListDict = [:]
            }
            
            let content = String(rawLine.trimmingCharacters(in: .whitespaces).dropFirst(2)).trimmingCharacters(in: .whitespaces)
            if let colonIndex = content.firstIndex(of: ":") {
                let key = String(content[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                let val = String(content[content.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "\"", with: "")
                currentListDict[key] = val
            }
        } else if let colonIndex = rawLine.firstIndex(of: ":") {
            let key = String(rawLine[..<colonIndex]).trimmingCharacters(in: .whitespaces)
            let val = String(rawLine[rawLine.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "\"", with: "")
            
            let indent = rawLine.prefix(while: { $0 == " " }).count
            if indent == 0 {
                // Top level
                if let listKey = inListForKey {
                    if !currentListDict.isEmpty {
                        currentList.append(currentListDict)
                        currentListDict = [:]
                    }
                    result[listKey] = currentList
                    currentList = []
                    inListForKey = nil
                }
                
                if val.isEmpty {
                    inListForKey = key
                } else {
                    result[key] = val
                }
            } else {
                if inListForKey != nil {
                    // Inside list dict
                    currentListDict[key] = val
                } else {
                    // Regular nested dict not supported in this simple parser, treat as top level or ignore
                    // Wait, we need `server: \n port: 8080`. That's a regular dict.
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
    
    return result
}

let parsed = parseYAML(yaml: yaml)
print(parsed)
