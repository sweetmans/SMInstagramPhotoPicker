//
//  Copyright © 2021年 Sweetman, Inc. All rights reserved.
//

import UIKit
import Photos

public class InstagramPhotosLibraryView: UIView {
    struct Measurements {
        static let imageCellName = "InstagramPhotosImageCell"
        static let libraryViewName = "InstagramPhotosLibraryView"
    }
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var showAlbumsButton: UIButton!
    @IBOutlet weak var squareMask: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var addingMoreImageVisualView: UIVisualEffectView!
    @IBOutlet weak var progressView: InstagramPhotosProgressView!
    @IBOutlet weak var addingMoreButton: UIButton!
    @IBOutlet weak var actionViewHeightConstraint: NSLayoutConstraint!
    
    lazy var imageView: UIImageView = {
        let i = UIImageView()
        i.contentMode = .scaleAspectFill
        i.clipsToBounds = true
        return i
    }()
    
    var currentAsset: PHAsset?
    var currentImageRequestID: PHImageRequestID?
    var isOnDownloadingImage: Bool = true
    
    var images: PHFetchResult<PHAsset>!
    var imageManager: PHCachingImageManager?
    var phAsset: PHAsset!
    
    var scale: CGFloat = 1.0
    var scaleRect: CGRect = CGRect.zero
    var imageScale: CGFloat = 1.0
    
    var pickingInteractor: InstagramPhotosPickingInteracting?
    private var isDisplayingLimitedLibraryPicker = false
    private let albumsProvider: InstagramPhotosAlbumsProviding = InstagramPhotosAlbumsProvider()
    private let authorizationProvider: InstagramPhotosAuthorizationProviding = InstagramPhotosAuthorizationProvider()
    
    public static func instance() -> InstagramPhotosLibraryView {
        let view = UINib(nibName: Measurements.libraryViewName,
                         bundle: Bundle(for: self.classForCoder())).instantiate(withOwner: self, options: nil)[0] as! InstagramPhotosLibraryView
        view.initialize()
        InstagramPhotosLocalizationManager.main.addLocalizationConponent(localizationUpdateable: view)
        return view
    }
    
    func initialize() {
        if images != nil { return }
        settingFirstAlbum()
        scrollView.addSubview(imageView)
        imageView.frame = scrollView.frame
        let cellNib = UINib(nibName: Measurements.imageCellName,
                            bundle: Bundle(for: InstagramPhotosLibraryView.classForCoder()))
        collectionView.register(cellNib, forCellWithReuseIdentifier: Measurements.imageCellName)
        addingMoreImageVisualView.clipsToBounds = true
        addingMoreImageVisualView.layer.cornerRadius = 23.0
        collectionView.selectItem(at: IndexPath.init(row: 0, section: 0), animated: false, scrollPosition: .bottom)
        switch authorizationProvider.authorizationStatus() {
        case .limited:
            let provider = InstagramPhotosLocalizationManager.main.localizationsProviding
            showAlbumsButton.setTitle(provider.photosLimitedAccessModeText(), for: .normal)
            showAlbumsButton.isUserInteractionEnabled = false
            addingMoreButton.layer.cornerRadius = 22.0
        default:
            addingMoreImageVisualView.isHidden = true
        }
        PHPhotoLibrary.shared().register(self)
    }
    
    func settingFirstAlbum() {
        guard let firstAlbum = InstagramPhotosAlbumsProvider().listAllAlbums().first else { return }
        images = firstAlbum.assets
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.collectionView.reloadData()
        }
        currentAsset = firstAlbum.assets.firstObject
        loadingAlbumFirstImage(album: firstAlbum)
    }
    
    func setupFirstLoadingImageAttrabute(image: UIImage) {
        self.imageView.image = image
        let se = self.cacuclateContentSize(original: image.size, target: self.scrollView.frame.size)
        self.scrollView.contentSize = se
        self.imageView.frame = CGRect(origin: CGPoint.zero, size: se)
        self.scaleRect = CGRect(origin: CGPoint.zero, size: scrollView.frame.size)
        self.scrollView.zoomScale = 1.0
        self.scale = 1.0
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        actionViewHeightConstraint.constant = InstagramPhotoDimensionalProvider().libraryActionViewheight()
    }
    
    func cacuclateContentSize(original: CGSize, target: CGSize) -> CGSize {
        var size = CGSize(width: 0, height: 0)
        if original.width > original.height {
            let scale = original.height / target.height
            let w = original.width / scale
            self.imageScale = scale
            size = CGSize(width: w, height: target.height)
        }else{
            let scale = original.width / target.width
            let w = original.height / scale
            self.imageScale = scale
            size = CGSize(width: target.width, height: w)
        }
        return size
    }
    
    func updateShowAlbumButton(title: String) {
        switch authorizationProvider.authorizationStatus() {
        case .limited:
            let provider = InstagramPhotosLocalizationManager.main.localizationsProviding
            showAlbumsButton.setTitle(provider.photosLimitedAccessModeText(), for: .normal)
            showAlbumsButton.isUserInteractionEnabled = false
        default:
            showAlbumsButton.setTitle(title, for: .normal)
            showAlbumsButton.isUserInteractionEnabled = true
        }
    }
    
    private func loadingAlbumFirstImage(album: InstagramPhotosAlbum) {
        guard let firstAsset = albumsProvider.fetchAlbumFirstAsset(collection: album.collection) else { return }
        albumsProvider.fetchAssetImage(asset: firstAsset, size: .original) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let image):
                self.setupFirstLoadingImageAttrabute(image: image)
            default:
                print("Selected ablum loading first image failure")
            }
        }
    }
}

