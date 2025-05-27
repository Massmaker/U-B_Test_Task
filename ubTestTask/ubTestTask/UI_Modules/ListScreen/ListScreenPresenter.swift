//
//  ListScreenPresenter.swift
//  ubTestTask
//
//  Created by Ivan_Tests on 26.04.2025.
//



import Foundation
import UIKit


protocol ListScreenPresenterType {
    var displayedPostsCount:Int{get}
    func receiveLoadedPostItems(_ postItems:[any ListItemUIModelType])
    func updatePost(_ post:any ListItemUIModelType)
}



class ListScreenPresenter:ListScreenPresenterType {
    private weak var listVC:ListScreenViewControllerType?
    private(set) var displayedPostsCount:Int = 0
    
    @MainActor
    init(viewController:ListScreenViewController) {
        self.listVC = viewController
        viewController.title = "Posts"
        viewController.navigationItem.largeTitleDisplayMode = .never
    }
    
    func receiveLoadedPostItems(_ postItems:[any ListItemUIModelType]) {
        displayedPostsCount += postItems.count
        let uiModels = postItems.map({
            PostListDataModel(id: $0.id, title: $0.title, image: $0.image)
        })
        
       
//        DispatchQueue.main.async { [weak self] in
//            self?.listVC?.receivePostItems(uiModels)
//        }
    }
    
    func updatePost(_ post:any ListItemUIModelType) {
        
        let uiModel = PostListDataModel(id: post.id, title: post.title, image: post.image)
        
//        DispatchQueue.main.async {[weak self] in
//            self?.listVC?.updatePostItems([uiModel])
//        }
    }
}


extension UIImage
{
    /// Given a required height, returns a (rasterised) copy
    /// of the image, aspect-fitted to that height.

    func aspectFittedToHeight(_ newHeight: CGFloat, newWidth:CGFloat) -> UIImage {
        let minDimension = min(newHeight, newWidth)
        //if minDimension == newHeight
        
        let newSize = CGSize(width: minDimension, height: minDimension)
        let renderer = UIGraphicsImageRenderer(size: newSize)

        let image = renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return image
    }
}
