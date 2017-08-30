//
//  AlertView.swift
//  TryARKit
//
//  Created by Juncheng Han on 8/30/17.
//  Copyright © 2017 Jason H. All rights reserved.
//

import UIKit

class AlertView: UIVisualEffectView {

    var currentMessage: String?
    var nextMessage: String?
    var timer: Timer?
    
    func addMessage(_ message: String) {
        nextMessage = message
        
        if currentMessage == nil {
            showNextMessage()
        }
    }
    
    @objc private func showNextMessage() {
        currentMessage = nextMessage
        nextMessage = nil
        
        if currentMessage == nil {
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveLinear, animations: {
                self.alpha = 0
            }, completion: nil)
            
            return
        }
        
        let label = contentView.subviews[0] as! UILabel
        label.text = currentMessage ?? ""
        
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveLinear, animations: {
            self.alpha = 1
        }) { (finish) in
            self.perform(#selector(self.showNextMessage), with: nil, afterDelay: 5)
        }
    }
}
