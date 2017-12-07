//
//  ViewController+DetectFace.swift
//  TryARKit
//
//  Created by Juncheng Han on 8/31/17.
//  Copyright © 2017 Jason H. All rights reserved.
//

import Foundation
import ARKit
import Vision

extension ViewController {
    
    //    CGImagePropertyOrientation:
    //    case up // 0th row at top,    0th column on left   - default orientation
    //
    //    case upMirrored // 0th row at top,    0th column on right  - horizontal flip
    //
    //    case down // 0th row at bottom, 0th column on right  - 180 deg rotation
    //
    //    case downMirrored // 0th row at bottom, 0th column on left   - vertical flip
    //
    //    case leftMirrored // 0th row on left,   0th column at top
    //
    //    case right // 0th row on right,  0th column at top    - 90 deg CW
    //
    //    case rightMirrored // 0th row on right,  0th column on bottom
    //
    //    case left // 0th row on left,   0th column at bottom - 90 deg CCW
    
    var exifOrientationFromDeviceOrientation: CGImagePropertyOrientation {
        let exifOrientation: CGImagePropertyOrientation

        switch UIDevice.current.orientation {
        case .portraitUpsideDown:
            exifOrientation = .left
        case .landscapeLeft:
            exifOrientation = .up
        case .landscapeRight:
            exifOrientation = .down
        default:
            exifOrientation = .right
        }
        return exifOrientation
    }
    
    
    func updateTestModelAtPoint(point: CGPoint) {
        let (worldPosition, _, _) = worldPositionFromScreenPosition(point, objectPos: lastPosition)
        if let worldPosition = worldPosition {
            let testModelScene = SCNScene(named: "art.scnassets/dog/shibainu.dae")
            let node = (testModelScene?.rootNode.childNode(withName: "shibainu", recursively: true)!)!
            node.position = worldPosition
            lastPosition = worldPosition
            sceneView.scene.rootNode.addChildNode(node)
        }
    }

    
    func detectFaceAt(frame: ARFrame) {
        //, completionHandler: ([CGSize], Error) -> Void) {
        
        let cvImageBuffer = frame.capturedImage
        let faceDetectionRequest = VNDetectFaceRectanglesRequest { (requst, error) in
            if error == nil {
                
                if let results = requst.results {
                    
                    DispatchQueue.main.async {
                        
//                        for layer in self.layers {
//                            layer.removeFromSuperlayer()
//                        }
                        
                        for result in results {
                            if result is VNFaceObservation {
                                
                                let observation = result as! VNFaceObservation
                                let oldRect = observation.boundingBox
                                
                                let w = oldRect.size.width * self.view.bounds.size.width
                                let h = oldRect.size.height * self.view.bounds.size.height
                                let x = oldRect.origin.x * self.view.bounds.size.width
                                let y = self.view.bounds.size.height - (oldRect.origin.y * self.view.bounds.size.height) - h
                            
//                                let rect = CGRect(x: x, y: y, width: w, height: h)
//                                let testLayer = CALayer()
//                                testLayer.borderWidth = 2;
//                                testLayer.cornerRadius = 3;
//                                testLayer.borderColor = UIColor.red.cgColor;
//                                testLayer.frame = rect;
//
//                                self.layers.append(testLayer)
//                                self.view.layer.addSublayer(testLayer)
                                
                                self.updateTestModelAtPoint(point: CGPoint(x:x+w/2.0, y:y+h/2.0))
                            }
                        }
                    }
                }
            }
        }
        
        let faceDetctionRequstHandler = VNImageRequestHandler(cvPixelBuffer: cvImageBuffer, orientation: self.exifOrientationFromDeviceOrientation, options: [:])
        
        do {
            try faceDetctionRequstHandler.perform([faceDetectionRequest])
        } catch {
            print(error.localizedDescription)
        }
        
    }
    
}
