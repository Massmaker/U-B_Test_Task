//
//  CoreDataService.swift
//  ubTestTask
//
//  Created by Ivan_Tests on 26.04.2025.
//

import CoreData
fileprivate let logger = createLogger(subsystem: "Persistent_Storage", category: "CoreDataService")

protocol PostListDataModelStorageDelegate:AnyObject {
    func listObjectsDidUpdate()
}

class CoreDataService:NSObject {
    
    weak var delegate: (any PostListDataModelStorageDelegate)?
    
    private var mainQueueContext:NSManagedObjectContext
    private var writeContext:NSManagedObjectContext
    
    private var listItemsFetchController:NSFetchedResultsController<ListPost> {
        if let c = _listFetchController {
            return c
        }
        let initialFetchRequest = makeFetchRequestForList(pageSize: 25)
        let newController = makeNewFetchedResultsControllerForList(with: initialFetchRequest)
        _listFetchController = newController
        return newController
    }
    
    private var _listFetchController:NSFetchedResultsController<ListPost>?
    
    override init() {
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
        
        super.init()
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
    
    private func makeFetchRequestForList(pageSize:Int) -> NSFetchRequest<ListPost> {
        let fetchRequest:NSFetchRequest<ListPost> = ListPost.fetchRequest()
        fetchRequest.fetchBatchSize = pageSize
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "id", ascending: true)
        ]
        return fetchRequest
    }
    /// creates a fetched results controller that uses `mainContext`
    private func makeNewFetchedResultsControllerForList(with fetchRequest:NSFetchRequest<ListPost>) -> NSFetchedResultsController<ListPost> {
        NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.mainQueueContext, sectionNameKeyPath: nil, cacheName: nil)
    }
}

extension CoreDataService:PostListDataModelStorage {
    
    private struct ListModelResult:ListModelResultType {
        let identifier: NonEmptyContainer<String>
        let title: NonEmptyContainer<String>
        var imageData:Data?
    }
    
    func saveIfNeeded() {
        self.saveContex()
    }
    
    func receive(postListItems:[any ListItemInfoContainer]) {
        writeContext.perform {[weak self] in
            guard let self else { return }
            
            for postItem in postListItems {
                //create new Record for ListItem
                let listPost = ListPost(context: self.writeContext)
                listPost.id = postItem.identifier
                listPost.title = "\(postItem.roverName)_\(postItem.cameraName)_\(postItem.date.description)"
                
                //create new Record for small icon for the ListItem
                let photo = ListPostImage(context: self.writeContext)
                photo.imageURL = postItem.imageSourceURLString
                
                // assign relations between the two
                listPost.image = photo
                photo.listPost = listPost
            }
            
            self.saveContex()
        }
    }
    
    func getListPosts(page: Int, pageSize: Int) throws(PostListDataModelStorageError) -> [any ListModelResultType] {
        
        let controller:NSFetchedResultsController<ListPost>
        
        if let existingController = _listFetchController {
            controller = existingController
        }
        else {
            let newFetch = makeFetchRequestForList(pageSize: pageSize)
            let newController = makeNewFetchedResultsControllerForList(with: newFetch)
            
            self._listFetchController = newController
            newController.delegate = self
            controller = newController
            
            do {
                try self.mainQueueContext.performAndWait {
                    try newController.performFetch()
                }
            }
            catch(let error) {
                logger.error("Failure when fetching List Posts: \(error)")
                throw .noData
            }
        }
        
        let startIndex = pageSize * page
        let endIndex = startIndex + pageSize
        var fetchedObjects:[ListPost] = []
        for i in startIndex..<endIndex {
            let fetched = controller.object(at: IndexPath(item: i, section: 0))
            fetchedObjects.append(fetched)
        }
        
        let result:[ListModelResultType] = prepareReturnResultsFrom(entities: fetchedObjects)
        
        return result
    }
    
    func setImageData(_ data: Data, forListPostId listPostId: String, saveImmediately:Bool = false) {
        self.writeContext.performAndWait({ [weak self] in
            guard let strongSelf = self else { return }
            
            let fetch:NSFetchRequest<ListPost> = ListPost.fetchRequest()
            fetch.resultType = .managedObjectResultType
            fetch.predicate = NSPredicate(format: "id == %@", listPostId)
            
            
            do {
                let entities:[ListPost] = try strongSelf.writeContext.fetch(fetch)
                guard let first = entities.first else {
                    return
                }
                
                first.image?.data = data
                logger.notice("Assigned image data to \(listPostId)")
                if saveImmediately {
                    strongSelf.saveContex()
                }
            }
            catch {
                logger.error("Error fetching: \(error)")
                return
            }
        })
    }
    
    private func prepareReturnResultsFrom(entities:[ListPost]) -> [ListModelResult] {
        
        let result:[ListModelResult] = entities.compactMap({ fetched in
            
            guard let id = fetched.id,
                  let idContainer = NonEmptyContainer(id),
                  let title = fetched.title,
                  let titleContainer = NonEmptyContainer(title) else {
                return nil
            }
            
            let listModel = ListModelResult(identifier: idContainer,
                                            title: titleContainer,
                                            imageData: fetched.image?.data)
            return listModel
        })
        
        return result
    }
}

extension CoreDataService:NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
        if controller == self._listFetchController{//
            let definedController = controller as? NSFetchedResultsController<ListPost>
            let listPosts = controller.fetchedObjects
            delegate?.listObjectsDidUpdate()
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange sectionInfo: NSFetchedResultsSectionInfo,
                    atSectionIndex sectionIndex: Int,
                    for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            logger.notice("Fetched Controller Did Insert")
        case .delete:
            logger.notice("Fetched Controller Did Delete")
        case .update:
            logger.notice("Fetched Controller Did Update")
        case .move:
            logger.notice("Fetched Controller Did Move")
        default:
            break
        }
    }
}



