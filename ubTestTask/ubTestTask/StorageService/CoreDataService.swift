//
//  CoreDataService.swift
//  ubTestTask
//
//  Created by Ivan_Tests on 26.04.2025.
//

import CoreData

class CoreDataService {
    var context:NSManagedObjectContext
    init(context: NSManagedObjectContext) {
        self.context = context
    }
}

extension CoreDataService: ListPostsPersistentStoreType {
    
    
    
    func appendListPostItems(_ listPosts: [PostListDataModel]) {
        self.context.perform {[unowned context] in
            
            //context.insert(T##object: NSManagedObject##NSManagedObject)
            
            
            do {
                try context.save()
            }
            catch {
                #if DEBUG
                print("Failed to save post list items: \(error.localizedDescription)")
                #endif
            }
        }
    }
    
    func fetchListPostItems(offset: Int, pageSize: Int) -> [PostListDataModel] {
        return []
    }
    
    
}
