import Foundation
import AppKit

struct DiffChunk: Identifiable {
    let id = UUID()
    let type: DiffType
    let text: String
    
    enum DiffType {
        case unchanged
        case added
        case removed
    }
}

@Observable
class TextDiffViewModel {
    var leftText: String = "" {
        didSet { compare() }
    }
    
    var rightText: String = "" {
        didSet { compare() }
    }
    
    var diffResult: [DiffChunk] = []
    
    func compare() {
        guard !leftText.isEmpty || !rightText.isEmpty else {
            diffResult = []
            return
        }
        
        let leftLines = leftText.components(separatedBy: .newlines)
        let rightLines = rightText.components(separatedBy: .newlines)
        
        // 使用 macOS 原生的 NSOrderedCollectionDifference 进行比对
        let difference = rightLines.difference(from: leftLines)
        
        var result: [DiffChunk] = []
        
        // 简化版的按行差异可视化逻辑
        let diffs = rightLines.difference(from: leftLines)
        
        var appliedRight = leftLines
        
        for change in diffs {
            switch change {
            case let .remove(offset, element, _):
                appliedRight.remove(at: offset)
            case let .insert(offset, element, _):
                appliedRight.insert(element, at: offset)
            }
        }
        
        var leftIndex = 0
        var rightIndex = 0
        
        while leftIndex < leftLines.count || rightIndex < rightLines.count {
            let hasLeft = leftIndex < leftLines.count
            let hasRight = rightIndex < rightLines.count
            
            if hasLeft && hasRight && leftLines[leftIndex] == rightLines[rightIndex] {
                result.append(DiffChunk(type: .unchanged, text: leftLines[leftIndex]))
                leftIndex += 1
                rightIndex += 1
            } else {
                // 判断是删除还是新增
                if hasLeft && diffs.removals.contains(where: {
                    if case let .remove(offset, _, _) = $0 { return offset == leftIndex } else { return false }
                }) {
                    result.append(DiffChunk(type: .removed, text: leftLines[leftIndex]))
                    leftIndex += 1
                } else if hasRight && diffs.insertions.contains(where: {
                    if case let .insert(offset, _, _) = $0 { return offset == rightIndex } else { return false }
                }) {
                    result.append(DiffChunk(type: .added, text: rightLines[rightIndex]))
                    rightIndex += 1
                } else {
                    // Fallback，防止死循环
                    if hasLeft {
                        result.append(DiffChunk(type: .removed, text: leftLines[leftIndex]))
                        leftIndex += 1
                    }
                    if hasRight {
                        result.append(DiffChunk(type: .added, text: rightLines[rightIndex]))
                        rightIndex += 1
                    }
                }
            }
        }
        
        self.diffResult = result
    }
    
    func clear() {
        leftText = ""
        rightText = ""
        diffResult = []
    }
}
