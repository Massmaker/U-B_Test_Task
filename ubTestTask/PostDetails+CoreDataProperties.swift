//
//  PostDetails+CoreDataProperties.swift
//  ubTestTask
//
//  Created by Ivan_Tests on 28.04.2025.
//
//

import Foundation
import CoreData


extension PostDetails {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PostDetails> {
        return NSFetchRequest<PostDetails>(entityName: "PostDetails")
    }

    @NSManaged public var details: String?
    @NSManaged public var image: PostDetailsImage?
    @NSManaged public var post: ListPost?

}

extension PostDetails : Identifiable {

}
