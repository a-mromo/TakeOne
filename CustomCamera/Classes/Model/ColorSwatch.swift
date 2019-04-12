//
//  ColorSwatch.swift
//  CustomCamera
//
//  Created by Agustin Mendoza Romo on 4/8/19.
//  Copyright © 2019 Agustin Mendoza Romo. All rights reserved.
//

import UIKit

struct ColorSwatch: Codable {
    var name: String
    private var colorHexValue: String
    
    var color: UIColor? {
        return UIColor(hex: self.colorHexValue)
    }
    
}

extension ColorSwatch {
    private enum CodingKeys: String, CodingKey {
        case name = "Name"
        case colorHexValue = "HexValue"
    }
}
