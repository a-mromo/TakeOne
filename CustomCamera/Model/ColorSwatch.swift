//
//  ColorSwatch.swift
//  CustomCamera
//
//  Created by Agustin Mendoza Romo on 4/8/19.
//  Copyright © 2019 Agustin Mendoza Romo. All rights reserved.
//

import UIKit

struct ColorSwatch {
    var name: String
    var color: UIColor
    
    init(name: String, hexColor: String) {
        self.name = name
        self.color = UIColor(hex: hexColor) ?? UIColor.black
    }
    
    
    private struct JSONKeys {
        static let name = "Name"
        static let hexColor = "HexColor"
    }
}
