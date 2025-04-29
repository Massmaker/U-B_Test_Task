//
//  ListCollectionViewCell.swift
//  CleanSwiftNoStoryboards
//
//  Created by Ivan_Tests on 29.04.2025.
//

import UIKit

class ListCollectionViewCell: UICollectionViewCell {
    static var reuseIdentifier:String = "\(ListCollectionViewCell.self)"
    
    let imageView = UIImageView()
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        
        // Configure your image view (e.g., contentMode)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.font = UIFont.headline
        titleLabel.numberOfLines = 0 // Allow for multiple lines if needed
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        
        subtitleLabel.font = UIFont.subheadline
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 1
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Set up constraints - adjust these based on your desired layout
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            //imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            imageView.widthAnchor.constraint(equalToConstant: 60), // Adjust image width
            imageView.heightAnchor.constraint(equalToConstant: 60),
            
            titleLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            subtitleLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 16),
            subtitleLabel.topAnchor.constraint(greaterThanOrEqualTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            subtitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8)
        ])
    }

}

extension UIFont {
    static var headline: UIFont {
        return UIFont.preferredFont(forTextStyle: .headline)
    }

    static var subheadline: UIFont {
        return UIFont.preferredFont(forTextStyle: .subheadline)
    }
}
