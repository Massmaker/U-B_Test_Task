//
//  PostDetails+CoreDataProperties.swift
//  ubTestTask
//
//  Created by Ivan_Tests on 26.04.2025.
//
//

import Foundation
import CoreData


extension PostDetails {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PostDetails> {
        return NSFetchRequest<PostDetails>(entityName: "PostDetails")
    }

    @NSManaged public var details: String?
    @NSManaged public var post: ListPost?
    @NSManaged public var image: PostDetailsImage?

}

extension PostDetails : Identifiable {

}
