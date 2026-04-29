import Foundation

class BrowserDelegate: NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
    var browser: NetServiceBrowser!
    var subBrowsers = [NetServiceBrowser]()
    var services = [NetService]()

    func start() {
        browser = NetServiceBrowser()
        browser.delegate = self
        print("Starting scan for _services._dns-sd._udp. in domain ''")
        browser.searchForServices(ofType: "_services._dns-sd._udp.", inDomain: "")
        browser.schedule(in: .main, forMode: .common)
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        if browser == self.browser {
            // It's meta
            var newType = service.name
            if service.type.hasPrefix("_tcp") {
                newType += "._tcp."
            } else if service.type.hasPrefix("_udp") {
                newType += "._udp."
            } else {
                newType += ".\(service.type)" // Fallback
            }
            
            let domain = (service.domain == "." || service.domain.isEmpty) ? "local." : service.domain
            print("Meta found! Dispatching sub-browser for type: \(newType) in domain: \(domain)")
            
            let subBrowser = NetServiceBrowser()
            subBrowser.delegate = self
            subBrowser.schedule(in: .main, forMode: .common)
            subBrowsers.append(subBrowser)
            subBrowser.searchForServices(ofType: newType, inDomain: domain)
        } else {
            print("Real Service Found: \(service.name) \(service.type)")
            services.append(service)
            service.delegate = self
            service.schedule(in: .main, forMode: .common)
            service.resolve(withTimeout: 5.0)
        }
    }
    
    func netServiceDidResolveAddress(_ sender: NetService) {
        print("Resolved Service: \(sender.name) - IP Count: \(sender.addresses?.count ?? 0)")
    }
    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print("Failed to resolve Service: \(sender.name) - \(errorDict)")
    }
}

let delegate = BrowserDelegate()
delegate.start()
RunLoop.main.run(until: Date(timeIntervalSinceNow: 5.0))
