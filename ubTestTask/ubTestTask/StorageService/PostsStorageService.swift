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

enum PersistentStoreError:Error {
    case internalError((any Error)?)
}

protocol ListPostsPersistentStoreType {
    func appendListPostItems(_ listPosts:[PhotoInfo])
    func fetchListPostItems(offset:Int, pageSize:Int) throws (PersistentStoreError) -> [PostListDataModel]
    func updateImageData(_ data:Data?, forListPostWith id:String, saveImmadiately:Bool)
    func saveIfNeeded()
}

class PostsStorageService<P:ListPostsPersistentStoreType> {
    
    private var cachedPosts:[PostListDataModel] = []
    private var cachedPostIDs:Set<String> = []
    private var persistentStore:P
    
    init(cachedPosts: [PostListDataModel] = [], cachedPostIDs: Set<String> = [], persistentStore: P) {
        
        self.persistentStore = persistentStore
    }
    
    private func savePhotoInfosToCache(_ posts:[PhotoInfo], persist:Bool = true) {
        guard !posts.isEmpty else {
            return
        }
        
        let postListDataModels:[PostListDataModel] = mapPhotoInfosToCachedItems(posts)
        
        let newPostIdsSet = Set(postListDataModels.map{$0.id.value})
        
        let intersectionSet = cachedPostIDs.intersection(newPostIdsSet)
        
        var toBeAppended:[PostListDataModel]?
        var toBePersisted:[PhotoInfo]?
        
        if !intersectionSet.isEmpty {

            let sortedIDsToInsert = newPostIdsSet.subtracting(intersectionSet).sorted(by: < )
            
            //update IDs set
            self.cachedPostIDs.formUnion(Set(sortedIDsToInsert))
            
            //update the array
            
            //1 - update existing with latest changes
            let filteredSorted = postListDataModels
                .filter({intersectionSet.contains($0.id.value) })
                .sorted { $0.id.value < $1.id.value}
            
            for toUpdate in filteredSorted {
                if let indexInCache = self.cachedPosts.firstIndex(where: { aPostListDataModel in
                    aPostListDataModel.id.value == toUpdate.id.value
                }){
                    self.cachedPosts[indexInCache] = toUpdate
                }
            }
            
            let newPosts = postListDataModels.filter{ !intersectionSet.contains($0.id.value) }
            
            if !newPosts.isEmpty {
                toBeAppended = newPosts
            }
            
            if persist {
                // 2  - insert new list items
                let filteredPhotos = posts.filter({sortedIDsToInsert.contains("\($0.id)")})
                toBePersisted = filteredPhotos
            }
            
        }
        else {
            self.cachedPostIDs.formUnion(newPostIdsSet)
            
            toBeAppended = postListDataModels
            
            if persist {
                if newPostIdsSet.count == posts.count {
                    toBePersisted = posts
                }
                else {
                    toBePersisted = posts.filter { newPostIdsSet.contains("\($0.id)") }
                }
            }
        }
        
        // store in-memory
        if let toAppend = toBeAppended, !toAppend.isEmpty {
            savePostModelsToCache(toAppend)
        }

        if persist, let toPersist = toBePersisted {
            //backup to persisent store
            persistentStore.appendListPostItems(toPersist)
        }
    }
    
    private func savePostModelsToCache(_ postModels:[PostListDataModel]) {
        let sortedById = postModels.sorted(by: {$0.id.value < $1.id.value})
        self.cachedPosts.append(contentsOf: sortedById)
    }
    
    /// - Returns: an array of zero or more `PostListDataModel` s
    private func mapPhotoInfosToCachedItems(_ photoInfos:[PhotoInfo]) -> [PostListDataModel] {
        
        let result:[PostListDataModel] = photoInfos.compactMap { photoInfo in
            
            guard let idContainer = NonEmptyContainer("\(photoInfo.id)") else {
                return nil
            }
            
            guard let titleContainer = NonEmptyContainer(photoInfo.displayTitle) else {
                return nil
            }
            
            return PostListDataModel(id: idContainer, title: titleContainer)
        }
        
        return result
    }
    
    //MARK: -
    private func fetchingFromPersistentStorage(page:Int, pageSize:Int) throws (PersistentStoreError) -> [PostListDataModel] {
        
        let items = try persistentStore.fetchListPostItems(offset: page, pageSize: pageSize)
        return items
    }
}


extension PostsStorageService: PostListDataModelStorage {
    func saveListPosts(_ posts:[PhotoInfo]) {
       savePhotoInfosToCache(posts, persist: true)
    }
    
    func getListPosts(page: Int, pageSize: Int) throws (PostListDataModelStorageError) -> [PostListDataModel] {
        
        guard !cachedPosts.isEmpty else {
            
            do {
                let persistedListItems:[PostListDataModel] = try fetchingFromPersistentStorage(page:page, pageSize:pageSize)
                
                if persistedListItems.isEmpty {
                    throw PostListDataModelStorageError.noData
                }
                
                savePostModelsToCache(persistedListItems)
                
                return persistedListItems
            }
            catch (let persistentStoreError) {
                // Maybe add some logging to an external logger to be able to debug\analize
                
                #if DEBUG
                print("Persistent Store Failed to fetch: \(persistentStoreError)")
                #endif
                
                throw .noData
            }
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
        
        let result = Array(cachedPosts[safe:range])
        
        if result.count < pageSize {
            throw .partialResult(result)
        }
        
        return result
    }
    
    
    func setImageData(_ data: Data, forListPostId listPostId: Int) {
        
        persistentStore.updateImageData(data, forListPostWith: "\(listPostId)", saveImmadiately:false)
    }
    
    func saveIfNeeded() {
        persistentStore.saveIfNeeded()
    }
}
