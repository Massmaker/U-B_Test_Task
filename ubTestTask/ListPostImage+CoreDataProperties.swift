//
//  ListPostImage+CoreDataProperties.swift
//  ubTestTask
//
//  Created by Ivan_Tests on 28.04.2025.
//
//

import Foundation
import CoreData


extension ListPostImage {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ListPostImage> {
        return NSFetchRequest<ListPostImage>(entityName: "ListPostImage")
    }

    @NSManaged public var data: Data?
    @NSManaged public var imageURL: String?
    @NSManaged public var listPost: ListPost?

}

extension ListPostImage : Identifiable {

}
