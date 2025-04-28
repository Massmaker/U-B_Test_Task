//
//  API.swift
//  ubTestTask
//
//  Created by Ivan_Tests on 27.04.2025.
//

import Foundation

enum CameraType:String {
    case NAVCAM, PANCAM, FHAZ, RHAZ, all
    var lowercasedValue:String? {
        if case .all = self {
            return nil
        }
        return self.rawValue.lowercased()
    }
}

enum API {
    
    
    case bySOL(page:Int, cameraType:CameraType)
    
}

extension API {
    var urlParameters:[String:Any] {
        switch self {
        case .bySOL(let page, let cameraType):
            if let cameraValue = cameraType.lowercasedValue {
                return ["page":page, "camera":cameraValue]
            }
            else {
                return ["page":page]
            }
        }
    }
    
    var baseURL:String {
        "https://api.nasa.gov/mars-photos/api/v1/rovers/curiosity/photos"
    }
}
