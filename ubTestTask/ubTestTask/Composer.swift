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
class Composer {
    
    private static let instance = Composer()
    
    let networkService:NetworkService
    
    private init() {
        
        guard let pathString = Bundle.main.path(forResource: "ApiKeyInfo", ofType: "plist"),
            let data = FileManager.default.contents(atPath: pathString)else {
            networkService = NetworkService.demo()
            return
        }
        
        let decoder = PropertyListDecoder()
        
        do {
            let info = try decoder.decode(ApiKeyInfo.self, from: data)
            guard let apiKey = NonEmptyContainer(info.apiKey) else {
                networkService = NetworkService.demo()
                return
            }
            self.networkService = NetworkService(apiKey: apiKey)
        }
        catch {
            networkService = NetworkService.demo()
        }
        
        
    }
    
    class func createListScreenSuite() -> ListScreenViewController {
        let vc = ListScreenViewController()
        
        let presenter = ListScreenPresenter(viewController: vc)
        #warning("Remove the stub and supply a real CoreDataService instance")
        let persistentStore = CoreDataService()
        
        let storageService = PostsStorageService(persistentStore: persistentStore)
        
        let worker = ListScreenWorker(cache: storageService)
        
        let interactor = ListScreenInteractor(presenter: presenter, worker: worker, apiCaller: self.instance.networkService)
        
        vc.interactor = interactor
        vc.router = ListScreenRouter()
        
        return vc
    }
    
    class func createDetailsScreenSuite(for postId:NonEmptyContainer<String>) -> DetailsScreenViewController {
        let detailsVC = DetailsScreenViewController()
        #warning("Finish the setup")
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
