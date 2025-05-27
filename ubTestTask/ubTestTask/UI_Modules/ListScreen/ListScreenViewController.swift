//
//  ViewController.swift
//  ubTestTask
//
//  Created by Ivan_Tests on 26.04.2025.
//

import UIKit
fileprivate let logger = createLogger(subsystem: "ListScreenModule", category: "ListScreenViewController")

protocol ListScreenViewControllerType: UIViewController {
    func receivePostItems(_ items:[PostListDataModel])
    func updatePostItems(_ items:[PostListDataModel])
}

class ListScreenViewController: UIViewController {
    
    var interactor: (any ListScreenInteractorType)?
    var router: (any ToDetailsRouterType)?
    

    private var isScrolling:Bool = false
    private var isUpdating:Bool = false
    private var updatesQueue:[()->()] = []
    
    
    enum Section :Hashable {
        case main
    }
    
    private var collection:UICollectionView!
    private var currentLayout:UICollectionViewLayout?
    
    private lazy var collectionDataSource:UICollectionViewDiffableDataSource<Section, PostListDataModel> = {
        
        UICollectionViewDiffableDataSource<Section, PostListDataModel>(collectionView: collection, cellProvider: {collectionView,indexPath,itemIdentifier in
           
           guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ListCollectionViewCell.reuseIdentifier, for: indexPath) as? ListCollectionViewCell else {
               return UICollectionViewCell(frame: CGRect(x: 0, y: 0, width: 150, height: 150))
           }
           
            cell.titleLabel.text = itemIdentifier.title.value
            cell.subtitleLabel.text = itemIdentifier.id.value
            
            if let image = itemIdentifier.image {
                cell.imageView.image = image
            }
            else {
                cell.imageView.image = UIImage(systemName: "camera")
            }
            cell.contentView.layer.cornerRadius = 10
            cell.contentView.layer.borderColor = UIColor.lightGray.cgColor
            cell.contentView.layer.borderWidth = 2.0
            
           return cell
       })
    }()
    
    //MARK: - VC Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        logger.notice("\(#function)")
        navigationItem.title = "List"
        
        setupSubviews()
        setupCollection()
        
        var snap = collectionDataSource.snapshot()
        snap.appendItems([PostListDataModel](), toSection: Section.main)
        
        collectionDataSource.apply(snap, animatingDifferences: true)
        
        interactor?.onViewDidLoad()
    }
    
    override func viewWillAppear(_ animated:Bool) {
        super.viewWillAppear(animated)
        logger.notice("\(#function)")
        interactor?.onViewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated:Bool) {
        super.viewDidAppear(animated)
        logger.notice("\(#function)")
    }
    
    
    override func willTransition(
        to newCollection: UITraitCollection,
        with coordinator: any UIViewControllerTransitionCoordinator
    ) {
        super.willTransition(to: newCollection, with: coordinator)
        
        guard  view.traitCollection.horizontalSizeClass != newCollection.horizontalSizeClass ||
               view.traitCollection.verticalSizeClass != newCollection.verticalSizeClass else {
            //no need to handle layout here if this is presumably iPad
            return
        }
        
        setupLayout(traitCollection: newCollection)
        
        coordinator.animate(alongsideTransition: nil) {[weak self] context in
            if let self, let currentLayout = self.currentLayout {
                self.collection.setCollectionViewLayout(currentLayout, animated: true)
            }
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        //presumably iPad is rotating
        logger.notice("\(#function) Size Rotating to \(size.width) X \(size.height)")
        coordinator.animateAlongsideTransition(in: nil, animation: nil) { context in
            logger.notice("\(#function) Size Finished rotation in \(context.transitionDuration)")
        }

        super.viewWillTransition(to: size, with: coordinator)
    }
    
    //MARK: -
    private func setupSubviews() {
        
        view.backgroundColor = UIColor.lightGray
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        collectionView.delegate = self
        self.collection = collectionView
    }
    
    private func setupCollection() {
        setupLayout()
        if let layout = self.currentLayout {
            collection.setCollectionViewLayout(layout, animated: false)
        }
        var snapshot = collectionDataSource.snapshot()
        
        snapshot.appendSections([Section.main])
//        snapshot.appendItems([PostListDataModel](), toSection: .main)
        collectionDataSource.apply(snapshot)
    }
    
    private func setupLayout(traitCollection:UITraitCollection? = nil) {
        
        //let verticalSizeClass = traitCollection?.verticalSizeClass ?? .unspecified
        let horizontalSizeClass:UIUserInterfaceSizeClass
        
        if let input = traitCollection {
            horizontalSizeClass = input.horizontalSizeClass
        }
        else {
            
            horizontalSizeClass = view.traitCollection.horizontalSizeClass
        }
        
        collection.register(ListCollectionViewCell.self, forCellWithReuseIdentifier: ListCollectionViewCell.reuseIdentifier)
        
        
        let itemSize = NSCollectionLayoutSize(widthDimension: NSCollectionLayoutDimension.fractionalWidth(horizontalSizeClass == .regular ? 0.4 : 0.96),
                                              heightDimension: .estimated(100))
        
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.edgeSpacing = NSCollectionLayoutEdgeSpacing(leading: NSCollectionLayoutSpacing.fixed(4), top: .fixed(4), trailing: .flexible(8), bottom: .flexible(8))
        let groupSize = NSCollectionLayoutSize(widthDimension: NSCollectionLayoutDimension.fractionalWidth(1.0),
                                               heightDimension: NSCollectionLayoutDimension.estimated(100))
        
        let group:NSCollectionLayoutGroup
        if horizontalSizeClass == .regular {
            if #available(iOS 16.0, *) {
                group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, repeatingSubitem: item, count: 2)
            } else {
                // Fallback on earlier versions
                group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item, item])
            }
        }
        else {
            group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        }
