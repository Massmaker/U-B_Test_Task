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

class NetworkService {
    let apiKey:String
    private let decoder:JSONDecoder
    private var session:URLSession
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


extension NetworkService:NetworkAPICaller {
    
    func getBatch(page: Int, completion: @escaping (Result<[any ListItemInfoContainer], any Error>) -> ()) {

        if let _ = currentBatchDataTask {
            return
        }
        
        let api = API.bySOL(page: page, cameraType: .all)
        var queryParameters = api.urlParameters
        queryParameters["api_key"] = self.apiKey
        queryParameters["sol"] = 1500
        
        guard var url = URL(string: api.baseURL) else {
            return
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
                completion(.failure(NetworkingError.badURL))
                return
            }
            
            components.queryItems = queryItems
            
            guard let newURL = components.url else {
                completion(.failure(NetworkingError.badURL))
                return
            }
            
            url = newURL
        }
        
        
        logger.notice("\(#function) Requesting address: \(url.absoluteString)")
        
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        
        let task = self.session.dataTask(with: urlRequest, completionHandler: {[weak self] optData, optResponse, optError in
            
            guard let self else { return }
            
            let result = self.handledBadResponse(response: optResponse, with: optData)
            
            switch result {
            case .failure(let networkingError):
                completion(.failure(NetworkAPICallerError.networkingError(networkingError)))
            case .success(let data):
                logger.notice("\(#function) Success loading")
                do {
                    let batchResponse:BatchItemsResopnse = try self.decoder.decode(BatchItemsResopnse.self, from: data)
                    
                    guard !batchResponse.photos.isEmpty else {
                        logger.notice("API Supplied No items in batch response")
                        completion(.failure(NetworkAPICallerError.networkingError(.badResponseData)))
                        self.currentBatchDataTask = nil
                        return
                    }
                    
                    logger.notice("API Supplied \(batchResponse.photos.count) items batch response")
                    
                    completion(.success(batchResponse.photos))
                    
                }
                catch {
                    completion(.failure(NetworkAPICallerError.decodingError) )
                }
            }
            
            self.currentBatchDataTask = nil
        })
        
        self.currentBatchDataTask = task
        task.resume()
        
    }
    
    
    func loadImageData(for urlString:NonEmptyContainer<String>, completion: @escaping (Result<Data, any Error>) -> ()) {
        
        
        guard urlString.value.hasPrefix("https:") else {
            completion(.failure(NetworkingError.badURL))
            return
        }
        guard let url = URL(string: urlString.value) else {
            completion(.failure(NetworkingError.badURL))
            return
        }
        
        
        let request = URLRequest(url: url)
        
        logger.notice("\(#function) Requesting address: \(request.url!.absoluteString)")
        
        let task =
        session.dataTask(with: request) {[weak self] dataOrNil, responseOrNil, errorOrNil in
            guard let self else { return }
            if let error = errorOrNil {
                completion(.failure(error))
                return
            }
            
            let result = self.handledBadResponse(response: responseOrNil, with: dataOrNil)
            
            switch result {
            case .success(let data):
                completion(.success(data))
            case .failure(let networkingError):
                completion(.failure(networkingError))
            }
        }
        
        task.resume()
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
