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
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setImage(_ image:UIImage) {
        imageView?.image = image
    }
    
    func setText(_ text:String) {
        self.textLabel?.text = text
    }

}
