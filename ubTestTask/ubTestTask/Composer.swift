//
//  Composer.swift
//  ubTestTask
//
//  Created by Ivan_Tests on 26.04.2025.
//

import Foundation
//import list screen module

//import details screen module


/**
This is a composition root for both List screen and the Details screen
*/
class Composer {
    class func createListScreenSuite() -> ListScreenViewController {
        let vc = ListScreenViewController()
        
        let presenter = ListScreenPresenter(viewController: vc)
        #warning("Remove the stub and supply a real CoreDataService instance")
        let persistentStore = CoreDataServiceStub()
        
        let storageService = PostsStorageService(persistentStore: persistentStore)
        
        let worker = ListScreenWorker(cache: storageService)
        
        let interactor = ListScreenInteractor(presenter: presenter, worker: worker)
        
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
