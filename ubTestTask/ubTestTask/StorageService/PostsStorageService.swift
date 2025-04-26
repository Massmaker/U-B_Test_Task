//
//  PostsStorageService.swift
//  ubTestTask
//
//  Created by Ivan_Tests on 26.04.2025.
//

import Foundation

enum PostListDataModelStorageError:Error {
    case noData
    case partialResult([PostListDataModel])
}

protocol ListPostsPersistentStoreType {
    func appendListPostItems(_ listPosts:[PostListDataModel])
    func fetchListPostItems(offset:Int, pageSize:Int) -> [PostListDataModel]
}

class PostsStorageService<P>:PostListDataModelStorage where P:ListPostsPersistentStoreType {
    
    private var cachedPosts:[PostListDataModel] = []
    private var cachedPostIDs:Set<String> = []
    private var persistentStore:P
    
    init(cachedPosts: [PostListDataModel] = [], cachedPostIDs: Set<String> = [], persistentStore: P) {
        
        self.persistentStore = persistentStore
    }
    
    func getListPosts(page: Int, pageSize: Int) throws (PostListDataModelStorageError) -> [PostListDataModel] {
        
        guard !cachedPosts.isEmpty else {
            throw .noData
        }
        
        guard page != 0 else {
            let prefix = Array(cachedPosts.prefix(pageSize))
            if prefix.count < pageSize {
                throw .partialResult(prefix)
            }
            return prefix
        }
        
        let offset = pageSize * page
        let cacheCount = cachedPosts.count
        
        guard offset < cacheCount else {
            throw .noData
        }
        
        let range = offset..<(offset + pageSize)
        
        let result = Array(cachedPosts[range])
        
        if result.count < pageSize {
            throw .partialResult(result)
        }
        
        return result
    }
    
    
    func saveListPosts(_ posts:[PostListDataModel]) {
        
        let newPostIdsSet = Set(posts.map{$0.id.value})
                                
        guard cachedPostIDs.intersection(newPostIdsSet).isEmpty else {
            //TODO: handle partial intersection
            return
        }
        
        // store in-memory
        self.cachedPostIDs.formUnion(newPostIdsSet)
        self.cachedPosts.append(contentsOf: posts)
        

        //backup to persisent store
    }
    
}
