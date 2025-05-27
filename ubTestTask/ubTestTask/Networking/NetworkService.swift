//
//  NetworkService.swift
//  ubTestTask
//
//  Created by Ivan_Tests on 27.04.2025.
//

import Foundation
fileprivate let logger = createLogger(subsystem:"Networking", category:"NetworkService")

import Foundation




enum NetworkingError:Error {
    case badURL
    case badResponse
    case badStatusCode
    case badResponseData
}

enum NetworkAPICallerError:Error {
    case decodingError
    case networkingError(NetworkingError)
}


class NetworkService: @unchecked Sendable {
    let apiKey:String
    private let decoder:JSONDecoder
    private let session:URLSession
    private var currentBatchDataTask:URLSessionDataTask?
    
    init(apiKey: NonEmptyContainer<String>) {
        
        self.apiKey = apiKey.value
        
        let decoder = JSONDecoder()
        
        //customize JSON Decoding
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let dateFormatter:DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-mm-DD"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        self.decoder = decoder
        
        self.session = URLSession(configuration: .default)
    }
    
    
    private func handledBadResponse(response:URLResponse?, with data:Data?) -> Result<Data,NetworkingError> {
        guard let httpResponse = response as? HTTPURLResponse else {
            return .failure(NetworkingError.badResponse)
        }
        
        let statusCode = httpResponse.statusCode
        if statusCode / 100  != 2 {
            return .failure(NetworkingError.badStatusCode)
        }
        
        if let aData = data  {
            return .success(aData)
        }
        
        return .failure(NetworkingError.badResponseData)
    }
}



//MARK: - NASA Response
struct BatchItemsResopnse:Decodable {
    var photos:[PhotoInfo]
}

struct PhotoInfo:Decodable {
    private(set) var earthDate:Date
    private(set) var id:Int
    private(set) var sol:Int
    private(set) var imgSrc:String
    private(set) var camera:CameraInfo
    private(set) var rover:RoverInfo
}

struct CameraInfo:Decodable {
    private(set) var fullName:String
    let id:Int
    private(set) var name:String
    private(set) var roverId:Int
}

struct RoverInfo:Decodable {
    let id:Int
    private(set) var landingDate:Date
    private(set) var launchDate:Date
    private(set) var name:String
    private(set) var status:String
}

extension PhotoInfo {
    var displayTitle:String {
        "\(rover.name)_\(rover.status)_\(camera.fullName)_\(earthDate)"
    }
}


extension PhotoInfo:ListItemInfoContainer {
    var date: Date {
        earthDate
    }
    
    var identifier: String {
        "\(id)"
    }
    
    var imageSourceURLString: String {
        imgSrc
    }
    
    var cameraName: String {
        camera.fullName
    }
    
    var roverName: String {
        rover.name
    }
}


actor NetworkServiceActor {
    let apiKey:String
    private let decoder:JSONDecoder
    private var session:URLSession
    private var currentBatchDataTask:URLSessionDataTask?
    
    enum DataLoadingState {
        case inProgress(Task<Data?, any Error>)
        case completed(Data)
    }
    
    private lazy var pendingTasks:[String:DataLoadingState] = [:]
    
    init(apiKey: NonEmptyContainer<String>) {
        
        self.apiKey = apiKey.value
        
        let decoder = JSONDecoder()
        
        //customize JSON Decoding
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let dateFormatter:DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-mm-DD"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        self.decoder = decoder
        
        self.session = URLSession(configuration: .default)
    }
    
    /// handles actor re-entrancy
    private func loadData(for path:String) async throws -> Data? {
        
        if case let .inProgress(task) = pendingTasks[path] {
            return try await task.value
        }
        
        if case let .completed(data) = pendingTasks[path] {
            return data
        }
        
        let loadingTask = Task<Data?, any Error> {
            //actual networking call
            let imageURLRequest = try NetworkRequestsBuilder.buildGetImageDataRequest(for: path)
            let imageData = try await loadData(for: imageURLRequest)
            return imageData
        }
        
        pendingTasks[path] = .inProgress(loadingTask)
        
        guard let taskResultData = try await loadingTask.value else {
            return nil
        }
        
        pendingTasks[path] = .completed(taskResultData)
        
        return taskResultData
    }
    
    private func loadData(for request:URLRequest) async throws -> Data {
       
        do {
            let taskResponse = try await session.data(for: request)
            let data = taskResponse.0
            guard !data.isEmpty else {
                throw URLError(.badServerResponse)
            }
            return data
        }
        catch {
            throw error
        }
    }
}

