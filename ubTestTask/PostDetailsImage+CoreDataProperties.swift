//
//  PostDetailsImage+CoreDataProperties.swift
//  ubTestTask
//
//  Created by Ivan_Tests on 28.04.2025.
//
//

import Foundation
import CoreData


extension PostDetailsImage {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PostDetailsImage> {
        return NSFetchRequest<PostDetailsImage>(entityName: "PostDetailsImage")
    }

    @NSManaged public var data: Data?
    @NSManaged public var imageURL: String?
    @NSManaged public var postDetails: PostDetails?

}

extension PostDetailsImage : Identifiable {

}
