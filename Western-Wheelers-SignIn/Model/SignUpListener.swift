import Foundation
//import CoreBluetooth
//https://www.raywenderlich.com/231-core-bluetooth-tutorial-for-ios-heart-rate-monitor
//https://developer.apple.com/library/archive/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/PerformingCommonPeripheralRoleTasks/PerformingCommonPeripheralRoleTasks.html#//apple_ref/doc/uid/TP40013257-CH4-SW1'
//https://uynguyen.github.io/2018/02/21/Play-Central-And-Peripheral-Roles-With-CoreBluetooth/

//class SignUpListener : NSObject, CBCentralManagerDelegate {
//    static let instance:SignUpListener = SignUpListener()
//    var centralManager: CBCentralManager!
//
//    func start() {
//        centralManager = CBCentralManager(delegate: self, queue: nil)
//        //centralManager?.scanForPeripherals(withServices: [CBUUIDs.BLEService_UUID])
//        centralManager?.scanForPeripherals(withServices: nil)
//    }
//    
//    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
//                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
//        print("BLUETOOTH DISC ===================")
//        print(peripheral)
//    }
//    
//    func centralManagerDidUpdateState(_ central: CBCentralManager) {
//        print("BLUETOOTH ===================")
//        switch central.state {
//          case .poweredOff:
//              print("Is Powered Off.")
//          case .poweredOn:
//              print("Is Powered On.")
//              //startScanning()
//          case .unsupported:
//              print("Is Unsupported.")
//          case .unauthorized:
//          print("Is Unauthorized.")
//          case .unknown:
//              print("Unknown")
//          case .resetting:
//              print("Resetting")
//          @unknown default:
//            print("Error")
//          }
//    }
//
//}
