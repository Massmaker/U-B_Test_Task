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
        
        let ds = UITableViewDiffableDataSource<Section, PostListDataModel>(tableView: tableView) {[unowned self] tableView, indexPath, itemIdentifier in
            guard let postListCell = tableView.dequeueReusableCell(withIdentifier: PostListCell.reuseIdentifier, for: indexPath) as? PostListCell else {
                return UITableViewCell(style: .value2, reuseIdentifier: "DefaultCellIdentifier")
            }
            
            let postItem = postItems[indexPath.row]
            let image = postItem.image
            postListCell.setImage(image)
            
            let title = postItem.title.value
            postListCell.setText(title)
            
            return postListCell
        }
        self.dataSource = ds
        
        var snapshot = ds.snapshot()
        snapshot.appendSections([Section.main])
        snapshot.appendItems([PostListDataModel](), toSection: Section.main)
        ds.apply(snapshot)
        
        tableView.dataSource = ds
        tableView.delegate = self
    }
}

extension ListScreenViewController : ListScreenViewControllerType {
    func receivePostItems(_ items:[PostListDataModel]) {
        self.postItems.append(contentsOf: items)
        
        var snapshot = self.dataSource.snapshot()
        snapshot.appendItems(items, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    func updatePost(id:Int, with imageData:Data) {
        
        if let index = self.postItems.firstIndex(where: {$0.id.value == "\(id)"}) {
            var toUpdate = self.postItems[index]
            
            toUpdate.imageData = imageData
            self.postItems[index] = toUpdate
            let indexPath = IndexPath(row: index, section: 0)
            
            
            if var listModel = dataSource.itemIdentifier(for: indexPath) {
                var snapshot = dataSource.snapshot()
                listModel.imageData = imageData
                snapshot.reloadItems([listModel])
                dataSource.apply(snapshot, animatingDifferences: true)
            }
        }
    }
}

extension ListScreenViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.interactor?.onItemSelected(at: indexPath.row)
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
