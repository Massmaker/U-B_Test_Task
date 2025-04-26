//
//  ListScreenRouter.swift
//  ubTestTask
//
//  Created by Ivan_Tests on 26.04.2025.
//

import UIKit

protocol ToDetailsRouterType {
    func routeToDetailsScreen(for post:PostListDataModel)
}

class ListScreenRouter:ToDetailsRouterType {
    weak var viewController:UIViewController? // note here the type of the view controller is not specified precisely - loose coupling
    
    func routeToDetailsScreen(for post:PostListDataModel) {
        
    }
}
