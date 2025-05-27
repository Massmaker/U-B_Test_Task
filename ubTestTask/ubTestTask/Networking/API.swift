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

enum URLRequestMethod:String {
    case get = "GET"
    var httpMethod:String {
        return self.rawValue.uppercased()
    }
}

extension API {
    var urlPathParameters:[String:Any]? {
        switch self {
        case .bySOL(let page, let cameraType):
            var params:[String:Any] = ["page":page, "sol":1500]
            
            if let cameraValue = cameraType.lowercasedValue {
                params["camera"] = cameraValue
            }
            return params
        }
    }
    
    var baseURL:String {
        "https://api.nasa.gov/mars-photos/api/v1"
    }
    
    var path:String {
        switch self {
        case .bySOL: //(let page, let cameraType):
            return "/rovers/curiosity/photos"
        }
    }
    
    var method:URLRequestMethod {
        switch self {
        case .bySOL: //(let page, let cameraType):
            return .get
        }
    }
}


extension API {
    func requestPath() -> String {
        baseURL.appending(path)
    }
}
