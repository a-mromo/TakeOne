//
//  UIImage+Extension.swift
//  CustomCamera
//
//  Created by Agustin Mendoza Romo on 4/11/19.
//  Copyright © 2019 Agustin Mendoza Romo. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    class func createTransparentImageFrom(label: UILabel, imageSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 2.0)
        let currentView = UIView.init(frame: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
        currentView.backgroundColor = UIColor.clear
        currentView.addSubview(label)
        
        currentView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
}

