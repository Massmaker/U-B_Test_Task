//
//  PostListCell.swift
//  ubTestTask
//
//  Created by Ivan_Tests on 27.04.2025.
//

import UIKit

class PostListCell: UITableViewCell {

    static var reuseIdentifier:String = "\(PostListCell.self)"
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        imageView?.image = UIImage(named: "PostImagePlaceHolder")
        creatContentConfig()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        if var config = self.contentConfiguration as? UIListContentConfiguration {
            config.image = nil
            self.contentConfiguration = config
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setImage(_ image:UIImage) {
        if var config = self.contentConfiguration as? UIListContentConfiguration {
            config.image = image
            self.contentConfiguration = config
        }
    }
    
    func setText(_ text:String) {
        if var config = self.contentConfiguration as? UIListContentConfiguration{
            config.text = text
            
            self.contentConfiguration = config
        }
    }

    func setSecondaryText(_ text:String) {
        if var config = self.contentConfiguration as? UIListContentConfiguration{
            config.secondaryText = text
            
            self.contentConfiguration = config
        }
    }
    
    private func creatContentConfig() {
        var config = self.defaultContentConfiguration()
        config.imageProperties.maximumSize = CGSize(width: 100 , height: 100)
        config.imageProperties.cornerRadius = 10
        self.contentConfiguration = config
        
    }
}
