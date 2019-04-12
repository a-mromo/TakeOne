//
//  CopyableLabel.swift
//  CustomCamera
//
//  Created by Agustin Mendoza Romo on 4/12/19.
//  Copyright © 2019 Agustin Mendoza Romo. All rights reserved.
//

import UIKit

class CopyableLabel: UILabel, NSCopying {
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
