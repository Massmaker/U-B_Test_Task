//
//  ViewController.swift
//  ubTestTask
//
//  Created by Ivan_Tests on 26.04.2025.
//

import UIKit



class ListScreenViewController: UIViewController {
    var interactor: (any ListScreenInteractorType)?
    var router: (any ToDetailsRouterType)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
    }


}

