//
//  Copyright © 2021年 Sweetman, Inc. All rights reserved.
//

import UIKit

class SMPhotoPickAlbumViewCell: UITableViewCell {
    @IBOutlet weak var logoView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!
    
    var album: InstagramImageAlbum? {didSet{updateAlbumInfo()}}
    private let albumsProvider: InstagramImageAlbumsProviding = InstagramImageAlbumsProvider()
    
    func updateAlbumInfo() {
        guard let unwrapAlbum = album else { return }
        loadingAlbumFirstImage(album: unwrapAlbum)
        nameLabel.text = unwrapAlbum.name
        countLabel.text = "\(String(describing: unwrapAlbum.count)) photos"
    }
    
    private func loadingAlbumFirstImage(album: InstagramImageAlbum) {
        guard let firstAsset = albumsProvider.fetchAlbumFirstAsset(collection: album.collection) else { return }
        albumsProvider.fetchAssetImage(asset: firstAsset, size: .original) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let image):
                self.logoView.image = image
            default:
                print("setting first image failure")
            }
        }
    }
}
