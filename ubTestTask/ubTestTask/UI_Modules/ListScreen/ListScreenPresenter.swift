//
//  ListScreenPresenter.swift
//  ubTestTask
//
//  Created by Ivan_Tests on 26.04.2025.
//

protocol ListScreenPresenterType {
    
}

class ListScreenPresenter:ListScreenPresenterType {
    private weak var listVC:ListScreenViewController?
    
    init(viewController:ListScreenViewController) {
        self.listVC = viewController
        viewController.title = "Posts"
        viewController.navigationItem.largeTitleDisplayMode = .never
    }
    
    
}
