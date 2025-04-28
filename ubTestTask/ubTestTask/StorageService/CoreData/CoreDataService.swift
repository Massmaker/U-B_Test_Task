//
//  CoreDataService.swift
//  ubTestTask
//
//  Created by Ivan_Tests on 26.04.2025.
//

import CoreData

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

                print("Store: '\(type)', Options: \(options)")

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
}

extension CoreDataService: ListPostsPersistentStoreType {
    
    
    
    func appendListPostItems(_ listPosts: [PhotoInfo]) {
        self.writeContext.perform {[unowned self] in
            
            listPosts.forEach { photoInfo in
                
                let listPost = ListPost(context: self.writeContext)
                listPost.title = photoInfo.displayTitle
                listPost.id = "\(photoInfo.id)"
                
                let imageEntity = ListPostImage(context: self.writeContext)
                imageEntity.imageURL = photoInfo.imgSrc
                
                //assign relations
                imageEntity.listPost = listPost
                listPost.image = imageEntity
                self.writeContext.insert(listPost)
                self.writeContext.insert(imageEntity)
            }
            
            
            guard writeContext.hasChanges else {
                return
            }
            
            do {
                
                try writeContext.save()
                #if DEBUG
                print("\(self) \(#function) Saved postList infos")
                #endif
            }
            catch {
                #if DEBUG
                print("Failed to save post list items: \(error)")
                #endif
            }
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
            
            let mappedPostItems = fetchedEntries.compactMap { listPost in
                
                if let postId = listPost.id,
                   let idContainer = NonEmptyContainer(postId),
                   let title = listPost.title,
                   let titleContainer = NonEmptyContainer(title) {
                    
                    return PostListDataModel(id: idContainer,
                                             title: titleContainer,
                                             imageData:listPost.image?.data )
                }
                else {
                    return nil
                }
                
            }
            #if DEBUG
            print("\(#file) \(#function) fetched \(mappedPostItems.count) list posts")
            #endif
            return mappedPostItems
        }
        catch (let mainContextFetchError){
            
            print("Fetch error: \(mainContextFetchError)")
            
            throw PersistentStoreError.internalError(mainContextFetchError)
        }
    }
    
    
}
