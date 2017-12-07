//
//  ViewController.swift
//  TryARKit
//
//  Created by Juncheng Han on 8/29/17.
//  Copyright © 2017 Jason H. All rights reserved.
//

import UIKit
import ARKit
import Vision

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var alertView: AlertView!
    
    var lastPosition: SCNVector3?
    
//    let testNode: SCNNode = {
//        let testModelScene = SCNScene(named: "art.scnassets/lolipop.dae")
//        let node = (testModelScene?.rootNode.childNode(withName: "Lollipop_headusOBJexport", recursively: true)!)!
//        //node.scale = SCNVector3(0.007, 0.005, 0.005)
//
//        node.position = SCNVector3(0, 0, 100)
//        return node
//    }()
    
    var highlightView: UIView = {
        let view = UIView(frame: .zero)
        view.layer.borderColor = UIColor.red.cgColor
        view.layer.borderWidth = 4
        view.backgroundColor = .clear
        
        return view
    }()
    
    
    var layers = [CALayer]()
    let lolipops = [SCNNode]()
    
    let faceDetectQueue = DispatchQueue(label: "com.tryARKit.faceDetectQueue")
    
    // Timer for
    var timer: Timer?
    
    var planeNodes = [UUID : SCNNode]()
    var nodesInScene = [SCNNode]()
    var currentTrackingState: ARCamera.TrackingState = .normal
    
    var arViewConfig: ARViewConfigure = ARViewConfigure(showFeaturePoints: true, showPlanes: true, detectPlanes: true, showStatistics: true)
    
    let arConfiguration: ARConfiguration = {
        if ARWorldTrackingConfiguration.isSupported {
            let config = ARWorldTrackingConfiguration()
            
            // By default, open plane detection
            config.planeDetection = .horizontal
            
            return config
        } else {
            let config = AROrientationTrackingConfiguration()
            
            return config
        }
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupScene()
        
        setupFocusSquare()
        
        // setupTimer()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide the navigation controller
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        // Run the arsession with configuration
        sceneView.session.run(arConfiguration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }

    private func setupScene() {
     
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Show Feature Points by default
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        sceneView.preferredFramesPerSecond = 60
        sceneView.contentScaleFactor = 1.3
        
        sceneView.scene.lightingEnvironment.intensity = 25
        
        if let camera = sceneView.pointOfView?.camera {
            camera.wantsHDR = true
            camera.wantsExposureAdaptation = true
            camera.exposureOffset = -1
            camera.minimumExposure = -1
        }
        
        /**
         Determines whether the view will update the scene’s lighting.
         
         @discussion When set, the view will automatically create and update lighting for
         light estimates the session provides. Defaults to YES.
         */
        sceneView.automaticallyUpdatesLighting = true
        
//        // Add single tap on the sceneView
//        let singleTap = UITapGestureRecognizer(target: self, action: #selector(taped))
//        sceneView.addGestureRecognizer(singleTap)
        
        
//        sceneView.scene.rootNode.addChildNode(testNode)
        
    }
    
    private func setupTimer() {
        
        timer = Timer(timeInterval: 2.0, target: self, selector: #selector(addLolipop), userInfo: nil, repeats: true)
        RunLoop.current.add(timer!, forMode: .commonModes)
        
    }
    
    
    
    @objc func addLolipop() {
        faceDetectQueue.async {
            if let currentFrame = self.sceneView.session.currentFrame {
                self.detectFaceAt(frame: currentFrame)
            }
        }
    }
    
    @objc func taped(recognizer: UITapGestureRecognizer) {
        
        print("taped")
        highlightView.removeFromSuperview()
        highlightView.frame.size = CGSize(width:120, height:120)
        highlightView.center = recognizer.location(in: view)
        view.addSubview(highlightView)
        
        // convert the rect for the initial observation
        let originalRect = self.highlightView.frame
        // var convertedRect = sceneView.scene.
            //self.cameraLayer.metadataOutputRectConverted(fromLayerRect: originalRect)
//        convertedRect.origin.y = 1 - convertedRect.origin.y
//        
//        // set the observation
//        let newObservation = VNDetectedObjectObservation(boundingBox: convertedRect)
//        self.lastObservation = newObservation
        
        
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            // Get 2D location point from ARSCNView
            let touchLocation = touch.location(in: sceneView)
            
            // Get all hit results from existing planes
            let results = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
            
            guard !results.isEmpty else {
                return
            }
            
            // Get the closest plane hit result (ARHitTestResult)
            if let result = results.first {
                addTestModelAt(result: result)
            }
            
        }
    }
    
    fileprivate func addTestModelAt(result: ARHitTestResult) {
        // Create a new scene
        let testModelScene = SCNScene(named: "art.scnassets/dog/shibainu.dae")
        
        if let testModelNode = testModelScene?.rootNode.childNode(withName: "shibainu", recursively: true) {
        
            // Set position
            let position: SCNVector3 = SCNVector3Make(
                result.worldTransform.columns.3.x,
                result.worldTransform.columns.3.y,
                result.worldTransform.columns.3.z
            )
            
            print(position)
            
            testModelNode.position = position
            
            nodesInScene.append(testModelNode)
            
            sceneView.scene.rootNode.addChildNode(testModelNode)
        }
    }
    
    // MARK:IBActions
    
    @IBAction func showFeaturePoints(_ sender: UISwitch) {
        let enabled = sender.isOn
        
        arViewConfig.showFeaturePoints = enabled
        
        if enabled {
            sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints];
        } else {
            sceneView.debugOptions = [];
        }
    }
    
    @IBAction func showPlanes(_ sender: UISwitch) {
        let enabled = sender.isOn
        
        if arViewConfig.showPlanes == enabled {
            return
        }
        
        arViewConfig.showPlanes = enabled
        
        if enabled {
            
            focusSquare.unhide()
            
            for node in planeNodes.values {
                
                let normalMaterial = SCNMaterial()
                normalMaterial.diffuse.contents = UIImage(named: "art.scnassets/plane-area.png")
         
                node.geometry?.materials = [normalMaterial]
            }
        } else {
            
            focusSquare.hide()
            
            for node in planeNodes.values {
                
                let transparentMaterial = SCNMaterial()
                transparentMaterial.diffuse.contents = UIColor.clear
                
                node.geometry?.materials = [transparentMaterial]
            }
        }
        
    }
    
    @IBAction func detectPlanes(_ sender: UISwitch) {
        let enabled = sender.isOn
        
        if enabled == arViewConfig.detectPlanes {
            return
        }
        
        arViewConfig.detectPlanes = enabled
        
        disableDetectPlane(disabled: !enabled)
    }
    
    fileprivate func disableDetectPlane(disabled: Bool) {
        guard arConfiguration is ARWorldTrackingConfiguration else {
            return
        }
        if disabled {
            // ARPlaneDetectionNone = 0
            (arConfiguration as! ARWorldTrackingConfiguration).planeDetection = .init(rawValue: 0)
        } else {
            (arConfiguration as! ARWorldTrackingConfiguration).planeDetection = .horizontal
        }
        
        sceneView.session.run(arConfiguration)
    }
    
    @IBAction func showStatistics(_ sender: UISwitch) {
        let enabled = sender.isOn
        
        if enabled {
            setupTimer()
            timer?.fire()
        } else {
            timer?.invalidate()
        }
        // arViewConfig.showStatistics = enabled
        
        // self.sceneView.showsStatistics = enabled;
    }
    
    // MARK: - Focus Square
    
    var focusSquare = FocusSquare()
    
    func setupFocusSquare() {
        focusSquare.unhide()
        focusSquare.removeFromParentNode()
        sceneView.scene.rootNode.addChildNode(focusSquare)
    }
    
    func updateFocusSquare() {
        let (worldPosition, planeAnchor, _) = worldPositionFromScreenPosition(view.center, objectPos: focusSquare.position)
        if let worldPosition = worldPosition {
            focusSquare.update(for: worldPosition, planeAnchor: planeAnchor, camera: sceneView.session.currentFrame?.camera)
        }
    }

    
}