extension NetworkServiceActor:NetworkAPICallerAsync {
   /// performa the data batch url request with the NAVCAM camera type
    func getBatch(page: Int) async throws(NetworkAPICallerError) -> [any ListItemInfoContainer] {
        let api = API.bySOL(page: page, cameraType: CameraType.NAVCAM)
        
        do {
            let request = try NetworkRequestsBuilder.buildGetRequest(for: api, apiKey: self.apiKey)
            let responseData = try await loadData(for: request)
            
            do {
                let batchResponse = try decoder.decode(BatchItemsResopnse.self, from: responseData)
                let photos = batchResponse.photos
                
                guard !photos.isEmpty else {
                    throw NetworkAPICallerError.networkingError(.badResponse)
                }
                
                return photos
                
            }
            catch let decodingError {
                throw NetworkAPICallerError.decodingError
            }
            
        }
        catch let networkingError as NetworkingError {
            throw .networkingError(networkingError)
        }
        catch {
            throw .networkingError(.badResponse)
        }
    }
    
    func loadImageData(for pathURL: String) async throws(NetworkAPICallerError) -> Data {
        do {
            guard let data = try await loadData(for: pathURL) else {
                throw NetworkAPICallerError.networkingError(NetworkingError.badResponseData)
            }
            
            return data
        }
        catch let urlSessionError { //actually here can be any error such as no internet connection, timeout ot any other error
            throw NetworkAPICallerError.networkingError(.badResponse)
        }
    }
}


fileprivate final class NetworkRequestsBuilder {
    static func buildGetRequest(for api: API, apiKey:String) throws(NetworkingError) -> URLRequest {
        
        var queryParameters:[String:Any]
        
        if var pathParams = api.urlPathParameters {
            pathParams["api_key"] = apiKey
            
            queryParameters = pathParams
        }
        else {
            queryParameters = [:]
        }
        
        guard var url = URL(string: api.baseURL) else {
            throw NetworkingError.badURL
        }
                
        
        let queryItems =
        queryParameters.map {stringKey, valueAny in
            if let string = valueAny as? String {
                return URLQueryItem(name: stringKey, value: string)
            }
            else {
                return URLQueryItem(name: stringKey, value: "\(valueAny)")
            }
            
        }
        
        if #available(iOS 16.0, *) {
            url.append(queryItems: queryItems)
        } else {
            guard var components = URLComponents(string: url.absoluteString) else {
                throw NetworkingError.badURL
            }
            
            components.queryItems = queryItems
            
            guard let newURL = components.url else {
                throw NetworkingError.badURL
            }
            
            url = newURL
        }
        
        let getURLString = api.requestPath()
        
        guard getURLString.firstIndex(of: "&") == nil else { //just some minimum safety
            throw NetworkingError.badURL //URLError(.unsupportedURL)
        }
        
        var request:URLRequest
        
        if let pathParams = api.urlPathParameters,
           var components = URLComponents(string: getURLString) {
            
            //using this approach for compatibility -> pre iOS 16
            let queryItems = pathParams.map({URLQueryItem(name: $0.key, value: "\($0.value)")})
            components.queryItems = queryItems
            guard let newURL = components.url else {
                throw NetworkingError.badURL //URLError(.unsupportedURL)
            }
            
            request = URLRequest(url: newURL)
        }
        else {
            guard let url = URL(string: getURLString) else {
                throw NetworkingError.badURL //URLError(.badURL)
            }
            request = URLRequest(url: url)
        }
        
        request.httpMethod = api.method.httpMethod
        
        
        return request
    }
    
    /// builds a simple GET URLRequest if the `imageURLString` is a valid URL
    static func buildGetImageDataRequest(for imageURLString:String) throws(NetworkingError) -> URLRequest {
        guard let url = URL(string: imageURLString) else {
            throw NetworkingError.badURL
        }
        
        let request = URLRequest(url: url)
        return request
    }
}


