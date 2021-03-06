//
//  Copyright © 2021年 Sweetman, Inc. All rights reserved.
//

import UIKit

class InstagramPhotosImageCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!    
    @IBOutlet weak var mk: UIView!

    var image: UIImage? {
        didSet {
            self.imageView.image = image
        }
    }
    
    override var isSelected: Bool {
        didSet{
            if self.isSelected {
                self.mk.isHidden = false
            }else{
                self.mk.isHidden = true
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        isSelected = false
    }
}
