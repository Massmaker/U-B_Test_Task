//
//  listScreenWorker.swift
//  ubTestTask
//
//  Created by Ivan_Tests on 26.04.2025.
//


import Foundation

enum FetchError:Error {
    case noDataFetched
    case partialResultFetched([PostListDataModel])
}

typealias ListPostsCompletion = (Result<[PostListDataModel], FetchError>) -> ()

protocol ListScreenDataWorkerType {
    var pageSize:Int {get}
    var currentPage:Int {get}
    func fetchInitialData(completion:ListPostsCompletion)
    func fetchNextPageData(completion:ListPostsCompletion)
    func fetchDataFor(_ page:Int, completion:ListPostsCompletion)
    func receiveLoadedInfos(_ infos:[PhotoInfo])
    func receiveData(_ data:NonEmptyContainer<Data>, forImageWith id:Int)
    func saveIfNeeded()
}






/**
 THis class is responsible for data loading and managing
 */
class ListScreenWorker<C:PostListDataModelStorage>: ListScreenDataWorkerType {
    
    private(set) var pageSize:Int = 10
    private(set) var currentPage:Int = 0
    private var cache:C
    
    
    init(pageSize: Int = 10, currentPage: Int = 0, cache: C) {
        self.pageSize = pageSize
        self.currentPage = currentPage
        self.cache = cache
    }
    
    func fetchInitialData(completion: ListPostsCompletion) {
        precondition(currentPage == 0, "Not initial page data requested")
        
        fetch(completion: completion)
    }
    
    func fetchNextPageData(completion: ListPostsCompletion) {
        currentPage += 1
        fetch(completion: completion)
    }
    
    func fetchDataFor(_ page:Int, completion:ListPostsCompletion) {
        if currentPage != page {
            currentPage = page
        }
        
        fetch(completion: completion)
    }
    
    private func fetch(completion: ListPostsCompletion) {
        do {
            let fetchedBatch = try cache.getListPosts(page: self.currentPage,
                                                      pageSize: self.pageSize)
           
            completion(.success(fetchedBatch))
        }
        catch {
            switch error {
            case .noData:
                completion(.failure(.noDataFetched))
            case .partialResult(let postListDataModels):
                completion(.failure(.partialResultFetched(postListDataModels)))
            }
        }
    }
    
    func receiveLoadedInfos(_ infos:[PhotoInfo]) {
        cache.saveListPosts(infos)
    }
    
    func receiveData(_ data:NonEmptyContainer<Data>, forImageWith id:Int) {
        cache.setImageData(data.value, forListPostId: id)
    }
    
    func saveIfNeeded() {
        cache.saveIfNeeded()
    }
}
