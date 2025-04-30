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
    func receiveLoadedPostItems(_ postItems:[ListItemUIModelType])
    func updatePost(_ post:ListItemUIModelType)
}



class ListScreenPresenter:ListScreenPresenterType {
    private weak var listVC:ListScreenViewControllerType?
    private(set) var displayedPostsCount:Int = 0
    
    init(viewController:ListScreenViewController) {
        self.listVC = viewController
        viewController.title = "Posts"
        viewController.navigationItem.largeTitleDisplayMode = .never
    }
    
    func receiveLoadedPostItems(_ postItems:[ListItemUIModelType]) {
        displayedPostsCount += postItems.count
        let uiModels = postItems.map({
            PostListDataModel(id: $0.id, title: $0.title, image: $0.image)
        })
        
        DispatchQueue.main.async {[weak self] in
            self?.listVC?.receivePostItems(uiModels)
        }
    }
    
    func updatePost(_ post:ListItemUIModelType) {
       
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
