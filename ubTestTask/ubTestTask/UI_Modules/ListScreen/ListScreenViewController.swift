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
    
    enum Section {
        case main
    }
    
    var interactor: (any ListScreenInteractorType)?
    var router: (any ToDetailsRouterType)?
    
    
    private var postItems:[PostListDataModel] = []
    private var tableView:UITableView!
    private var dataSource:UITableViewDiffableDataSource<Section,PostListDataModel>!
    private var isScrolling:Bool = false
    private var isUpdating:Bool = false
    private var updatesQueue:[()->()] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        
        let verticalClass = traitCollection.verticalSizeClass
        let horizontalClass = traitCollection.horizontalSizeClass
        
        print("\(#function) vertical: \(verticalClass), horizontal: \(horizontalClass)")
        
        
        configureTableView()
        
        
        
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
    
    private func configureTableView() {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
        
        self.tableView = tableView
        
        tableView.register(PostListCell.self, forCellReuseIdentifier: PostListCell.reuseIdentifier)
        
        let ds = UITableViewDiffableDataSource<Section, PostListDataModel>(tableView: tableView) { tableView, indexPath, itemIdentifier in
            guard let postListCell = tableView.dequeueReusableCell(withIdentifier: PostListCell.reuseIdentifier, for: indexPath) as? PostListCell else {
                return UITableViewCell(style: .value2, reuseIdentifier: "DefaultCellIdentifier")
            }
            
            let postItem = itemIdentifier
            
            if var config = postListCell.contentConfiguration as? UIListContentConfiguration {
                config.text = postItem.title.value
                config.secondaryText = postItem.id.value
                
                if let image = postItem.image {
                    print(" Cell with Image for \(postItem.id.value)")
                    config.image = image
                }
                
                
                postListCell.contentConfiguration = config
            }
            
            return postListCell
        }
        self.dataSource = ds
        
        var snapshot = ds.snapshot()
        snapshot.appendSections([Section.main])
        //snapshot.appendItems([PostListDataModel](), toSection: Section.main)
        ds.apply(snapshot)
        
        tableView.dataSource = ds
        tableView.delegate = self
    }
}

extension ListScreenViewController : ListScreenViewControllerType {
    func receivePostItems(_ items:[PostListDataModel]) {
        self.postItems.append(contentsOf: items)
        
        var snapshot = self.dataSource.snapshot()
        snapshot.appendItems(items, toSection: Section.main)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    func updatePost(id: Int, with imageData: Data) {
        
        if isUpdating {
            updatesQueue.append {[weak self, id, imageData] in
                self?.updatePost(id: id, with: imageData)
            }
            return
        }
        
        isUpdating = true
        
        guard let indexInPostItems = self.postItems.firstIndex(where: { $0.id.value == "\(id)" }) else {
            print("Post with ID \(id) not found in postItems")
            isUpdating = false
            takeNextUpdateIfNeeded()
            return
        }

        // 1. Create a modified copy of the data model
        let existing = self.postItems[indexInPostItems]
        
        let updatedPostItem = PostListDataModel(id: existing.id, title: existing.title, imageData: imageData)
        self.postItems[indexInPostItems] = updatedPostItem // Update local data immediately
      
        guard var currentSnapshot = dataSource?.snapshot() else {
            print("Data source snapshot is nil")
            isUpdating = false
            takeNextUpdateIfNeeded()
            return
        }
        let currentIdentifiers = currentSnapshot.itemIdentifiers
        let diff = self.postItems.difference(from:currentIdentifiers )
        guard let newIdentifiers = currentIdentifiers.applying(diff) else {
            isUpdating = false
            takeNextUpdateIfNeeded()
            return
        }
        
        currentSnapshot.deleteItems(currentIdentifiers)
        currentSnapshot.appendItems(newIdentifiers)
        
        dataSource?.apply(currentSnapshot, animatingDifferences: true, completion: {[weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                self?.isUpdating = false
                self?.takeNextUpdateIfNeeded()
            })
            
            print("DID Update Snapshot for \(id)")
        })
        
        
//        // 2. Get the current snapshot

//
//        var itemsToUpdate = currentSnapshot.itemIdentifiers(inSection: .main)
//        
//        
//        let currentIndexInSnapshot = currentSnapshot.indexOfItem(existing)!
//        dataSource.apply(currentSnapshot, animatingDifferences: true)
//
//        // 3. Find the existing item in the snapshot using its ID
//        if let itemToUpdate = itemsToUpdate.first(where: { $0.id.value == existing.id.value }) {
//            
//            // 4. Get the current index of the item in the snapshot
//            if let currentIndexInSnapshot = currentSnapshot.indexOfItem(itemToUpdate) {
//                // 5. Remove the old item
//                currentSnapshot.deleteItems([itemToUpdate])
//
//                // 6. Insert the updated item at the same index
//                let itemsInSection = currentSnapshot.itemIdentifiers(inSection: .main)
//                
//                if currentIndexInSnapshot <= itemsInSection.count {
//                    if currentIndexInSnapshot == 0 && !itemsInSection.isEmpty {
//                        currentSnapshot.insertItems([updatedPostItem], beforeItem: itemsInSection[0])
//                    } else if currentIndexInSnapshot < itemsInSection.count {
//                        currentSnapshot.insertItems([updatedPostItem], afterItem: itemsInSection[currentIndexInSnapshot - 1])
//                    } else {
//                        currentSnapshot.appendItems([updatedPostItem], toSection: .main) // Should ideally not happen if index is correct
//                    }
//                } else {
//                    currentSnapshot.appendItems([updatedPostItem], toSection: .main) // If section was empty
//                }
//
//                // 7. Apply the updated snapshot
//                dataSource.apply(currentSnapshot, animatingDifferences: false)
//                return
//            } else {
//                print("Post with ID \(id) not found in the current snapshot")
//                // Handle the case where the item isn't in the snapshot (shouldn't happen if data is consistent)
//            }
//        } else {
//            print("Could not find item with ID \(id) in snapshot")
//        }
        
        

    }
    
    private func takeNextUpdateIfNeeded() {
        isUpdating = false
        guard !self.updatesQueue.isEmpty else {
            return
        }
        
        let nextWorkItem = self.updatesQueue.removeFirst()
            
        nextWorkItem()
        
    }
}

extension ListScreenViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.interactor?.onItemSelected(at: indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if isScrolling {
            return
        }
        
        if self.postItems.count > 1, indexPath.row == self.postItems.count - 1 {
            interactor?.loadNextBatch()
        }
    }
    
    //MARK: Scrolling
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isScrolling = false
        if let lastVisibleIndexPath = self.tableView.indexPathsForVisibleRows?.last,
           lastVisibleIndexPath.row == self.postItems.count - 1 {
            interactor?.loadNextBatch()
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isScrolling = true
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            isScrolling = false
        }
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        isScrolling = false
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !isScrolling {
            isScrolling = true
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
