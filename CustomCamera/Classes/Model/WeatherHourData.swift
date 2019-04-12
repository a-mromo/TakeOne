//
//  WeatherHourData.swift
//  CustomCamera
//
//  Created by Agustin Mendoza Romo on 4/11/19.
//  Copyright © 2019 Agustin Mendoza Romo. All rights reserved.
//

import Foundation

struct WeatherHourData: Codable {
    
    let time: Date
    let windSpeed: Double
    let temperature: Double
    let precipitation: Double
}

extension WeatherHourData {
    private enum CodingKeys: String, CodingKey {
        case time, windSpeed, temperature
        case precipitation = "precipIntensity"
    }
}

struct HourlyWeatherData: Codable {
    let data: [WeatherHourData]
}
