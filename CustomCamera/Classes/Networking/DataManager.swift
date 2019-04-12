//
//  DataManager.swift
//  CustomCamera
//
//  Created by Agustin Mendoza Romo on 4/10/19.
//  Copyright © 2019 Agustin Mendoza Romo. All rights reserved.
//

import Foundation

enum DataManagerError: Error {
    
    case Unknown
    case FailedRequest
    case InvalidResponse
}

final class DataManager {
    
    typealias WeatherDataCompletion = (WeatherData?, DataManagerError?) -> ()
    
    let baseURL: URL
    
    init(baseURL: URL) {
        self.baseURL = baseURL
    }
    
    func weatherDataForLocation(latitude: Double, longitude: Double, completion: @escaping WeatherDataCompletion) {
        
        let URL = baseURL.appendingPathComponent("\(latitude), \(longitude)")
        
        URLSession.shared.dataTask(with: URL) { (data, response, error) in
            DispatchQueue.main.async {
                self.didFetchWeatherData(data: data, response: response, error: error, completion: completion)
            }
        }.resume()
    }
    
    func didFetchWeatherData(data: Data?, response: URLResponse?, error: Error?, completion: WeatherDataCompletion) {
        if let _ = error {
            completion(nil, .FailedRequest)
            
        } else if let data = data, let response = response as? HTTPURLResponse {
            if response.statusCode == 200 {
                parseWeatherData(data: data, completion: completion)
            } else {
                completion(nil, .FailedRequest)
            }
        } else {
            completion (nil, .Unknown)
        }
    }
    
    func parseWeatherData(data: Data, completion: WeatherDataCompletion) {
        
        do {
            let decoder = JSONDecoder()
            let weatherData = try decoder.decode(WeatherData.self, from: data)
            completion(weatherData, nil)
        } catch _ {
            completion(nil, .InvalidResponse)
        }
    }
}
