//
//  CoreDataService.swift
//  ubTestTask
//
//  Created by Ivan_Tests on 26.04.2025.
//

import CoreData
fileprivate let logger = createLogger(subsystem: "Persistent_Storage", category: "CoreDataService")

protocol PostListDataModelStorage {
    func getListPosts(page:Int, pageSize:Int) throws (PostListDataModelStorageError) -> [PostListDataModel]
    func saveListPosts(_ posts:[PhotoInfo])
    func setImageData(_ data:Data, forListPostId listPostId:Int)
    func saveIfNeeded()
}

class CoreDataService {
    private var mainQueueContext:NSManagedObjectContext
    private var writeContext:NSManagedObjectContext
    
    init() {
        let cdName:String = "Model"
        
        guard let modelURL = Bundle.main.url(forResource: cdName, withExtension: "momd") else {
            fatalError("No Object Graph model file")
        }
        
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to initialize Objects Model")
        }
        
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        
        
        guard let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("\(cdName).sqlite") else {
            fatalError("Wrong file URL")
        }
        
        
        do {
            let persistentStore:NSPersistentStore = try coordinator.addPersistentStore(type: .sqlite,
                                                                                       configuration: nil,
                                                                                       at: storeURL,
                                                                                       options:
                                            [NSMigratePersistentStoresAutomaticallyOption : NSNumber(true),
                                             NSInferMappingModelAutomaticallyOption: NSNumber(true)]) //options to be setup for lightweight migration
            
#if DEBUG
            if let options = persistentStore.options {
                let type = persistentStore.type

                logger.info("Store: '\(type)', Options: \(options)")

            }
#endif

        }
        catch {
            fatalError("Failed to add persistentStore: \(error.localizedDescription)")
        }
        
        //root context
        let parentContext = NSManagedObjectContext(.privateQueue)
        parentContext.persistentStoreCoordinator = coordinator

        //child context
        let mainContext = NSManagedObjectContext(.mainQueue)
        mainContext.parent = parentContext
        mainContext.automaticallyMergesChangesFromParent = true
        
        //Properly assign contexts
        self.writeContext = parentContext
        self.mainQueueContext = mainContext
    }
    
    private func saveContex(andWait:Bool = false) {
        
        let saveOp = {[unowned self] in
            do {
                try self.writeContext.save()
                
                logger.info("\(#function) \(andWait) Saved")
            }
            catch {
                logger.warning("\(#function) Failed to save private context: \(error)")
            }
        }
        
        if andWait {
            self.writeContext.performAndWait(saveOp)
        }
        else {
            self.writeContext.perform(saveOp)
        }
    }
}

import UIKit

extension CoreDataService: ListPostsPersistentStoreType {
    
    func appendListPostItems(_ listPosts: [PhotoInfo]) {
        self.writeContext.perform {[unowned self] in
            
            listPosts.forEach { photoInfo in
                
                let listPost = ListPost(context: self.writeContext) //also inserts into context
                listPost.title = photoInfo.displayTitle
                listPost.id = "\(photoInfo.id)"
                
                let imageEntity = ListPostImage(context: self.writeContext) //also inserts into context
                imageEntity.imageURL = photoInfo.imgSrc
                
                //assign relations
                imageEntity.listPost = listPost
                listPost.image = imageEntity

            }
            
            guard writeContext.hasChanges else {
                return
            }
            
            self.saveContex()
        }
    }
    
    func fetchListPostItems(offset: Int, pageSize: Int) throws (PersistentStoreError) -> [PostListDataModel] {
        
        let fetchRequest:NSFetchRequest<ListPost> = ListPost.fetchRequest()
        fetchRequest.fetchBatchSize = pageSize
        fetchRequest.fetchOffset = offset
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "id", ascending: true)
        ]
        
        do {
            let fetchedEntries:[ListPost] = try mainQueueContext.performAndWait {
                do {
                    let entries = try mainQueueContext.fetch(fetchRequest)
                    return entries
                }
                catch {
                    throw error
                }
            }
            
            if fetchedEntries.isEmpty {
                return []
            }
            //fetchedEntries[safe:]
            let mappedPostItems = fetchedEntries.compactMap { listPost in
                
                if let postId = listPost.id,
                   let idContainer = NonEmptyContainer(postId),
                   let title = listPost.title,
                   let titleContainer = NonEmptyContainer(title) {
                    
                    if let imageEntity = listPost.image,
                       let data = imageEntity.data {
                        return PostListDataModel(id: idContainer,
                                                 title: titleContainer,
                                                 image:UIImage(data:data))
                    }
                    else {
                        return PostListDataModel(id: idContainer,
                                                 title: titleContainer,
                                                 image: nil)
                    }
                    
                }
                else {
                    return nil
                }
                
            }
            
            logger.info("\(#function) fetched \(mappedPostItems.count) list posts")
            
            return mappedPostItems
        }
        catch (let mainContextFetchError){
            
            logger.error("Fetch error: \(mainContextFetchError)")
            
            throw PersistentStoreError.internalError(mainContextFetchError)
        }
    }
    
    func saveIfNeeded() {
        self.writeContext.perform {
            if self.writeContext.hasChanges {
                self.saveContex(andWait: true)
            }
        }
    }
    
    func updateImageData(_ data: Data?, forListPostWith id: String, saveImmadiately: Bool = false) {
        let request = ListPost.fetchRequest()
        
        request.predicate = NSPredicate.init(format: "id == %@", id)
        
        self.writeContext.perform {
            do {
                let listItems = try self.writeContext.fetch(request)
                if let listPostItem = listItems.first {
                    listPostItem.image?.data = data
                }
                
                if saveImmadiately, self.writeContext.hasChanges {
                    self.saveContex(andWait: true)
                }
            }
            catch {
                
            }
        }
    }
    

}
