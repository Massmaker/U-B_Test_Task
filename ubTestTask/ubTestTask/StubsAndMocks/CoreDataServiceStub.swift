//
//  CoreDataServiceStub.swift
//  ubTestTask
//
//  Created by Ivan_Tests on 26.04.2025.
//

import Foundation

class CoreDataServiceStub:ListPostsPersistentStoreType {
    func fetchListPostItems(offset: Int, pageSize: Int) throws(PersistentStoreError) -> [PostListDataModel] {
        return []
    }
    
    func appendListPostItems(_ listPosts: [PhotoInfo]) {
        
    }
    
}
