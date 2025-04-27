//
//  API.swift
//  ubTestTask
//
//  Created by Ivan_Tests on 27.04.2025.
//

import Foundation

enum CameraType:String {
    case NAVCAM, PANCAM, FHAZ, RHAZ
    var lowercasedValue:String {
        self.rawValue.lowercased()
    }
}

enum API {
    
    
    case bySOL(page:Int, cameraType:CameraType)
    
}

extension API {
    var urlParameters:[String:Any] {
        switch self {
        case .bySOL(let page, let cameraType):
            return ["page":page, "camera":cameraType.lowercasedValue]
        }
    }
    
    var baseURL:String {
        "https://api.nasa.gov/mars-photos/api/v1/rovers/curiosity/photos"
    }
}
