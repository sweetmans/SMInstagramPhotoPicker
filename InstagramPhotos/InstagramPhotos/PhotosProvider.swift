//
//  Copyright © 2021年 Sweetman, Inc. All rights reserved.
//

import InstagramPhotosPodspec

struct PhotosProvider: InstagramImagePicking {
    private let viewController: ViewController
    init(viewController: ViewController) {
        self.viewController = viewController
    }
    
    func instagramPhotosDidFinishPickingImage(result: InstagramImagePickingResult) {
        switch result {
        case .failure(let error):
            switch error {
            case .cancelByUser:
                print("User canceled selete image")
            default:
                print(error)
            }
        case .success(let ipImage):
            viewController.imageView.image = ipImage.image
        }
    }
}
