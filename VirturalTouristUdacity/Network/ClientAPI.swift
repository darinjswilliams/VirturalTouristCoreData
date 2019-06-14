//
//  ClientAPI.swift
//  VirturalTouristUdacity
//
//  Created by Darin Williams on 6/8/19.
//  Copyright © 2019 dwilliams. All rights reserved.
//

import Foundation
import UIKit

class ClientAPI {
    

class func processPhotos(url: URL, completionHandler: @escaping (FlickerResponse?, Error?)-> Void){
    
    taskForGETRequest(url: url, response: FlickerResponse.self) { (response, error) in
        guard let response = response else {
            print("requestforPhotos: Failed")
            DispatchQueue.main.async {
                completionHandler(nil, error)
            }
            return
        }
        DispatchQueue.main.async {
            completionHandler(response, error)
        }
    }
}


class func getPhotoLocationByPageNumber(url: URL, completionHandler: @escaping (FlickerResponse?, Error?)-> Void){
    
    
    //Set the limit on amount of objects returned
    
    self.taskForGETRequest(url: url, response: FlickerResponse.self) { (response, error) in
        guard let response = response else {
            print("getPhotos: Failed")
            DispatchQueue.main.async {
                completionHandler(nil, error)
            }
            return
        }
        DispatchQueue.main.async {
            completionHandler(response, error)
        }
    }
}


class func taskForGETRequest<ResponseType: Decodable>(url: URL,response: ResponseType.Type,  completionHandler: @escaping (ResponseType?, Error?) -> Void) -> URLSessionDataTask {
    
    var request = URLRequest(url: url)
    
    request.httpMethod = AuthenticationUtils.headerGet
    
    print("here is the url \(request)")
    
    
    let downloadTask = URLSession.shared.dataTask(with: request) {
        (data, response, error) in
        // guard there is data
        guard let data = data else {
            // TODO: CompleteHandler can return error
            DispatchQueue.main.async {
                completionHandler(nil, error)
            }
            return
        }
        
        let jsonDecoder = JSONDecoder()
        do {
            let result = try? jsonDecoder.decode(ResponseType.self, from: data)
            
            DispatchQueue.main.async {
                completionHandler(result, nil)
            }
            
        } catch {
            DispatchQueue.main.async {
                completionHandler(nil,error)
            }
        }
    }
    
    downloadTask.resume()
    
    return downloadTask
}


class func taskDownLoadPhotosData(url: URL, completionHandler: @escaping (UIImage?, Error?) -> Void) {
    
    let downloadTask = URLSession.shared.dataTask(with: url, completionHandler: {
        (data, response, error) in
        // guard there is data
        guard let data = data else {
            // TODO: CompleteHandler can return error
            completionHandler(nil, error)
            
            return
        }
        
        let downloadedImage: UIImage = UIImage(data: data)!
        completionHandler(downloadedImage, nil)
    })
    downloadTask.resume()
    
}

}
