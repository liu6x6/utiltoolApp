import Foundation
import SwiftUI
import Observation

struct MDNSTxtRecord: Identifiable, Equatable {
    let id = UUID()
    var key: String
    var value: String
}

struct DiscoveredMDNSService: Identifiable, Equatable {
    let id = UUID()
    var service: NetService
    var isResolved: Bool = false
    var ipAddresses: [String] = []
    var txtRecords: [String: String] = [:]
    var resolveError: String? = nil
    
    static func == (lhs: DiscoveredMDNSService, rhs: DiscoveredMDNSService) -> Bool {
        return lhs.id == rhs.id &&
               lhs.isResolved == rhs.isResolved &&
               lhs.ipAddresses == rhs.ipAddresses &&
               lhs.txtRecords == rhs.txtRecords &&
               lhs.resolveError == rhs.resolveError
    }
}

@Observable
class MDNSViewModel: NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
    
    // MARK: - Browser State
    var isScanning = false
    var scanType: String = ""
    var scanDomain: String = ""
    var discoveredServices: [DiscoveredMDNSService] = []
    var selectedServiceId: UUID?
    
    private var serviceBrowser: NetServiceBrowser?
    private var subBrowsers: [NetServiceBrowser] = []
    private var resolvingServices: [NetService] = [] // Retain services during resolution
    private var scannedTypes: Set<String> = []
    
    // MARK: - Publisher State
    var isPublishing = false
    var pubName: String = "UtilTool_mDNS"
    var pubType: String = "_http._tcp."
    var pubPort: String = "8080"
    var pubTxtRecords: [MDNSTxtRecord] = [MDNSTxtRecord(key: "version", value: "1.0"), MDNSTxtRecord(key: "dev", value: "utiltool")]
    var pubLogs: [String] = []
    
    private var publishedService: NetService?
    
    // MARK: - Browser Actions
    func toggleScan() {
        if isScanning {
            serviceBrowser?.stop()
            serviceBrowser = nil
            for sub in subBrowsers {
                sub.stop()
            }
            subBrowsers.removeAll()
            isScanning = false
            for svc in resolvingServices {
                svc.stop()
            }
            resolvingServices.removeAll()
            scannedTypes.removeAll()
        } else {
            discoveredServices.removeAll()
            resolvingServices.removeAll()
            for sub in subBrowsers {
                sub.stop()
            }
            subBrowsers.removeAll()
            scannedTypes.removeAll()
            selectedServiceId = nil
            
            serviceBrowser = NetServiceBrowser()
            serviceBrowser?.delegate = self
            serviceBrowser?.schedule(in: .main, forMode: .common)
            
            let finalType = scanType.trimmingCharacters(in: .whitespaces).isEmpty ? "_services._dns-sd._udp." : scanType
            serviceBrowser?.searchForServices(ofType: finalType, inDomain: scanDomain)
            isScanning = true
        }
    }
    
    // MARK: - Publisher Actions
    func togglePublish() {
        if isPublishing {
            publishedService?.stop()
            publishedService = nil
            isPublishing = false
            logPub("Stopped broadcasting.")
        } else {
            guard let portInt = Int32(pubPort) else {
                logPub("Error: Invalid port number.")
                return
            }
            
            publishedService = NetService(domain: "local.", type: pubType, name: pubName, port: portInt)
            publishedService?.delegate = self
            publishedService?.schedule(in: .main, forMode: .common)
            
            var txtDict: [String: Data] = [:]
            for record in pubTxtRecords {
                if !record.key.isEmpty {
                    txtDict[record.key] = record.value.data(using: .utf8) ?? Data()
                }
            }
            
            if !txtDict.isEmpty {
                let txtData = NetService.data(fromTXTRecord: txtDict)
                publishedService?.setTXTRecord(txtData)
            }
            
            publishedService?.publish()
            isPublishing = true
            logPub("Attempting to publish service: \(pubName) (\(pubType)) on port \(portInt)...")
        }
    }
    
    func addTxtRecord() {
        pubTxtRecords.append(MDNSTxtRecord(key: "new_key", value: "new_value"))
    }
    
    func removeTxtRecord(id: UUID) {
        pubTxtRecords.removeAll { $0.id == id }
    }
    
    func logPub(_ msg: String) {
        DispatchQueue.main.async {
            self.pubLogs.insert("[\(Date().formatted())] \(msg)", at: 0)
        }
    }
    
    // MARK: - NetServiceBrowserDelegate
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        DispatchQueue.main.async {
            if browser === self.serviceBrowser && (self.scanType.trimmingCharacters(in: .whitespaces).isEmpty || self.scanType == "_services._dns-sd._udp." || self.scanType == "_services._dns-sd._udp") {
                // Discovering service TYPES
                // When browsing for _services._dns-sd._udp., the returned service has:
                // name = "_http", type = "_tcp.local.", domain = "."
                // To browse for it, the new type is "_http._tcp."
                var newType = service.name
                if service.type.hasPrefix("_tcp") {
                    newType += "._tcp."
                } else if service.type.hasPrefix("_udp") {
                    newType += "._udp."
                } else {
                    newType += ".\(service.type)"
                }
                
                let domain = (service.domain == "." || service.domain.isEmpty) ? "local." : service.domain
                
                let uniqueKey = newType + domain
                if !self.scannedTypes.contains(uniqueKey) {
                    self.scannedTypes.insert(uniqueKey)
                    
                    let newBrowser = NetServiceBrowser()
                    newBrowser.delegate = self
                    newBrowser.schedule(in: .main, forMode: .common)
                    newBrowser.searchForServices(ofType: newType, inDomain: domain)
                    self.subBrowsers.append(newBrowser)
                }
                return
            }
            
            // Avoid duplicate actual services
            if !self.discoveredServices.contains(where: { $0.service.name == service.name && $0.service.type == service.type }) {
                let discovered = DiscoveredMDNSService(service: service)
                self.discoveredServices.append(discovered)
            }
        }
    }
    
    func resolveService(id: UUID) {
        DispatchQueue.main.async {
            guard let index = self.discoveredServices.firstIndex(where: { $0.id == id }) else { return }
            
            self.discoveredServices[index].resolveError = nil // reset error
            
            let svc = self.discoveredServices[index].service
            if !self.resolvingServices.contains(svc) {
                self.resolvingServices.append(svc)
            }
            
            svc.stop() // Always stop before re-resolving
            svc.delegate = self
            svc.schedule(in: .main, forMode: .common) // THIS IS CRITICAL FOR RESOLUTION
            svc.resolve(withTimeout: 10.0) // Give it more time
        }
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        DispatchQueue.main.async {
            self.discoveredServices.removeAll { $0.service == service }
            self.resolvingServices.removeAll { $0 == service }
        }
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        DispatchQueue.main.async {
            self.isScanning = false
            print("Browser error: \(errorDict)")
        }
    }
    
    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        DispatchQueue.main.async {
            self.isScanning = false
        }
    }
    
    // MARK: - NetServiceDelegate
    func netServiceDidResolveAddress(_ sender: NetService) {
        DispatchQueue.main.async {
            if let index = self.discoveredServices.firstIndex(where: { $0.service == sender }) {
                self.discoveredServices[index].isResolved = true
                self.discoveredServices[index].ipAddresses = self.extractIPs(from: sender.addresses)
                
                if let txtData = sender.txtRecordData() {
                    self.discoveredServices[index].txtRecords = self.extractTXT(from: txtData)
                }
            }
        }
    }
    
    func netService(_ sender: NetService, didUpdateTXTRecord data: Data) {
        DispatchQueue.main.async {
            if let index = self.discoveredServices.firstIndex(where: { $0.service == sender }) {
                self.discoveredServices[index].txtRecords = self.extractTXT(from: data)
            }
        }
    }
    
    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        DispatchQueue.main.async {
            print("Failed to resolve service \(sender.name): \(errorDict)")
            if let index = self.discoveredServices.firstIndex(where: { $0.service === sender }) {
                self.discoveredServices[index].resolveError = "解析超时或失败 (\(errorDict))"
            }
        }
    }
    
    // Publisher delegates
    func netServiceDidPublish(_ sender: NetService) {
        logPub("Successfully published service: \(sender.name)")
    }
    
    func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        logPub("Failed to publish service: \(errorDict)")
        DispatchQueue.main.async {
            self.isPublishing = false
        }
    }
    
    // MARK: - Helpers
    private func extractIPs(from addresses: [Data]?) -> [String] {
        guard let addresses = addresses else { return [] }
        var result: [String] = []
        for data in addresses {
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            data.withUnsafeBytes { pointer in
                let sockaddrPtr = pointer.bindMemory(to: sockaddr.self).baseAddress!
                if getnameinfo(sockaddrPtr, socklen_t(data.count),
                               &hostname, socklen_t(hostname.count),
                               nil, 0, NI_NUMERICHOST) == 0 {
                    let ip = String(cString: hostname)
                    // IPv6 local interface scope ID removal for cleaner UI
                    if ip.contains("%") {
                        result.append(String(ip.split(separator: "%")[0]))
                    } else {
                        result.append(ip)
                    }
                }
            }
        }
        return Array(Set(result)) // Remove duplicates if any
    }
    
    private func extractTXT(from data: Data) -> [String: String] {
        let dict = NetService.dictionary(fromTXTRecord: data)
        var result: [String: String] = [:]
        for (k, v) in dict {
            if let str = String(data: v, encoding: .utf8) {
                result[k] = str
            } else {
                result[k] = "(Binary Data)"
            }
        }
        return result
    }
}
