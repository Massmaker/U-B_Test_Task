//
//  PostDataModel.swift
//  ubTestTask
//
//  Created by Ivan_Tests on 26.04.2025.
//


import UIKit

/// a model for displaying a list item with a small image size for UI performance ( list, scrolling...)
struct PostListDataModel: ImageContainer, Hashable  {
    let id:NonEmptyContainer<String>
    let title:NonEmptyContainer<String>
    var image:UIImage?
    
    static func == (lhs: PostListDataModel, rhs: PostListDataModel) -> Bool {
        lhs.id.value == rhs.id.value //&& lhs.title.value == rhs.id.value && lhs.image == rhs.image
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id.value)
//        hasher.combine(title.value)
//        if let imageData = image?.jpegData(compressionQuality: 1.0) {
//            hasher.combine(imageData)
//        }
    }
}

/// a model for displaying larger size image and some additional details text
struct PostDetailsDataModel: ImageContainer {
    let id:NonEmptyContainer<String>
    let title:NonEmptyContainer<String>
    let details:NonEmptyContainer<String>
    private(set) var image:UIImage?
    
    mutating func setImage(_ image:UIImage?) {
        self.image = image
    }
}


protocol ImageContainer {
    var image:UIImage? { get }
}

