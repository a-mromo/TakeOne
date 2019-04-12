//
//  DraggableLabel.swift
//  CustomCamera
//
//  Created by Agustin Mendoza Romo on 4/12/19.
//  Copyright © 2019 Agustin Mendoza Romo. All rights reserved.
//

import UIKit

class DraggableLabel: UILabel{
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.isUserInteractionEnabled = true
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first;
        let location = touch?.location(in: self.superview);
        if(location != nil)
        {
            self.frame.origin = CGPoint(x: location!.x-self.frame.size.width/2, y: location!.y-self.frame.size.height/2);
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
}

extension DraggableLabel: NSCopying {
    func copy(with zone: NSZone? = nil) -> Any {
        let label = UILabel()
        label.textColor = self.textColor
        label.text = self.text
        label.font = self.font
        label.textAlignment =  self.textAlignment
        label.center = self.center
        label.frame = self.frame
        return label
    }
}
