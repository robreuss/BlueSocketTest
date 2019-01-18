import Foundation
import ElementalController

let eid_testDoubleElement: Int8 = 1
let serviceName = "blue"
var elementalController = ElementalController()
var clientDevice: ClientDevice?
var serverDevice: ServerDevice?

class Main {
    
    func runClient() {
        
        elementalController.setupForBrowsingAs(deviceNamed: "Blue Client")
        
        elementalController.browser.events.foundServer.handler { serverDevice in
            
            let element = serverDevice.attachElement(Element(identifier: eid_testDoubleElement, displayName: "eid_testDoubleElement", proto: .tcp, dataType: .Double))
            
            element.handler = { element, _ in
                print("Value: \(element.value)")
                
            }
            
            serverDevice.events.deviceDisconnected.handler = { _ in
                logDebug("Server disconnected handler fired")
            }
            
            serverDevice.events.connected.handler = { (device) in
                logDebug("Client is connected handler fired")
                
                let serverDevice = device as! ServerDevice
                
                var keepSending = true
                while keepSending == true {
                    
                    let element = device.getElementWith(identifier: eid_testDoubleElement)
                    //elementEcho!.value = Date().timeIntervalSince1970
                    element!.value = Date().timeIntervalSince1970
                    do {
                        try serverDevice.send(element: element!)
                        
                    } catch {
                        logDebug("Element failed to send: \(error)")
                        keepSending = false
                    }
                    
                    
                }
                
            }
            
            serverDevice.connect()
            
        }
        
        elementalController.browser.browseFor(serviceName: serviceName)
    }
    
    func runServer() {
        
        elementalController.setupForService(serviceName: serviceName, displayName: "")
        
        elementalController.service.events.deviceDisconnected.handler = { _, _ in
            logDebug("Device disconnected handler fired")
        }
        
        elementalController.service.events.deviceConnected.handler = { _, device in
            
            clientDevice = device as! ClientDevice
            
            let element = device.attachElement(Element(identifier: eid_testDoubleElement, displayName: "eid_testDoubleElement", proto: .tcp, dataType: .Double))
            
            element.handler = { element, device in
                logDebug("Recieved test element: \(element.value)")
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
