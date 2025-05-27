//
//  PostsStorageServiceProtocols.swift
//  ubTestTask
//
//  Created by Ivan_Tests on 30.04.2025.
//

import UIKit

//MARK: - UI Models
protocol ImageContainer {
    var image:UIImage? { get }
}

protocol ListItemUIModelType:ImageContainer, Hashable {
    var id:NonEmptyContainer<String> {get}
    var title:NonEmptyContainer<String> {get}
    var image:UIImage? {get}
}

protocol ListModelResultType {
    var identifier: NonEmptyContainer<String> {get}
    var title: NonEmptyContainer<String> {get}
    var imageData:Data? {get}
}

extension ListModelResultType {
    var uiModel:some ListItemUIModelType {
        guard let data = imageData else {
            return PostListDataModel(id: identifier, title: title)
        }
        
        return PostListDataModel(id: identifier, title: title, image: UIImage(data: data))
    }
}

protocol DetailsItemUIModelType: ImageContainer {
    var id:NonEmptyContainer<String>{get}
    var title:NonEmptyContainer<String>{get}
    var textString:NonEmptyContainer<String>{get}
    var image:UIImage? {get}
}

protocol DetailsModelResultType {
    var identifier: NonEmptyContainer<String> {get}
    var title: NonEmptyContainer<String> {get}
    var details:NonEmptyContainer<String> {get}
    var imageData:Data? {get}
}

extension DetailsModelResultType {
    var uiModel:DetailsItemUIModelType {
        guard let data = imageData else {
            return PostDetailsDataModel(id:identifier, title:title, textString:details)
        }
        
        return PostDetailsDataModel(id:identifier, title:title, textString:details, image:UIImage(data: data))
    }
}

//MARK: - Data models
//downloadable data to persist and convert back into UI models
protocol ListItemInfoContainer: Sendable {
    var date:Date {get}
    var identifier:String {get}
    var sol:Int {get}
    var imageSourceURLString:String {get}
    var cameraName:String {get}
    var roverName:String {get}
}

//MARK: - Errors
enum PostListDataModelStorageError: Error {
    case noData
    case partialResult([PostListDataModel])
}

enum PersistentStoreError: Error {
    case internalError((any Error)?)
}

enum FetchError: Error {
    case noDataFetched
    case partialResultFetched([PostListDataModel])
}


//MARK: -
protocol PostListDataModelStorage: AnyObject {
    var delegate:(any PostListDataModelStorageDelegate)? {get set}
    func getListPosts(page:Int, pageSize:Int) throws (PostListDataModelStorageError) -> [ListModelResultType]
    func receive(postListItems:[any ListItemInfoContainer])
    func setImageData(_ data:Data, forListPostId listPostId:String, saveImmediately:Bool)
    func saveIfNeeded()
}

protocol NetworkAPICallerAsync {
    func getBatch(page:Int) async throws(NetworkAPICallerError) -> [any ListItemInfoContainer]
    
    func loadImageData(for pathURL:String) async throws(NetworkAPICallerError) -> Data
}
