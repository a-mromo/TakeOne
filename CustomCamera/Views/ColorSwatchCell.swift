//
//  ColorSwatchCell.swift
//  CustomCamera
//
//  Created by Agustin Mendoza Romo on 4/8/19.
//  Copyright © 2019 Agustin Mendoza Romo. All rights reserved.
//

import UIKit

class ColorSwatchCell: UICollectionViewCell {
    
    static let identifier = "ColorSwatchCell"
    private var indexPath: IndexPath!
    
    @IBOutlet weak var colorView: UIView!
    
    func configure(from colorSwatch: ColorSwatch, indexPath: IndexPath) {
        self.indexPath = indexPath
        self.colorView.backgroundColor = colorSwatch.color
    }
    
    
}