extension ViewController: ARSCNViewDelegate {
    
    //MARK: ARSessionObserver methods
    // Responding to Tracking Quality Changes
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        let trackingState = camera.trackingState
        
        switch trackingState {
        case .limited(let reason):
            switch reason {
            case .excessiveMotion:
                showMessage("Limited tracking: slow down the movement of the device")
            case .insufficientFeatures:
                showMessage("Limited tracking: too few feature points, view areas with more textures")
            case .initializing:
                showMessage("AR Tracking is initializing")
            }
        case .notAvailable:
            showMessage("AR tracking is not available on this device")
        case .normal:
            showMessage("AR tracking is normal")
        }
    }
    
    /**
     This is called when a session fails.
     
     @discussion On failure the session will be paused.
     @param session The session that failed.
     @param error The error being reported (see ARError.h).
     */
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Show error message
        showAlertControllerWith(title: "Error", message: error.localizedDescription)
    }
    
    /**
     This is called when a session interruption has ended.
     
     @discussion A session will continue running from the last known state once
     the interruption has ended. If the device has moved, anchors will be misaligned.
     To avoid this, some applications may want to reset tracking (see ARSessionRunOptions).
     @param session The session that was interrupted.
     */
    func sessionWasInterrupted(_ session: ARSession) {
        alertView.addMessage("The tracking session has been interrupted")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        alertView.addMessage("Tracking session has been reset due to interruption")
        resetTrackingSession()
    }
    
    fileprivate func resetTrackingSession() {
        // Remove planes in planeNodes
        planeNodes.removeAll()
        
        // Remove all objects in planeNodes
        nodesInScene.removeAll()
        
        // Rest session
        sceneView.session.run(arConfiguration, options: [.removeExistingAnchors, .resetTracking])
    }
    
    fileprivate func showMessage(_ message: String) {
        alertView.addMessage(message)
    }
    
    fileprivate func showAlertControllerWith(title:String, message: String) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .cancel) { _ in
            
        }
        alertController.addAction(alertAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    //MARK: ARSCNViewDelegate
    /**
     Implement this to provide a custom node for the given anchor.
     
     @discussion This node will automatically be added to the scene graph.
     If this method is not implemented, a node will be automatically created.
     If nil is returned the anchor will be ignored.
     @param renderer The renderer that will render the scene.
     @param anchor The added anchor.
     @return Node that will be mapped to the anchor or nil.
     */
//    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
//
//    }
    
    
    /**
     Called when a new node has been mapped to the given anchor.
     
     @param renderer The renderer that will render the scene.
     @param node The node that maps to the anchor.
     @param anchor The added anchor.
     */
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // Add plane to the gound
        if anchor is ARPlaneAnchor {
            
            let planeAnchor = anchor as! ARPlaneAnchor
            
            let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
            
            let planeNode = SCNNode()
            planeNode.name = "planeNode"
            planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
            planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2.0, 1, 0, 0)
            
            let material = SCNMaterial()
            material.diffuse.contents = UIImage(named: "art.scnassets/plane-area.png")
            
            plane.materials = [material]
            
            planeNode.geometry = plane
            
            node.addChildNode(planeNode)
            
            planeNodes[anchor.identifier] = planeNode
            
        } else {
            return
        }
    }
    
    /*!
     @method renderer:updateAtTime:
     @abstract Implement this to perform per-frame game logic. Called exactly once per frame before any animation and actions are evaluated and any physics are simulated.
     @param renderer The renderer that will render the scene.
     @param time The time at which to update the scene.
     @discussion All modifications done within this method don't go through the transaction model, they are directly applied on the presentation tree.
     */
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        
        DispatchQueue.main.async {
            self.updateFocusSquare()
        }
    }
    
    
    
    
    /**
     Called when a node has been updated with data from the given anchor.
     
     @param renderer The renderer that will render the scene.
     @param node The node that was updated.
     @param anchor The anchor that was updated.
     */
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // update the plane
        if anchor is ARPlaneAnchor {
            
            let planeAnchor = anchor as! ARPlaneAnchor
            
            if let planeNode = planeNodes[anchor.identifier] {
                if let oldPlane = planeNode.geometry {
                    
                    let newPlane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
                    newPlane.materials = oldPlane.materials
                    
                    planeNode.geometry = newPlane
                }
            }
            
        } else {
            return
        }
    }
}

