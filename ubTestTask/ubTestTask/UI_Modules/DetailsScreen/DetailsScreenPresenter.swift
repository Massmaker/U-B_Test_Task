//
//  DetailsScreenPresenter.swift
//  ubTestTask
//
//  Created by Ivan_Tests on 26.04.2025.
//

import Foundation

protocol DetailsScreenPresenterType {
    
}

class DetailsScreenPresenter:DetailsScreenPresenterType {
    
    private weak var listVC:DetailsScreenViewController?

    init(viewController:DetailsScreenViewController) {
        self.listVC = viewController
        viewController.navigationItem.largeTitleDisplayMode = .never
    }

}
