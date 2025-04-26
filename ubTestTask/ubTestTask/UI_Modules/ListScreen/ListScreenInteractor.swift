//
//  ListScreenInteractor.swift
//  ubTestTask
//
//  Created by Ivan_Tests on 26.04.2025.
//





protocol ListScreenInteractorType {
    
}

class ListScreenInteractor<P:ListScreenPresenterType, W:ListScreenDataWorkerType> : ListScreenInteractorType {
    private var presenter: P
    private var worker:W
    
    init(presenter: P, worker:W) {
        self.presenter = presenter
        self.worker = worker
    }
}
