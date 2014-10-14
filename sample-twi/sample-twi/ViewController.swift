import UIKit
import CoreBluetooth
import QuartzCore
import SceneKit

class ViewController: UIViewController, CBCentralManagerDelegate {
    
    var centralManager:CBCentralManager!
    var blueToothReady = false
    var scene:SCNScene!
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        // create a new scene
        scene = SCNScene() //(named: "art.scnassets/ship.dae")
        
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
        //TODO(alex): adding a material doesn't seem to work
        let boxMaterial = SCNMaterial()
        boxMaterial.reflective.contents = UIImage(named: "checker.png")
        box.materials?.append(boxMaterial)
        
        let boxNode = SCNNode(geometry: box)
        boxNode.name = "box"
        
        let keyframeAnimation = CAKeyframeAnimation(keyPath: "rotation")
        keyframeAnimation.timingFunction = CAMediaTimingFunction()
        
        
        // Add animation
        let spin = CABasicAnimation(keyPath: "rotation")
        spin.toValue = NSValue(SCNVector4: SCNVector4(x: 1, y: 1.0, z: 0.0, w: Float(2.0*M_PI)))
        spin.duration = 3
        spin.repeatCount = HUGE // for infinity
        boxNode.addAnimation(spin, forKey: "spin")
        
        scene.rootNode.addChildNode(boxNode)
        
        
        // retrieve the SCNView
        let scnView = self.view as SCNView
        
        // set the scene to the view
        scnView.scene = scene
        
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        scnView.showsStatistics = true
        
        // configure the view
        scnView.backgroundColor = UIColor.blackColor()
        
        // Start bluetooth and get data from Twi devices
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
                    if let raw = value as? NSData {
                        let desc = raw.description
                        
                        //Example: <59002c01 fcfa703e 0000ffff fcff>
                        let bytes = desc.componentsSeparatedByString(" ")
                        // ignore <5900 and take 4 - ask this guy: https://github.com/honnet (Cédric Honnet)
                        let ax = (bytes[0] as NSString).substringFromIndex(5) //2c01
                        let ay = (bytes[1] as NSString).substringToIndex(4) //fcfa
                        let az = (bytes[1] as NSString).substringFromIndex(5) //703e
                        let yaw = (bytes[2] as NSString).substringToIndex(4) //0000
                        let pitch = (bytes[2] as NSString).substringFromIndex(4) //ffff
                        let roll = (bytes[3] as NSString).substringToIndex(4) //fcff
                        
                        //let axFloat *Float = 1
                        //let scanner = NSScanner(string:ax)
                        //scanner.scanHexFloat(result:axFloat)
                        
                        println("Bytes: \(desc)")
                        println("ax: \(ax) | ay: \(ay) | az: \(ax)") // calibrated in  +/-2g, bounds: (-2**12 , 2**12 - 1)
                        println("yaw: \(yaw) | pitch: \(pitch) | roll: \(roll)") // signed degrees: (-180, 180)
                    }
                    
                    for node in scene.rootNode.childNodes {
                        let n = node as? SCNNode
                        if n?.name == "box" {
                            let animation = n?.animationForKey("spin") as CABasicAnimation
                        }
                    }
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


