//
//  PhotosModel.swift
//  VirtualTourist
//
//  Created by Darin Williams on 5/25/19.
//  Copyright © 2019 dwilliams. All rights reserved.
//

import Foundation

struct FlickerResponse: Codable {
    let photos: PublicPhoto
    let stat: String
    
}

struct PublicPhoto: Codable {
    let page, pages, perpage: Int
    let total: String
    let photo: [MyPhoto]
}

struct MyPhoto: Codable {
    let id, owner, secret, server: String
    let farm: Int
    let title: String
    let ispublic, isfriend, isfamily: Int
    
    func photoURL() -> URL {
        return URL(string: "https://farm\(farm).staticflickr.com/\(server)/\(id)_\(secret).jpg")!
    }
    
}

struct FlickrSearchPayload: Codable {
    let pageResults: SearchPageResult
    
    enum CodingKeys: String, CodingKey {
        case pageResults = "photo"
    }
}

struct SearchPageResult: Codable {
    let page, pages, perpage: Int
    let total, imageUrl: String
    let photoMeta: [PublicPhoto]
    
    
    enum CodingKeys: String, CodingKey {
        case page = "page"
        case pages = "pages"
        case perpage = "perpage"
        case total = "total"
        case photoMeta = "photo"
        case imageUrl = "imageUrl"
    }
}


struct TouristPhoto: Codable {
    
    let message: String
}