//        group.interItemSpacing = NSCollectionLayoutSpacing.flexible(8)
//        group.contentInsets = .init(top: 0, leading: 8, bottom: 0, trailing: 8)
        let section = NSCollectionLayoutSection(group: group)
        // You can add section insets if needed
        // section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        section.interGroupSpacing = 8 // Add spacing between cells
        
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            return section
        })
        
        self.currentLayout = layout
        
    }
    
//    private func configureTableView() {
//        let tableView = UITableView()
//        tableView.translatesAutoresizingMaskIntoConstraints = false
//        
//        view.addSubview(tableView)
//        
//        NSLayoutConstraint.activate([
//            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
//            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
//            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
//        ])
//        
//        self.tableView = tableView
//        
//        tableView.register(PostListCell.self, forCellReuseIdentifier: PostListCell.reuseIdentifier)
//        
//        let ds = UITableViewDiffableDataSource<Section, PostListDataModel>(tableView: tableView) { tableView, indexPath, itemIdentifier in
//            guard let postListCell = tableView.dequeueReusableCell(withIdentifier: PostListCell.reuseIdentifier, for: indexPath) as? PostListCell else {
//                return UITableViewCell(style: .value2, reuseIdentifier: "DefaultCellIdentifier")
//            }
//            
//            let postItem = itemIdentifier
//            
//            if var config = postListCell.contentConfiguration as? UIListContentConfiguration {
//                config.text = postItem.title.value
//                config.secondaryText = postItem.id.value
//                
//                if let image = postItem.image {
//                    print(" Cell with Image for \(postItem.id.value)")
//                    config.image = image
//                }
//                
//                
//                postListCell.contentConfiguration = config
//            }
//            
//            return postListCell
//        }
//        self.dataSource = ds
//        
//        var snapshot = ds.snapshot()
//        snapshot.appendSections([Section.main])
//        //snapshot.appendItems([PostListDataModel](), toSection: Section.main)
//        ds.apply(snapshot)
//        
//        tableView.dataSource = ds
//        tableView.delegate = self
//    }
}

extension ListScreenViewController : ListScreenViewControllerType {
    
    func receivePostItems(_ items:[PostListDataModel]) {
        
        var snapshot = self.collectionDataSource.snapshot(for: Section.main)
        
        snapshot.append(items)
        
        collectionDataSource.apply(snapshot, to: Section.main, animatingDifferences: true, completion: {
            logger.notice("\(#function) Did end applying snapshot")
        })
    }
    
    func updatePostItems(_ items:[PostListDataModel]) {
        
        
        var snapshot = collectionDataSource.snapshot()
        
        items.forEach({item in
            
        let models = snapshot.itemIdentifiers(inSection: Section.main)
        
        guard let model = models.first(where: {$0.id.value == item.id.value}) else {
            return
        }
        
        logger.notice("\(#function)")
        
            if let path = collectionDataSource.indexPath(for: model) {
                let nextPath = NSIndexPath(item: path.item + 1, section: path.section)
                
                if path.item == models.count - 1 {
                    snapshot.deleteItems([model])
                    snapshot.appendItems([item])
                }
                else if let nextModel = models[safe: nextPath.item] {
                    snapshot.deleteItems([model])
                    snapshot.insertItems([item], beforeItem: nextModel)

                }
                else {
                    fatalError("Unhandled condition in List Screen")
                }
            }
        })
            
        snapshot.reconfigureItems(items)
        
        collectionDataSource.apply(snapshot)
    }
    
}

    
//MARK: Scrolling
extension ListScreenViewController:UIScrollViewDelegate {

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isScrolling = false
//        guard let dataSource else {
//            return
//        }
//                
//        let snapshot = dataSource.snapshot()
        
//        let currentItems = snapshot.itemIdentifiers(inSection: Section.main)
        
//        if let lastVisibleIndexPath = self.tableView.indexPathsForVisibleRows?.last,
//           let visibleListItem = dataSource.itemIdentifier(for: lastVisibleIndexPath),
//           visibleListItem == currentItems.last {
//    
//            interactor?.loadNextBatch()
//        }
        
        let lastVisibleItemPaths:[IndexPath] = self.collection.indexPathsForVisibleItems
            .sorted(by: {lhs, rhs in
                lhs.item < rhs.item
            })
        
        guard !lastVisibleItemPaths.isEmpty else {
            return
        }
        
        let snapshot = collectionDataSource.snapshot(for: Section.main)
        let currentItems = snapshot.visibleItems
        
        if let lastVisibleItemPath = lastVisibleItemPaths.last,
           let visibleItem = collectionDataSource.itemIdentifier(for: lastVisibleItemPath) {
            
            let isLast = visibleItem.id.value == currentItems.last?.id.value
            if isLast {
                interactor?.onScrolledToEnd()
            }
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

extension ListScreenViewController:UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
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
