//
//  PostDataModel.swift
//  ubTestTask
//
//  Created by Ivan_Tests on 26.04.2025.
//

import Foundation

/// a model for displaying a list item with a small image size for UI performance ( list, scrolling...)
struct PostListDataModel: ImageContainer  {
    let id:NonEmptyContainer<String>
    let title:NonEmptyContainer<String>
    var imageData:Data?
}

/// a model for displaying larger size image and some additional details text
struct PostDetailsDataModel: ImageContainer {
    let id:NonEmptyContainer<String>
    let title:NonEmptyContainer<String>
    let details:NonEmptyContainer<String>
    let imageData:Data?
}

import UIKit
protocol ImageContainer {
    var imageData:Data? { get }
    var image:UIImage { get }
}

extension ImageContainer {
    var image:UIImage {
        if let data = imageData, let dataImage = UIImage(data: data) {
            return dataImage
        }
        
        return UIImage(named: "PostImagePlaceHolder")!
    }
}

