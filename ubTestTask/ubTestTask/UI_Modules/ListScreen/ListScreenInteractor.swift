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
    
    func onScrolledToEnd() {
        logger.notice(#function)
        worker.fetchNextPageData { [weak self] fetchResult in
            self?.handleFetchResult(fetchResult)
        }
    }
    
    func loadNextBatch() {
        worker.fetchNextPageData { [weak self] fetchResult in
            self?.handleFetchResult(fetchResult)
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
                //store to cache and persist if didSetup
                self.worker.receiveLoadedInfos(photoInfos)
                
                self.handleBatchLoadingFor(page:page, with: photoInfos)
            }
        }
        
        
    }
    
    private func handleBatchLoadingFor(page:Int, with photoInfos:[PhotoInfo]) {
        print("\(#function)")
        self.worker.fetchDataFor(page) {[weak self] fetchResult in
            print("\(#function) completion")
            
            switch fetchResult {
            case .success(let postListItems):
                    self?.presenter.receiveLoadedPostItems(postListItems)
                    
                    let postIDsWithoutImages = postListItems.filter({$0.image == nil}).map({$0.id})
                    let idsSet:Set<String> = Set(postIDsWithoutImages.map{$0.value})
                    
                    let filteredPhotoItems = photoInfos.filter {idsSet.contains("\($0.id)") }
                    
                    
                    let toLoadPhotos:[(postId:Int, src:NonEmptyContainer<String>)] = filteredPhotoItems.compactMap({
                        if let nonEmptySource = NonEmptyContainer($0.imgSrc) {
                            return ($0.id, nonEmptySource)
                        }
                        return nil
                    })
                    
                    if !toLoadPhotos.isEmpty {
                        self?.loadImagesFor(postsWithImageSources: toLoadPhotos)
                    }
                
            case .failure(let fetchError):
                print("\(#function) Error: \(fetchError)")
            }
        }
            

    }
    
    private func loadImagesFor(postsWithImageSources sources:[(postId:Int, src:NonEmptyContainer<String>)]) {
        #if DEBUG
        print("Loading images for sources: \(sources)")
        #endif
        
        let group = DispatchGroup()
        let count = sources.count
        
        for _ in 0..<count {
            group.enter()
        }
        
        DispatchQueue.concurrentPerform(iterations: count, execute: {[weak self, sources] iteration in
            let input = sources[iteration]
            let postId = input.postId
            
            guard let strongSelf = self else {
                group.leave()
                return
            }
            
            let source:NonEmptyContainer<String>
            if input.src.value.hasPrefix("http:") {
                let safenedString = input.src.value.replacingOccurrences(of: "http:", with: "https:")
                source = NonEmptyContainer(safenedString)!
            }
            else {
                source = input.src
            }
            
            #if DEBUG
            print("Start loading image for \(postId)")
            #endif
            
            self?.apiCaller.loadImageData(for: source) { result in
                switch result {
                case .success(let imageData):
                    #if DEBUG
                    print("Success loading image for \(postId)")
                    #endif
                    
                    
                    
                    
                    var snapshotData:Data?
                    //Update persistent Storage
                    if let image = UIImage(data: imageData){//}, scale: UIScreen.main.scale) {
                        if image.size.width > 100 || image.size.height > 100 {
                            let snapshotImage = image.aspectFittedToHeight(100, newWidth: 100)
                            snapshotData = snapshotImage.jpegData(compressionQuality: 100)
                        }
                        else {
                            snapshotData = imageData
                        }
                    }
                    
                    if let snapData = snapshotData {
                        //update UI
                        DispatchQueue.main.async {[weak strongSelf, postId, snapData] in
                            guard let self = strongSelf else {
                                return
                            }
                            self.presenter.updatePost(postId: postId, withImageData: snapData)
                        }
                        
                        guard let dataContainer = NonEmptyContainer(snapData) else {
                            return
                        }
                        
                        self?.worker.receiveData(dataContainer, forImageWith: postId)
                    }
                    
                case .failure(let error):
                    #if DEBUG
                    print("Failed to load image for \(postId): \(error)")
                    #endif
                }
                group.leave()
            }
        })
        
        group.notify(queue: DispatchQueue.main) {[weak self] in
            // here is potentially not secure saving -
            // the write context can be still updating image data for some List post images
            self?.worker.saveIfNeeded()
        }
       
    }
}
