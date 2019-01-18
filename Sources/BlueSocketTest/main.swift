import Foundation
import ElementalController

let eid_testDoubleElement: Int8 = 1
let eid_testStringElement: Int8 = 2


let serviceName = "blue"
var elementalController = ElementalController()
var clientDevice: ClientDevice?
var serverDevice: ServerDevice?

class Main {
    
    func runClient() {
        
        elementalController.setupForBrowsingAs(deviceNamed: "Blue Client")
        
        elementalController.browser.events.foundServer.handler { serverDevice in
            
            let doubleElement = serverDevice.attachElement(Element(identifier: eid_testDoubleElement, displayName: "eid_testDoubleElement", proto: .tcp, dataType: .Double))

            let stringElement = serverDevice.attachElement(Element(identifier: eid_testStringElement, displayName: "eid_testStringElement", proto: .tcp, dataType: .String))

            
            serverDevice.events.deviceDisconnected.handler = { _ in
                logDebug("Server disconnected handler fired")
            }
            
            serverDevice.events.connected.handler = { (device) in
                logDebug("Client is connected handler fired")
                
                let serverDevice = device as! ServerDevice
           
                var keepSending = true
                while keepSending == true {
                    
                    // -------------------------------
                    // This will send a DOUBLE and NOT result in a client disconnect (zero bytes read)
                    /*
                    let element = device.getElementWith(identifier: eid_testDoubleElement)
                    element!.value = Date().timeIntervalSince1970
                    do {
                        try serverDevice.send(element: element!)
                    } catch {
                        logDebug("Element failed to send: \(error)")
                        keepSending = false
                    }
                    */
                    //--------------------------------

                    
                    
                    //--------------------------------
                    // This will send a LONG STRING and result in a client disconnect (zero bytes read)
                    
                    let element = device.getElementWith(identifier: eid_testStringElement)
                    element!.value = String(repeating: "A", count: 100000)
                    do {
                        try serverDevice.send(element: element!)
                    } catch {
                        logDebug("Element failed to send: \(error)")
                        keepSending = false
                    }
                    
                    //--------------------------------
                    
                    usleep(1000)
                    
                    
                }
                
            }
            
            serverDevice.connect()
            
        }
        
        elementalController.browser.browseFor(serviceName: serviceName)
    }
    
    func runServer() {
  
        elementalController.setupForService(serviceName: serviceName, displayName: "")
        
        elementalController.service.events.deviceDisconnected.handler = { _, _ in
            logDebug("Client device disconnected handler fired")
        }
        
        elementalController.service.events.deviceConnected.handler = { _, device in

            let doubleElement = device.attachElement(Element(identifier: eid_testDoubleElement, displayName: "eid_testDoubleElement", proto: .tcp, dataType: .Double))
            
            doubleElement.handler = { element, device in
                //logDebug("Recieved Double element: \(doubleElement.value)")
            }
            
            let stringElement = device.attachElement(Element(identifier: eid_testStringElement, displayName: "eid_testStringElement", proto: .tcp, dataType: .String))
            
            stringElement.handler = { element, device in
                //logDebug("Recieved String element: \(stringElement.value)")
            }
            
        }
        
        do {
            try elementalController.service.publish(onPort: 0)
        } catch {
            logError("Publish error: \(error)")
        }

    }
}

var process = Main()
#if os(Linux)
    process.runServer()
#else
    process.runClient()
#endif

// Prevent our instance of MainProcess from being destroyed
withExtendedLifetime((process)) {
    RunLoop.main.run()
}
