//
//  PostDataModel.swift
//  ubTestTask
//
//  Created by Ivan_Tests on 26.04.2025.
//


import UIKit

/// a model for displaying a list item with a small image size for UI performance ( list, scrolling...)
struct PostListDataModel: ListItemUIModelType, Hashable, Sendable  {
    let id:NonEmptyContainer<String>
    let title:NonEmptyContainer<String>
    private(set) var image:UIImage?
    
    mutating func setImage(_ image:UIImage?) {
        self.image = image
    }
    
    mutating func setImageData(_ data:Data?) {
        guard let imageData = data, let image = UIImage(data:imageData) else {
            self.image = nil
            return
        }
        
        self.image = image
    }
    
    //MARK: - Hashable
    static func == (lhs: PostListDataModel, rhs: PostListDataModel) -> Bool {
        lhs.id.value == rhs.id.value //&& lhs.title.value == rhs.id.value && lhs.image == rhs.image
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id.value)
    }
}

/// a model for displaying larger size image and some additional details text
struct PostDetailsDataModel: DetailsItemUIModelType, Hashable {
    
    let id:NonEmptyContainer<String>
    let title:NonEmptyContainer<String>
    let textString:NonEmptyContainer<String>
    private(set) var image:UIImage?
    
    mutating func setImage(_ image:UIImage?) {
        self.image = image
    }
    
    mutating func setImageData(_ data:Data?) {
        guard let imageData = data, let image = UIImage(data:imageData) else {
            self.image = nil
            return
        }
        
        self.image = image
    }
    
    //MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id.value)
    }
    
    static func ==(lhs:PostDetailsDataModel, rhs:PostDetailsDataModel) -> Bool {
        lhs.id.value == rhs.id.value
    }
    
}




