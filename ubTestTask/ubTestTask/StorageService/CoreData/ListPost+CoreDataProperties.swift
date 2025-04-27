//
//  ListPost+CoreDataProperties.swift
//  ubTestTask
//
//  Created by Ivan_Tests on 26.04.2025.
//
//

import Foundation
import CoreData


extension ListPost {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ListPost> {
        return NSFetchRequest<ListPost>(entityName: "ListPost")
    }

    @NSManaged public var id: String?
    @NSManaged public var title: String?
    @NSManaged public var image: ListPostImage?
    @NSManaged public var details: PostDetails?

}

extension ListPost : Identifiable {

}
