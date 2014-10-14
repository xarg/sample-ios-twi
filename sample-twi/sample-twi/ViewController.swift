import UIKit
import CoreBluetooth
import QuartzCore
import SceneKit

class ViewController: UIViewController, CBCentralManagerDelegate {
    
    var centralManager:CBCentralManager!
    var blueToothReady = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        // create a new scene
        let scene = SCNScene() //(named: "art.scnassets/ship.dae")
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        
        // create and add a light to the scene
        let lightNode1 = SCNNode()
        lightNode1.light = SCNLight()
        lightNode1.light!.type = SCNLightTypeOmni
        lightNode1.light!.color = UIColor.whiteColor()
        lightNode1.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode1)
        
        //let lightNode2 = SCNNode()
        //lightNode2.light = SCNLight()
        //lightNode2.light!.type = SCNLightTypeOmni
        //lightNode2.light!.color = UIColor.purpleColor()
        //lightNode2.position = SCNVector3(x: 10, y: 1, z: 1)
        //scene.rootNode.addChildNode(lightNode2)
        //
        //let lightNode3 = SCNNode()
        //lightNode3.light = SCNLight()
        //lightNode3.light!.type = SCNLightTypeOmni
        //lightNode3.light!.color = UIColor.yellowColor()
        //lightNode3.position = SCNVector3(x: -20, y: -10, z: 10)
        //scene.rootNode.addChildNode(lightNode3)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLightTypeAmbient
        ambientLightNode.light!.color = UIColor.darkGrayColor()
        scene.rootNode.addChildNode(ambientLightNode)
        
        
        let box = SCNBox(width: 3, height: 3, length: 3, chamferRadius: 0.1)
        let boxMaterial = SCNMaterial()
        boxMaterial.reflective.contents = UIImage(named: "sphere.png")
        box.materials?.append(boxMaterial)
        
        let boxNode = SCNNode(geometry: box)
        
        // Add animation
        let spin = CABasicAnimation(keyPath: "rotation")
        spin.toValue = NSValue(SCNVector4: SCNVector4(x: 1, y: 1.0, z: 0.0, w: Float(2.0*M_PI)))
        spin.duration = 3
        spin.repeatCount = HUGE // for infinity
        boxNode.addAnimation(spin, forKey: "spin around")
        
        scene.rootNode.addChildNode(boxNode)
        
        
        // retrieve the SCNView
        let scnView = self.view as SCNView
        
        // set the scene to the view
        scnView.scene = scene
        
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        // scnView.showsStatistics = true
        
        // configure the view
        scnView.backgroundColor = UIColor.blackColor()
        
        startUpCentralManager()
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> Int {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return Int(UIInterfaceOrientationMask.AllButUpsideDown.toRaw())
        } else {
            return Int(UIInterfaceOrientationMask.All.toRaw())
        }
    }
    
    func startUpCentralManager() {
        println("Initializing central manager")
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func discoverDevices() {
        println("discovering devices")
        centralManager.scanForPeripheralsWithServices(nil, options: nil)
    }
    
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        if peripheral.name == "Twi" { // only track Twi devices
            for (key, value)  in advertisementData {
                if key == "kCBAdvDataManufacturerData" {
                    println("Position: \(value)")
                }
            }
        }
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        println("checking state")
        switch (central.state) {
        case .PoweredOff:
            println("CoreBluetooth BLE hardware is powered off")
            
        case .PoweredOn:
            println("CoreBluetooth BLE hardware is powered on and ready")
            blueToothReady = true;
            
        case .Resetting:
            println("CoreBluetooth BLE hardware is resetting")
            
        case .Unauthorized:
            println("CoreBluetooth BLE state is unauthorized")
            
        case .Unknown:
            println("CoreBluetooth BLE state is unknown");
            
        case .Unsupported:
            println("CoreBluetooth BLE hardware is unsupported on this platform");
            
        }
        if blueToothReady {
            discoverDevices()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}