extension ViewController {
    
    // Code from Apple PlacingObjects demo: https://developer.apple.com/sample-code/wwdc/2017/PlacingObjects.zip
    
    func worldPositionFromScreenPosition(_ position: CGPoint,
                                         objectPos: SCNVector3?,
                                         infinitePlane: Bool = false) -> (position: SCNVector3?, planeAnchor: ARPlaneAnchor?, hitAPlane: Bool) {
        
        // -------------------------------------------------------------------------------
        // 1. Always do a hit test against exisiting plane anchors first.
        //    (If any such anchors exist & only within their extents.)
        
        let planeHitTestResults = sceneView.hitTest(position, types: .existingPlaneUsingExtent)
        if let result = planeHitTestResults.first {
            
            let planeHitTestPosition = SCNVector3.positionFromTransform(result.worldTransform)
            let planeAnchor = result.anchor
            
            // Return immediately - this is the best possible outcome.
            return (planeHitTestPosition, planeAnchor as? ARPlaneAnchor, true)
        }
        
        // -------------------------------------------------------------------------------
        // 2. Collect more information about the environment by hit testing against
        //    the feature point cloud, but do not return the result yet.
        
        var featureHitTestPosition: SCNVector3?
        var highQualityFeatureHitTestResult = false
        
        let highQualityfeatureHitTestResults = sceneView.hitTestWithFeatures(position, coneOpeningAngleInDegrees: 18, minDistance: 0.2, maxDistance: 2.0)
        
        if !highQualityfeatureHitTestResults.isEmpty {
            let result = highQualityfeatureHitTestResults[0]
            featureHitTestPosition = result.position
            highQualityFeatureHitTestResult = true
        }
        
        // -------------------------------------------------------------------------------
        // 3. If desired or necessary (no good feature hit test result): Hit test
        //    against an infinite, horizontal plane (ignoring the real world).
        
        let dragOnInfinitePlanesEnabled = false
        
        if (infinitePlane && dragOnInfinitePlanesEnabled) || !highQualityFeatureHitTestResult {
            
            let pointOnPlane = objectPos ?? SCNVector3Zero
            
            let pointOnInfinitePlane = sceneView.hitTestWithInfiniteHorizontalPlane(position, pointOnPlane)
            if pointOnInfinitePlane != nil {
                return (pointOnInfinitePlane, nil, true)
            }
        }
        
        // -------------------------------------------------------------------------------
        // 4. If available, return the result of the hit test against high quality
        //    features if the hit tests against infinite planes were skipped or no
        //    infinite plane was hit.
        
        if highQualityFeatureHitTestResult {
            return (featureHitTestPosition, nil, false)
        }
        
        // -------------------------------------------------------------------------------
        // 5. As a last resort, perform a second, unfiltered hit test against features.
        //    If there are no features in the scene, the result returned here will be nil.
        
        let unfilteredFeatureHitTestResults = sceneView.hitTestWithFeatures(position)
        if !unfilteredFeatureHitTestResults.isEmpty {
            let result = unfilteredFeatureHitTestResults[0]
            return (result.position, nil, false)
        }
        
        return (nil, nil, false)
    }
}

