//
//  ListScreenInteractor.swift
//  ubTestTask
//
//  Created by Ivan_Tests on 26.04.2025.
//

import Foundation
import UIKit

fileprivate let logger = createLogger(subsystem: "ListScreenModule", category: "Interactor")

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
    func onScrolledToEnd()
    func onItemSelected(withId itemId:NonEmptyContainer<String>)
}


class ListScreenInteractor<P:ListScreenPresenterType, Store:PostListDataModelStorage, N:NetworkAPICallerAsync> : ListScreenInteractorType {
    
    private var presenter: P
    
    private let apiCaller:N
    private let store:Store
    private var lastFetchError:FetchError?
    private let pageSize = 25
    init(presenter: P, store:Store, apiCaller:N) {
        self.presenter = presenter
        self.store = store
        self.apiCaller = apiCaller
    }
    
    func onViewDidLoad() {
        
        store.delegate = self
        
        do {
            let postItems = try store.getListPosts(page: 0, pageSize: 25)
            
            let uiModels = postItems.map{
                $0.uiModel
            }
            
            presenter.receiveLoadedPostItems(uiModels)
        }
        catch {
            
        }
    }
    
    func onScrolledToEnd() {
        logger.notice(#function)
        
        guard canLoadMore() else {
            return
        }
        
        loadNextBatch()
    }
    
    func loadNextBatch() {
        guard canLoadMore() else {
            return
        }
        
        let pages = (presenter.displayedPostsCount / pageSize)
        let nextPage = pages + 1
        
        do {
            let postItems = try store.getListPosts(page: nextPage, pageSize: 25)
            let uiModels = postItems.map{
                $0.uiModel
            }
            
            presenter.receiveLoadedPostItems(uiModels)
        }
        catch {
            
        }
    }
    
    func onItemSelected(withId itemId:NonEmptyContainer<String>) {
        //TODO: TODO: Navigate to Details Screen
    }
    
    private func handleFetchResult(_ result:Result<[PostListDataModel], FetchError>) {
        switch result {
        case .success(let fetchedItems):
            presenter.receiveLoadedPostItems(fetchedItems)
            
        case .failure(let error):
            print("Interactor handling error: \(error)")
            switch error {
            case .noDataFetched:
                startNetworkLoadingPosts()
            case .partialResultFetched(let fetchedPartialBatch):
                print("\(#file). \(#function). Partial Result: '\(fetchedPartialBatch.count)' Items")
                self.lastFetchError = error
                presenter.receiveLoadedPostItems(fetchedPartialBatch)
                
            }
        }
    }
    
    private func startNetworkLoadingPosts() {
        let currentPage = presenter.displayedPostsCount / pageSize
        let apiRequestPage = currentPage + 1
        
        Task {[weak self] in
            guard let self else {
                return
            }
            do {
                let photoInfos = try await self.apiCaller.getBatch(page: apiRequestPage)
                
                //store to cache and persist if didSetup
                self.store.receive(postListItems: photoInfos)
                
                let tuples:[(postId: String, src: NonEmptyContainer<String>)] = photoInfos.compactMap{
                    
                    if let srcContainer = NonEmptyContainer($0.imageSourceURLString) {
                        return (postId:$0.identifier, src:srcContainer)
                    }
                    return nil
                }
                
                self.loadImagesFor(postsWithImageSources:tuples)
            }
            catch {
                print("Error Loading batch for page '\(currentPage)': \(error)")
            }
        }
    }
    
    private func loadImagesFor(postsWithImageSources sources:[(postId:String, src:NonEmptyContainer<String>)]) {
        
        logger.notice("Loading images for sources: \(sources)")
        Task {
            await withTaskGroup { [weak self, sources] group in
                for input in sources {
                    group.addTask { [weak self, input] in
                        
                        guard let self else { return }
                        
                        let source:NonEmptyContainer<String>
                        if input.src.value.hasPrefix("http:") {
                            let safenedString = input.src.value.replacingOccurrences(of: "http:", with: "https:")
                            source = NonEmptyContainer(safenedString)!
                        }
                        else {
                            source = input.src
                        }
                        let postId = input.postId
                        logger.notice("Start loading image for \(postId)")
                        
                        
                        do {
                            let imageData = try await self.apiCaller.loadImageData(for: source.value)
                            
                            var iconData:Data?
                            //Update persistent Storage
                            if let image = UIImage(data: imageData){//}, scale: UIScreen.main.scale) {
                                if image.size.width > 100 || image.size.height > 100 {
                                    let snapshotImage = image.aspectFittedToHeight(100, newWidth: 100)
                                    iconData = snapshotImage.jpegData(compressionQuality: 100)
                                }
                                else {
                                    iconData = imageData
                                }
                            }
                            
                            if let data = iconData {
                                guard let dataContainer = NonEmptyContainer(data) else {
                                    return
                                }
                                
                                self.store.setImageData(dataContainer.value, forListPostId: postId, saveImmediately: false)
                            }
                        }
                        catch {
                            logger.error("Failed to load image for \(postId): \(error)")
                        }
                    }
                }
            }
            
        }
       
    }
    
    private func canLoadMore() -> Bool {
        guard let error = self.lastFetchError else {
            return true
        }
        
        switch error {
        case .noDataFetched:
            return true
        case .partialResultFetched: //(let array):
            return false
        }
        
    }
}


//MARK: - PostListDataModelStorageDelegate

extension ListScreenInteractor:PostListDataModelStorageDelegate {
    func listObjectsDidUpdate() {
        logger.notice("Storage did Send Update Signal...")
    }
}
