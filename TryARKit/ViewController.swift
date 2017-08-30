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
    
    let planeNodes = [UUID : SCNNode]()
    var currentTrackingState: ARCamera.TrackingState = .normal
    
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
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide the navigation controller
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        // Run the arsession with configuration
        sceneView.session.run(arConfiguration, options: ARSession.RunOptions(rawValue: 0))
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
    
    
    //MARK: ARSessionObserver method
    
    // Responding to Tracking Quality Changes
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        let trackingState = camera.trackingState
        
        print(trackingState)
        

        
        currentTrackingState = trackingState
        
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
    
    private func showMessage(_ message: String) {
        alertView.addMessage(message)
    }
}

extension ViewController: ARSCNViewDelegate {
    
    
    
}



