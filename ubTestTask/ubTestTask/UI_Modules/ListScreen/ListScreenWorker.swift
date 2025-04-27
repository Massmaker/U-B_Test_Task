//
//  listScreenWorker.swift
//  ubTestTask
//
//  Created by Ivan_Tests on 26.04.2025.
//

typealias ListPostsCompletion = (Result<[PostListDataModel], any Error>) -> ()

protocol ListScreenDataWorkerType {
    func fetchInitialData(completion:ListPostsCompletion)
    func fetchNextPageData(completion:ListPostsCompletion)
}

protocol PostListDataModelStorage {
    func getListPosts(page:Int, pageSize:Int) throws (PostListDataModelStorageError) -> [PostListDataModel]
    func saveListPosts(_ posts:[PostListDataModel])
}




/**
 THis class is responsible for data loading and managing
 */
class ListScreenWorker<C:PostListDataModelStorage>: ListScreenDataWorkerType {
    
    private(set) var pageSize:Int = 20
    private var currentPage:Int = 0
    private var cache:C
    
    
    init(pageSize: Int = 20, currentPage: Int = 0, cache: C) {
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
    
    private func fetch(completion: ListPostsCompletion) {
        do {
            let fetchedBatch = try cache.getListPosts(page: self.currentPage,
                                                      pageSize: self.pageSize)
            let postsWithoutImage = fetchedBatch.filter { postListDataModel in
                postListDataModel.imageData == nil
            }
            
            completion(.success(fetchedBatch))
            
            if !postsWithoutImage.isEmpty {
                loadImagesForPosts(postsWithoutImage)
            }
        }
        catch {
            switch error {
            case .noData:
                //try loading data
                print("Trying to load some Posts for List...")
            case .partialResult(let postListDataModels):
                completion(.success(postListDataModels))
            }
        }
    }
    
    private func loadImagesForPosts(_ posts:[PostListDataModel]){
        
    }
}