extension InstagramPhotosLibraryView: InstagramPhotosLocalizationUpdateable {
    public func localizationContents() {
        let provider = InstagramPhotosLocalizationManager.main.localizationsProviding
        updateShowAlbumButton(title: provider.pinkingControllerDefaultAlbumName())
        addingMoreButton.setTitle(provider.pinkingControllerAddingImageAccessButtonText(), for: .normal)
    }
}

extension InstagramPhotosLibraryView {
    @IBAction func showAlbumsButtonAction(_ sender: Any) {
        guard let interactor = pickingInteractor else { return }
        interactor.showAlbumsView()
    }
    
    @IBAction func addingMoreButtonAction(_ sender: UIButton) {
        isDisplayingLimitedLibraryPicker = true
        pickingInteractor?.presentLimitedLibraryPicker()
    }
}

extension InstagramPhotosLibraryView: UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Measurements.imageCellName, for: indexPath) as! InstagramPhotosImageCell
        let asset = self.images[indexPath.row]
        PHImageManager.default().requestImage(for: asset,
                                              targetSize: CGSize(width: 300, height: 300),
                                              contentMode: .aspectFill,
                                              options: nil) { (image, info) in
            cell.image = image
        }
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images == nil ? 0 : images.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (UIScreen.main.bounds.width - 3) / 4.00
        return CGSize(width: width, height: width)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = images[indexPath.row]
        currentAsset = asset
        displayThubnailImage(asset: asset)
        displayOriginalImage(asset: asset)
    }
    
    private func displayThubnailImage(asset: PHAsset) {
        if let requestID = currentImageRequestID {
            PHImageManager.default().cancelImageRequest(requestID)
        }
        PHImageManager.default().requestImage(for: asset,
                                              targetSize: CGSize(width: 300, height: 300),
                                              contentMode: .aspectFill,
                                              options: nil) { [weak self] image, info in
            guard let self = self, let unwrapImage = image else { return }
            DispatchQueue.main.async {
                self.setupFirstLoadingImageAttrabute(image: unwrapImage)
            }
        }
    }
    
    private func displayOriginalImage(asset: PHAsset) {
        isOnDownloadingImage = true
        let targetSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
        progressView.isHidden = true
        let requestOptions = PHImageRequestOptions()
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.isNetworkAccessAllowed = true
        requestOptions.version = .original
        requestOptions.progressHandler = { [weak self] progress, err, pointer, info in
            guard let self = self else { return }
            self.displayProgressView(progress: progress)
        }
        DispatchQueue.global(qos: .userInteractive).async {
            self.currentImageRequestID = PHImageManager.default().requestImage(for: asset,
                                                                               targetSize: targetSize,
                                                                               contentMode: .aspectFill,
                                                                               options: requestOptions) { [weak self] image, info in
                guard let self = self else { return }
                self.isOnDownloadingImage = false
                self.currentImageRequestID = nil
                guard let unwrapImage = image else { return }
                DispatchQueue.main.async {
                    self.setupFirstLoadingImageAttrabute(image: unwrapImage)
                }
            }
        }
    }
    
    private func displayProgressView(progress: Double) {
        DispatchQueue.main.async {
            if self.progressView.isHidden {
                self.progressView.isHidden = false
            }
            self.progressView.progress = CGFloat(progress)
            if progress == 1.0 {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+0.3, execute: {
                    self.progressView.progress = 0.0
                    self.progressView.isHidden = true
                })
            }
        }
    }
}

extension InstagramPhotosLibraryView {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == self.scrollView {
            self.squareMask.isHidden = false
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == self.scrollView{
            self.squareMask.isHidden = true
            self.scaleRect = CGRect(origin: scrollView.contentOffset, size: scrollView.frame.size)
        }
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView == self.scrollView{
            self.squareMask.isHidden = true
            self.scaleRect = CGRect(origin: scrollView.contentOffset, size: scrollView.frame.size)
        }
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if scrollView == self.scrollView {
            self.squareMask.isHidden = false
        }
    }
    
    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        if scrollView == self.scrollView{
            self.scale = scale
            self.squareMask.isHidden = true
            self.scaleRect = CGRect(origin: scrollView.contentOffset, size: scrollView.frame.size)
        }
    }
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}


extension InstagramPhotosLibraryView: PHPhotoLibraryChangeObserver {
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        if isDisplayingLimitedLibraryPicker {
            settingFirstAlbum()
            isDisplayingLimitedLibraryPicker = false
        }
    }
}
