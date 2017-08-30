//
//  ViewController.swift
//  TryARKit
//
//  Created by Juncheng Han on 8/29/17.
//  Copyright © 2017 Jason H. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var alertView: AlertView!
    
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
        
        // addTestModel()
    }
    
    func addTestModel() {
        
        let tableScene = SCNScene(named: "art.scnassets/wooden-desk-1/wooden-desk-1.dae")
        
        if let tableNode = tableScene?.rootNode.childNode(withName: "GX-037", recursively: true) {
            
            print(tableNode)
            
            // Set position
            let position: SCNVector3 = SCNVector3Make(
                0,
                0,
                -2
            )
            
            tableNode.position = position
            
            sceneView.scene.rootNode.addChildNode(tableNode)
        }
        
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
        
        /**
         Determines whether the view will update the scene’s lighting.
         
         @discussion When set, the view will automatically create and update lighting for
         light estimates the session provides. Defaults to YES.
         */
        sceneView.automaticallyUpdatesLighting = true
        
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
        let tableScene = SCNScene(named: "art.scnassets/wooden-desk-1/wooden-desk-1.dae")
        
        if let tableNode = tableScene?.rootNode.childNode(withName: "GX-037", recursively: true) {
        
            // Set position
            let position: SCNVector3 = SCNVector3Make(
                result.worldTransform.columns.3.x,
                result.worldTransform.columns.3.y,
                result.worldTransform.columns.3.z
            )
            
            print(position)
            
            tableNode.position = position
            
            nodesInScene.append(tableNode)
            
            sceneView.scene.rootNode.addChildNode(tableNode)
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
            for node in planeNodes.values {
                
                let normalMaterial = SCNMaterial()
                normalMaterial.diffuse.contents = UIImage(named: "art.scnassets/plane-area.png")
         
                node.geometry?.materials = [normalMaterial]
            }
        } else {
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
        
        arViewConfig.showStatistics = enabled
        
        self.sceneView.showsStatistics = enabled;
    }
    
}

extension ViewController: ARSCNViewDelegate {
    
    //MARK: ARSessionObserver methods
    // Responding to Tracking Quality Changes
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        let trackingState = camera.trackingState
        
        switch trackingState {
        case .limited(.initializing):
            showMessage("ARCamera is initializing")
        case .limited(.insufficientFeatures):
            showMessage("Limited tracking: too few feature points, view areas with more textures")
        case .limited(.excessiveMotion):
            showMessage("Limited tracking: slow down the movement of the device")
        case .notAvailable:
            showMessage("Camera tracking is not available on this device")
        case .normal:
            showMessage("ARCamera tracking is normal")
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



