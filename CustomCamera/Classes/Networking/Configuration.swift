//
//  Configuration.swift
//  CustomCamera
//
//  Created by Agustin Mendoza Romo on 4/10/19.
//  Copyright © 2019 Agustin Mendoza Romo. All rights reserved.
//

import Foundation

struct API {

    static let APIKey = "b3c3371f0580a7421b25088249531f62"
    static let baseURL = URL(string: "https://api.darksky.net/forecast/")!

    static var authenticatedBaseURL: URL {
        return baseURL.appendingPathComponent(APIKey)
    }
}

struct Defaults {
    static let latitude: Double = 43.6591
    static let longitude: Double = 70.2568
}
