//
//  ListScreenPresenter.swift
//  ubTestTask
//
//  Created by Ivan_Tests on 26.04.2025.
//



import Foundation
import UIKit


protocol ListScreenPresenterType {
    func receiveLoadedPostItems(_ postItems:[PostListDataModel])
    func updatePost(postId:Int, withImageData data:Data)
}



class ListScreenPresenter:ListScreenPresenterType {
    private weak var listVC:ListScreenViewControllerType?
    
    init(viewController:ListScreenViewController) {
        self.listVC = viewController
        viewController.title = "Posts"
        viewController.navigationItem.largeTitleDisplayMode = .never
    }
    
    func receiveLoadedPostItems(_ postItems:[PostListDataModel]) {
        DispatchQueue.main.async {[weak self] in
            self?.listVC?.receivePostItems(postItems)
        }
        
    }
    
    func updatePost(postId:Int, withImageData data:Data) {
//        guard let image = UIImage(data: data, scale: UIScreen.main.scale) else {
//            return
//        }
        
        listVC?.updatePost(id: postId, with: data)
        
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
