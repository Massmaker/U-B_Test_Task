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

protocol ListItemUIModelType:ImageContainer {
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
    var uiModel:ListItemUIModelType {
        guard let data = imageData else {
            return PostListDataModel(id: identifier, title: title)
        }
        
        return PostListDataModel(id: identifier, title: title, image: UIImage(data: data))
    }
}

//MARK: - Data models
//downloadable data to persist and convert back into UI models
protocol ListItemInfoContainer {
    var date:Date {get}
    var identifier:String {get}
    var sol:Int {get}
    var imageSourceURLString:String {get}
    var cameraName:String {get}
    var roverName:String {get}
}

//MARK: - Errors
enum PostListDataModelStorageError:Error {
    case noData
    case partialResult([PostListDataModel])
}

enum PersistentStoreError:Error {
    case internalError((any Error)?)
}

enum FetchError:Error {
    case noDataFetched
    case partialResultFetched([PostListDataModel])
}


//MARK: -
protocol PostListDataModelStorage :AnyObject{
    var delegate:(any PostListDataModelStorageDelegate)? {get set}
    func getListPosts(page:Int, pageSize:Int) throws (PostListDataModelStorageError) -> [ListModelResultType]
    func receive(postListItems:[ListItemInfoContainer])
    func setImageData(_ data:Data, forListPostId listPostId:String, saveImmediately:Bool)
    func saveIfNeeded()
}

protocol NetworkAPICaller {
    func getBatch(page:Int, completion:@escaping (Result<[ListItemInfoContainer], any Error>) -> ())
    func loadImageData(for urlString:NonEmptyContainer<String>, completion: @escaping (Result<Data, any Error>) -> ())
}
