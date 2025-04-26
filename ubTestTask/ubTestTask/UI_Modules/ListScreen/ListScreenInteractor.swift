//
//  ListScreenInteractor.swift
//  ubTestTask
//
//  Created by Ivan_Tests on 26.04.2025.
//



protocol InteractorType {
    func onViewDidLoad()
    func onViewWillAppear(_ animated:Bool)
}

extension InteractorType {
    /// `onViewWillAppear` default empty implementation
    func onViewWillAppear(_ animated:Bool) {
        
    }
}

protocol ListScreenInteractorType:InteractorType {
    func loadNextBatch()
}

class ListScreenInteractor<P:ListScreenPresenterType, W:ListScreenDataWorkerType> : ListScreenInteractorType {
    
    
    private var presenter: P
    private var worker:W
    
    
    
    init(presenter: P, worker:W) {
        self.presenter = presenter
        self.worker = worker
    }
    
    func onViewDidLoad() {
        worker.fetchInitialData { [weak self] fetchResult in
            self?.handleFetchResult(fetchResult)
        }
    }
    
    func loadNextBatch() {
        worker.fetchNextPageData { [weak self] fetchResult in
            self?.handleFetchResult(fetchResult)
        }
    }
    
    private func handleFetchResult(_ result:Result<[PostListDataModel], any Error>) {
        switch result {
        case .success(let fetchedItems):
            print("Interactor handling items: \(fetchedItems.count)")
        case .failure(let error):
            print("Interactor handling error: \(error)")
        }
    }
}
