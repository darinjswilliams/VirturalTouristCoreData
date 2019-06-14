//
//  EndPoints.swift
//  VirtualTourist
//
//  Created by Darin Williams on 5/15/19.
//  Copyright © 2019 dwilliams. All rights reserved.
//

import Foundation

enum EndPoints {
    
    
    
    
    case loginBase
    case apiKeyFlicker
    case secretFlickr
    case getAuthentication(Double, Double)
    case getPhotos(Int, Double, Double)
    case searchForPhotoById(Int)
    case getImageUrl(Int, String, String, String)
    
    
    
    var stringValue: String {
        switch self {
        case .loginBase: return "https://api.flickr.com/services/rest?api_key="
            
        case .apiKeyFlicker:
            return AuthenticationUtils.apiKey
            
        case .secretFlickr:
            return AuthenticationUtils.secret
            
        case .getAuthentication(let latitude, let longitude):
            return EndPoints.loginBase.stringValue + EndPoints.apiKeyFlicker.stringValue + "&method=flickr.photos.search&format=json&tags=&accuracy=11&nojsoncallback=1&lat=\(latitude)&lon=\(longitude)"
            
        case .getPhotos(let pageNo, let latitude, let longitude):
            return EndPoints.loginBase.stringValue + EndPoints.apiKeyFlicker.stringValue +
            "&method=flickr.photos.search&format=json&tags=&per_page=20&page=\(pageNo)&accuracy=12&nojsoncallback=1&lat=\(latitude)&lon=\(longitude)&radius=6"
        case .getImageUrl(let farm, let serverID, let id, let secret):
            return  "https://farm\(farm).staticflickr.com/\(serverID)/\(id)_\(secret).jpg"
            
        case .searchForPhotoById(let id):
            return EndPoints.loginBase.stringValue + EndPoints.apiKeyFlicker.stringValue +
            "&method=flickr.photos.getInfo&format=json&nojsoncallback=1&&photo_id=\(id)"
        }
    }
    
    var url: URL {
        return URL(string: stringValue)!
    }
}

