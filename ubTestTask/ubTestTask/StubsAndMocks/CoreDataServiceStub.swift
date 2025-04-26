//
//  CoreDataServiceStub.swift
//  ubTestTask
//
//  Created by Ivan_Tests on 26.04.2025.
//

import Foundation

class CoreDataServiceStub:ListPostsPersistentStoreType {
    func appendListPostItems(_ listPosts: [PostListDataModel]) {
        
    }
    
    func fetchListPostItems(offset: Int, pageSize: Int) -> [PostListDataModel] {
        return []
    }
    
    
}
