//
//  PostDataModel.swift
//  ubTestTask
//
//  Created by Ivan_Tests on 26.04.2025.
//

import Foundation

/// a model for displaying a list item with a small image size for UI performance ( list, scrolling...)
struct PostListDataModel {
    let id:NonEmptyContainer<String>
    let title:NonEmptyContainer<String>
    let imageData:Data
}

/// a model for displaying larger size image and some additional details text
struct PostDetailsDataModel {
    let id:NonEmptyContainer<String>
    let title:NonEmptyContainer<String>
    let details:NonEmptyContainer<String>
    let imageData:Data
}
