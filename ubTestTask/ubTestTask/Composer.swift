//
//  Composer.swift
//  ubTestTask
//
//  Created by Ivan_Tests on 26.04.2025.
//

import Foundation
//import list screen module

//import details screen module


fileprivate struct ApiKeyInfo:Decodable {
    var apiKey:String
}

/**
This is a composition root for both List screen and the Details screen
*/
@MainActor
class Composer {
    
    private static let instance = Composer()
    
    let networkService:NetworkService
    let netServiceActor:NetworkServiceActor
    
    private init() {
        
        guard let pathString = Bundle.main.path(forResource: "ApiKeyInfo", ofType: "plist"),
            let data = FileManager.default.contents(atPath: pathString)else {
            networkService = NetworkService.demo()
            netServiceActor = NetworkServiceActor.demo()
            return
        }
        
        let decoder = PropertyListDecoder()
        
        do {
            let info = try decoder.decode(ApiKeyInfo.self, from: data)
            guard let apiKey = NonEmptyContainer(info.apiKey) else {
                networkService = NetworkService.demo()
                netServiceActor = NetworkServiceActor.demo()
                return
            }
            self.networkService = NetworkService(apiKey: apiKey)
            self.netServiceActor = NetworkServiceActor(apiKey: apiKey)
        }
        catch {
            networkService = NetworkService.demo()
            netServiceActor = NetworkServiceActor.demo()
        }
        
        
    }
    
    class func createListScreenSuite() -> ListScreenViewController {
        let vc = ListScreenViewController()
        
        let presenter = ListScreenPresenter(viewController: vc)
    
        let persistentStore = CoreDataService()
        
        let interactor = ListScreenInteractor(presenter: presenter, store: persistentStore, apiCaller: self.instance.netServiceActor)
        
        vc.interactor = interactor
        vc.router = ListScreenRouter()
        
        return vc
    }
    
    class func createDetailsScreenSuite(for postId:NonEmptyContainer<String>) -> DetailsScreenViewController {
        let detailsVC = DetailsScreenViewController()
        #warning("Finish the setup for Details screen")
        //TODO: TODO: supply the interactor to a View Controller
        detailsVC.interactor = nil
        
        return detailsVC
    }
}


extension NetworkService {
    static func demo() -> NetworkService {
        NetworkService(apiKey: NonEmptyContainer("DEMO_KEY")!)
    }
}


extension NetworkServiceActor {
    static func demo() -> NetworkServiceActor {
        NetworkServiceActor(apiKey: NonEmptyContainer("DEMO_KEY")!)
    }
}
