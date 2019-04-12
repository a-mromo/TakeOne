//
//  File.swift
//  CustomCamera
//
//  Created by Agustin Mendoza Romo on 4/11/19.
//  Copyright © 2019 Agustin Mendoza Romo. All rights reserved.
//

import Foundation

struct WeatherData: Codable {
    
    let lat: Double
    let long: Double
    let hourData: HourlyWeatherData
}

extension WeatherData {
    private enum CodingKeys: String, CodingKey {
        case lat = "latitude"
        case long = "longitude"
        case hourData = "hourly"
    }
}
