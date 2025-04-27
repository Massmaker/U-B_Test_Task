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
        self.listVC?.receivePostItems(postItems)
    }
    
    func updatePost(postId:Int, withImageData data:Data) {
        guard let image = UIImage(data: data, scale: UIScreen.main.scale) else {
            return
        }
        
        if image.size.width > 100 || image.size.height > 100 {
            //resize image to a smaller one
            let smallerImage = image.aspectFittedToHeight(100, newWidth: 100)
            
            guard let imageData = smallerImage.jpegData(compressionQuality: 1.0) else {
                listVC?.updatePost(id: postId, with: data)
                return
            }
            
            listVC?.updatePost(id: postId, with: imageData)
            
        }
        
    }
}


extension UIImage
{
    /// Given a required height, returns a (rasterised) copy
    /// of the image, aspect-fitted to that height.

    func aspectFittedToHeight(_ newHeight: CGFloat, newWidth:CGFloat) -> UIImage {
       
        let scale = newHeight / self.size.height
        let newWidth = self.size.width * scale
        let newSize = CGSize(width: newWidth, height: newHeight)
        let renderer = UIGraphicsImageRenderer(size: newSize)

        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
