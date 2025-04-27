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


class ListScreenInteractor<P:ListScreenPresenterType, W:ListScreenDataWorkerType, N:NetworkAPICaller> : ListScreenInteractorType {
    
    
    private var presenter: P
    private var worker:W
    private let apiCaller:N
    
    
    init(presenter: P, worker:W, apiCaller:N) {
        self.presenter = presenter
        self.worker = worker
        self.apiCaller = apiCaller
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
    
    private func handleFetchResult(_ result:Result<[PostListDataModel], FetchError>) {
        switch result {
        case .success(let fetchedItems):
            
            presenter.receiveLoadedPostItems(fetchedItems)
            
            //start loading images for loaded posts if needed
            let postsWithoutImage = fetchedItems.filter { postListDataModel in
                postListDataModel.imageData == nil
            }
            
            if !postsWithoutImage.isEmpty {
                loadImagesFor(posts:postsWithoutImage)
            }
            
        case .failure(let error):
            print("Interactor handling error: \(error)")
            switch error {
            case .noDataFetched:
                startNetworkLoadingPosts()
            case .partialResultFetched(let fetchedPartialBatch):
                print("\(#file). \(#function). Partial Result: '\(fetchedPartialBatch.count)' Items")
            }
        }
    }
    
    private func startNetworkLoadingPosts() {
        let page = worker.currentPage
        
        apiCaller.getBatch(page: page) { [weak self, page] result in
            guard let self else { return }
            
            switch result {
            case .failure(let error):
                print("Error Loading batch for page '\(page)': \(error)")
            case .success(let photoInfos):
                self.worker.receiveLoadedInfos(photoInfos)
            }
        }
        
        
    }
    
    private func loadImagesFor(posts:[PostListDataModel]) {
        
    }
}
