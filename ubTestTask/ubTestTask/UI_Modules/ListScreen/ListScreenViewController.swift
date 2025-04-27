//
//  ViewController.swift
//  ubTestTask
//
//  Created by Ivan_Tests on 26.04.2025.
//

import UIKit

protocol ListScreenViewControllerType: UIViewController {
    func receivePostItems(_ items:[PostListDataModel])
    func updatePost(id:Int, with imageData:Data)
}

class ListScreenViewController: UIViewController {
    var interactor: (any ListScreenInteractorType)?
    var router: (any ToDetailsRouterType)?
    
    private var isIpad:Bool = false
    private var postItems:[PostListDataModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        
        let verticalClass = traitCollection.verticalSizeClass
        let horizontalClass = traitCollection.horizontalSizeClass
        
        print("\(#function) vertical: \(verticalClass), horizontal: \(horizontalClass)")
        
        isIpad = (verticalClass == .regular && horizontalClass == .regular)
        
        interactor?.onViewDidLoad()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        
        
        print("\(#function) Size Rotating to \(size.width) X \(size.height)")
        coordinator.animateAlongsideTransition(in: nil, animation: nil) { context in
            print("\(#function) Size Finished rotation in \(context.transitionDuration)")
        }

        super.viewWillTransition(to: size, with: coordinator)
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        
        if newCollection.horizontalSizeClass == .compact && newCollection.verticalSizeClass == .compact {
            print("Small iPhone in Landscape Mode")
        }
     
    }
    
    override func viewWillAppear(_ animated:Bool) {
        super.viewWillAppear(animated)
        
        interactor?.onViewWillAppear(animated)
    }
}

extension ListScreenViewController : ListScreenViewControllerType {
    func receivePostItems(_ items:[PostListDataModel]) {
        self.postItems.append(contentsOf: items)
    }
    
    func updatePost(id:Int, with imageData:Data) {
        if let index = self.postItems.firstIndex(where: {$0.id.value == "\(id)"}) {
            var toUpdate = self.postItems[index]
            
            toUpdate.imageData = imageData
            self.postItems[index] = toUpdate
        }
    }
}

extension UIUserInterfaceSizeClass: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .unspecified:
             "Unspecified"
        case  .compact:
             "Compact"
        case .regular:
             "Regular"
        @unknown default:
           "Unknown Unhandled"
        }
    }
}
