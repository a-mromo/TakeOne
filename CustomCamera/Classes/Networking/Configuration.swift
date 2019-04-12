//
//  Configuration.swift
//  CustomCamera
//
//  Created by Agustin Mendoza Romo on 4/10/19.
//  Copyright © 2019 Agustin Mendoza Romo. All rights reserved.
//

import Foundation

struct API {

    static let APIKey = "DARKSKY_API_KEY"
    static let baseURL = URL(string: "https://api.darksky.net/forecast/")!

    static var authenticatedBaseURL: URL {
        return baseURL.appendingPathComponent(APIKey)
    }
}
