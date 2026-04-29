import Foundation
import CoreBluetooth
import SwiftUI

struct DiscoveredPeripheral: Identifiable {
    let id: UUID
    let peripheral: CBPeripheral
    var name: String?
    var rssi: Int
    var advertisementData: [String: Any]
}

struct DiscoveredCharacteristic: Identifiable {
    let id = UUID()
    let characteristic: CBCharacteristic
    var valueStr: String?
}

@Observable
class BluetoothViewModel: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, CBPeripheralManagerDelegate {
    
    // MARK: - Central State
    var isCentralScanning = false
    var centralStateStr: String = "Unknown"
    var discoveredPeripherals: [DiscoveredPeripheral] = []
    var selectedPeripheral: CBPeripheral?
    var connectedPeripheral: CBPeripheral?
    
    var discoveredCharacteristics: [DiscoveredCharacteristic] = []
    
    // MARK: - Peripheral State
    var isPeripheralAdvertising = false
    var peripheralStateStr: String = "Unknown"
    var serverServiceUUIDStr: String = "FFE0"
    var serverCharacteristicUUIDStr: String = "FFE1"
    var serverMockResponse: String = "Hello from utiltoolApp"
    var receivedMessagesLogs: [String] = []
    
    // MARK: - Managers
    private var centralManager: CBCentralManager!
    private var peripheralManager: CBPeripheralManager!
    
    private var mutableCharacteristic: CBMutableCharacteristic?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Central Actions
    func toggleScan() {
        if isCentralScanning {
            centralManager.stopScan()
            isCentralScanning = false
        } else {
            discoveredPeripherals.removeAll()
            centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
            isCentralScanning = true
        }
    }
    
    func connect(to peripheral: CBPeripheral) {
        centralManager.stopScan()
        isCentralScanning = false
        selectedPeripheral = peripheral
        centralManager.connect(peripheral, options: nil)
    }
    
    func disconnect() {
        if let p = connectedPeripheral {
            centralManager.cancelPeripheralConnection(p)
        }
    }
    
    func read(characteristic: CBCharacteristic) {
        connectedPeripheral?.readValue(for: characteristic)
    }
    
    func write(data: Data, to characteristic: CBCharacteristic) {
        let type: CBCharacteristicWriteType = characteristic.properties.contains(.writeWithoutResponse) ? .withoutResponse : .withResponse
        connectedPeripheral?.writeValue(data, for: characteristic, type: type)
    }
    
    // MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        centralStateStr = central.state.stringValue
        if central.state != .poweredOn {
            isCentralScanning = false
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        DispatchQueue.main.async {
            if let index = self.discoveredPeripherals.firstIndex(where: { $0.id == peripheral.identifier }) {
                self.discoveredPeripherals[index].rssi = RSSI.intValue
                if let name = peripheral.name {
                    self.discoveredPeripherals[index].name = name
                }
            } else {
                let newP = DiscoveredPeripheral(id: peripheral.identifier, peripheral: peripheral, name: peripheral.name, rssi: RSSI.intValue, advertisementData: advertisementData)
                self.discoveredPeripherals.append(newP)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        DispatchQueue.main.async {
            self.connectedPeripheral = peripheral
            self.discoveredCharacteristics.removeAll()
            peripheral.delegate = self
            peripheral.discoverServices(nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            if self.connectedPeripheral?.identifier == peripheral.identifier {
                self.connectedPeripheral = nil
                self.discoveredCharacteristics.removeAll()
            }
        }
    }
    
    // MARK: - CBPeripheralDelegate
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let chars = service.characteristics else { return }
        DispatchQueue.main.async {
            for c in chars {
                let dc = DiscoveredCharacteristic(characteristic: c)
                self.discoveredCharacteristics.append(dc)
                if c.properties.contains(.read) {
                    peripheral.readValue(for: c)
                }
                if c.properties.contains(.notify) {
                    peripheral.setNotifyValue(true, for: c)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        let str = String(data: data, encoding: .utf8) ?? data.map { String(format: "%02x", $0) }.joined()
        
        DispatchQueue.main.async {
            if let idx = self.discoveredCharacteristics.firstIndex(where: { $0.characteristic.uuid == characteristic.uuid }) {
                self.discoveredCharacteristics[idx].valueStr = str
            }
        }
    }
    
    // MARK: - Server Actions
    func toggleAdvertising() {
        if isPeripheralAdvertising {
            peripheralManager.stopAdvertising()
            peripheralManager.removeAllServices()
            isPeripheralAdvertising = false
        } else {
            startServer()
        }
    }
    
    private func startServer() {
        guard peripheralManager.state == .poweredOn else { return }
        
        let serviceUUID = CBUUID(string: serverServiceUUIDStr)
        let charUUID = CBUUID(string: serverCharacteristicUUIDStr)
        
        let characteristic = CBMutableCharacteristic(
            type: charUUID,
            properties: [.read, .write, .notify],
            value: nil,
            permissions: [.readable, .writeable]
        )
        self.mutableCharacteristic = characteristic
        
        let service = CBMutableService(type: serviceUUID, primary: true)
        service.characteristics = [characteristic]
        
        peripheralManager.add(service)
        peripheralManager.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [serviceUUID],
            CBAdvertisementDataLocalNameKey: "UtilTool Server"
        ])
        
        isPeripheralAdvertising = true
        receivedMessagesLogs.append("[\(Date().formatted())] Started advertising Service: \(serverServiceUUIDStr)")
    }
    
    func logServerMsg(_ msg: String) {
        DispatchQueue.main.async {
            self.receivedMessagesLogs.insert("[\(Date().formatted())] \(msg)", at: 0)
        }
    }
    
    // MARK: - CBPeripheralManagerDelegate
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        peripheralStateStr = peripheral.state.stringValue
        if peripheral.state != .poweredOn {
            isPeripheralAdvertising = false
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        let responseData = serverMockResponse.data(using: .utf8) ?? Data()
        if request.offset > responseData.count {
            peripheral.respond(to: request, withResult: .invalidOffset)
            return
        }
        
        request.value = responseData.subdata(in: request.offset..<responseData.count)
        peripheral.respond(to: request, withResult: .success)
        logServerMsg("Client Read. Replied with: \(serverMockResponse)")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for req in requests {
            if let val = req.value {
                let str = String(data: val, encoding: .utf8) ?? val.map { String(format: "%02x", $0) }.joined()
                logServerMsg("Client Written: \(str)")
            }
            peripheral.respond(to: req, withResult: .success)
        }
    }
}

extension CBManagerState {
    var stringValue: String {
        switch self {
        case .unknown: return "Unknown"
        case .resetting: return "Resetting"
        case .unsupported: return "Unsupported"
        case .unauthorized: return "Unauthorized"
        case .poweredOff: return "Powered Off"
        case .poweredOn: return "Powered On"
        @unknown default: return "Fatal"
        }
    }
}
