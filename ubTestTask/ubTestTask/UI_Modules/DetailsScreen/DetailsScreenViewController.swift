//
//  DetailsScreenViewController.swift
//  ubTestTask
//
//  Created by Ivan_Tests on 26.04.2025.
//

import UIKit

class DetailsScreenViewController: UIViewController {

    var interactor: (any DetailsScreenInteractorType)?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        guard self.traitCollection.horizontalSizeClass != newCollection.horizontalSizeClass else {
            return
        }
        
        setupUI()
    }
    
    private func setupUI() {
        
    }

}
