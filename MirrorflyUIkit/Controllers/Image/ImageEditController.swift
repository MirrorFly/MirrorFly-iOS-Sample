//
//  ImageEditController.swift
//  MirrorflyUIkit
//
//  Created by User on 01/09/21.
//

import UIKit
import Photos
import BSImagePicker
import AVKit
import Tatsi
import FlyCommon
import GrowingTextViewHandler_Swift

protocol EditImageDelegate: class {
    func selectedImages(images: [ImageData])
}

class ImageEditController: UIViewController {
    @IBOutlet weak var addImage: UIImageView?
    @IBOutlet weak var addMoreButton: UIButton?
    @IBOutlet weak var deleteViw: UIView!
    @IBOutlet weak var addmore: UIView!
    @IBOutlet weak var captionTxt: UITextView?
    @IBOutlet weak var botomCollection: UICollectionView!
    @IBOutlet weak var topCollection: UICollectionView!
    @IBOutlet weak var captionHeightCons: NSLayoutConstraint?
    @IBOutlet weak var keyboardView: UIView?
    @IBOutlet weak var keyboardTopCons: NSLayoutConstraint?
    @IBOutlet weak var captionBottomCons: NSLayoutConstraint?
    @IBOutlet weak var TopViewCons: NSLayoutConstraint?
    @IBOutlet weak var captionViewTopCons: NSLayoutConstraint?
    @IBOutlet weak var bottomCollectionCons: NSLayoutConstraint?
    
    var growingTextViewHandler:GrowingTextViewHandler?
    public var imageAray = [ImageData]()
    public var selectedAssets = [PHAsset]()
    var imageEditIndex = Int()
    var botmImageIndex = Int()
    weak var delegate: EditImageDelegate? = nil
    var profileName = ""
    var captionText: String?
    public var iscamera = false
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        captionTxt?.inputAccessoryView = UIView()
        captionTxt?.inputAccessoryView?.tintColor = .clear
        checkForSlowMotionVideo()
        keyboardView = captionTxt?.inputAccessoryView
        setupUI()
    }
    
    private func checkForSlowMotionVideo() {
        imageAray.enumerated().forEach { (index, imageData) in
            if imageData.isVideo {
                if let phAsset = imageData.videoUrl {
                    PHCachingImageManager().requestAVAsset(forVideo: phAsset, options: nil) { [weak self] (asset, audioMix, args) in
                        if let avComposition = asset as? AVComposition {
                            DispatchQueue.main.async {
                                self?.startLoading(withText: processingVideo)
                            }
                            ChatUtils.compressSlowMotionVideo(asset: avComposition, onCompletion: { isSuccess, url in
                                DispatchQueue.main.async {
                                    self?.stopLoading()
                                }
                                if isSuccess {
                                    if let tempUrl = url {
                                        self?.imageAray[index].slowMotionVideoUrl = tempUrl
                                        self?.imageAray[index].isSlowMotion = true
                                    }
                                }
                            })
                        }
                    }
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        navigationController?.navigationBar.isHidden = false
        NotificationCenter.default.removeObserver(self, name:UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name:UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    func setupUI() {
        showHideDeleteView()
        showHideAddMoreOption()
        if iscamera {
            addmore.isHidden = true
            deleteViw.isHidden = true
        }
        botomCollection.isPagingEnabled = true
        setDefault()
        captionTxt?.delegate = self
        captionTxt?.font = UIFont.font12px_appRegular()
        captionTxt?.textContainerInset = UIEdgeInsets(top: 15, left: 10, bottom: 15, right: 10)
        captionTxt?.text = (captionText?.isNotEmpty ?? false) ? captionText : addCaption
        captionTxt?.textColor = Color.captionTxt
        captionTxt?.layer.cornerRadius = 20
        captionTxt?.clipsToBounds = true
        growingTextViewHandler = GrowingTextViewHandler(textView: captionTxt ?? UITextView(), heightConstraint: captionHeightCons ?? NSLayoutConstraint())
        growingTextViewHandler?.minimumNumberOfLines = chatTextMinimumLines
        growingTextViewHandler?.maximumNumberOfLines = chatTextMaximumLines
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: (topCollection?.frame.size.width ?? 0.0), height: (topCollection?.frame.size.width ?? 0.0))
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .horizontal
        topCollection?.collectionViewLayout = layout
        topCollection?.isPagingEnabled = true
        let layout2: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout2.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout2.itemSize = CGSize(width: 50, height: 50)
        layout2.minimumInteritemSpacing = 10
        layout2.minimumLineSpacing = 2
        layout2.scrollDirection = .horizontal
        layout2.footerReferenceSize = CGSize(width: 300, height: 50)
        botomCollection!.collectionViewLayout = layout2
        topCollection?.reloadData()
        botomCollection.reloadData()
    }
    
    private func showHideDeleteView() {
        deleteViw.isHidden = imageAray.count == 1 ? true : false
    }
    
    private func showHideAddMoreOption() {
        addMoreButton?.isUserInteractionEnabled = imageAray.count == 5 ? false : true
        addMoreButton?.alpha = imageAray.count == 5 ? 0.4 : 1.0
        addImage?.alpha = imageAray.count == 5 ? 0.4 : 1.0
    }
    
    @objc func appMovedToBackground() {
        closeKeyboard()
    }
    
    @objc func appMovedToForeground() {
        captionTxt?.becomeFirstResponder()
    }
    
    @IBAction func addMoreImages(_ sender: Any) {
        addMoreImages()
    }
    
    @IBAction func sendAction(_ sender: Any) {
        view.endEditing(true)
        navigationController?.popViewController(animated: true)
        if let captionText = captionTxt {
            captionTxt?.resignFirstResponder()
            textViewDidEndEditing(captionText)
        }
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.selectedImages(images: self?.imageAray ?? [])
        }
    }
    
    @IBAction func deleteAction(_ sender: Any) {
        if imageAray.count > 0 {
        self.selectedAssets.remove(at: imageEditIndex)
        imageAray.remove(at: imageEditIndex)
        topCollection?.reloadData()
        topCollection?.performBatchUpdates(nil, completion: {
            (result) in
            self.refresh()
            self.showHideDeleteView()
            self.showHideAddMoreOption()
        })
        self.botomCollection.reloadData()
        }
    }
    
    @IBAction func close(_ sender: Any) {
        popView()
    }
    
    func PHAssetForFileURL(url: URL) -> PHAsset? {
        let imageRequestOptions = PHImageRequestOptions()
        imageRequestOptions.version = .current
        imageRequestOptions.deliveryMode = .fastFormat
        imageRequestOptions.resizeMode = .fast
        imageRequestOptions.isSynchronous = true

        let fetchResult = PHAsset.fetchAssets(with: nil)
        var index = 0
        while index < fetchResult.count {
            if let asset = fetchResult[index] as? PHAsset {
                var found = false
                PHImageManager.default().requestImageData(for: asset,
                    options: imageRequestOptions) { (_, _, _, info) in
                    if let urlkey = info?["PHImageFileURLKey"] as? NSURL {
                        if urlkey.absoluteString! == url.absoluteString {
                                found = true
                            }
                        }
                }
                if (found) {
                    index += 1
                    return asset
                }
            }
        }

        return nil
    }
    
    func addMoreImages() {
        let imagePicker = ImagePickerController(selectedAssets: selectedAssets)
        imagePicker.settings.theme.selectionStyle = .numbered
        imagePicker.settings.fetch.assets.supportedMediaTypes = [.image,.video]
        imagePicker.settings.selection.max = 5
        imagePicker.settings.preview.enabled = true
        presentImagePicker(imagePicker, select: { [weak self] (asset) in
            // User selected an asset. Do something with it. Perhaps begin processing/upload?
            if let strongSelf = self {
            if  let assetName = asset.value(forKey: "filename") as? String {
                let fileExtension = URL(fileURLWithPath: assetName).pathExtension
                if fileExtension.lowercased() == "png" || fileExtension.lowercased() == "jpg" || fileExtension.lowercased() == "jpeg" || fileExtension.lowercased() == "gif" {
                        strongSelf.selectedAssets.append(asset)
                } else if asset.mediaType == PHAssetMediaType.video {
                    strongSelf.selectedAssets.append(asset)
                } else {
                    AppAlert.shared.showToast(message: fileformat_NotSupport)
                }
            }
        }
            if imagePicker.selectedAssets.count > 4 {
                AppAlert.shared.showToast(message: ErrorMessage.restrictedMoreImages)
            }
        }, deselect: { [weak self] (asset) in
            // User deselected an asset. Cancel whatever you did when asset was selected.
        if let strongSelf = self {
            strongSelf.selectedAssets.enumerated().forEach { index , element in
                if element == asset {
                    strongSelf.selectedAssets.remove(at: index)
                }
            }
        }
        }, cancel: { (assets) in
            // User canceled selection.
        }, finish: { [weak self] (assets) in
            if let strongSelf = self {
            // User finished selection assets.
            let imgagesAry = strongSelf.getAssetThumbnail(assets: strongSelf.selectedAssets)
                strongSelf.imageAray.removeAll()
            for image in imgagesAry {
                let isVideo = image.isVideo
                let videoUrl = isVideo ? image.videoUrl : nil
                let imgData: ImageData = ImageData(image: image.image, caption: nil, isVideo: isVideo, videoUrl: videoUrl, isSlowMotion: false)
                strongSelf.imageAray.append(imgData)
                strongSelf.topCollection?.reloadData()
            if !strongSelf.iscamera {
                strongSelf.botomCollection.reloadData()
            }
                strongSelf.setDefault()
                strongSelf.showHideDeleteView()
                strongSelf.showHideAddMoreOption()
            }
            self?.checkForSlowMotionVideo()
            }
        })
    }
    
    func setDefault() {
        imageEditIndex = 0
        setCaption()
        botmImageIndex = 0
    }
    
    func refresh ()
    {
        if self.imageAray.count != 0
        {
            var visibleRect = CGRect()
            visibleRect.origin = topCollection.contentOffset
            visibleRect.size = topCollection.bounds.size
            let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
            if let indexPath = topCollection.indexPathForItem(at: visiblePoint)
            {
                self.imageEditIndex = indexPath.row
                let nxtimgDta = imageAray[imageEditIndex]
                botmImageIndex = imageEditIndex
                self.captionTxt?.text = nxtimgDta.caption
            }
        }
    }
    
    func getAssetThumbnail(assets: [PHAsset]) -> [ImageData]
    {
        var arrayOfImages = [ImageData]()
        for asset in assets {
        if  let assetName = asset.value(forKey: "filename") as? String {
                let fileExtension = URL(fileURLWithPath: assetName).pathExtension
            let manager = PHImageManager.default()
            let options = PHImageRequestOptions()
            options.version = .original
            options.isSynchronous = true
            manager.requestImageData(for: asset, options: options) { data, _, _, _ in
            if asset.mediaType == PHAssetMediaType.image {
                if let data = data {
                    if  let  img = UIImage(data: data) {
                        if fileExtension.lowercased() == "png" || fileExtension.lowercased() == "jpg" || fileExtension.lowercased() == "jpeg" || fileExtension.lowercased() == "gif" {
                            let imageDetail: ImageData = ImageData(image: img, caption: nil, isVideo: false, videoUrl: nil, isSlowMotion: false)
                            arrayOfImages.append(imageDetail)
                        }
                    }
                }
            } else if asset.mediaType == PHAssetMediaType.video {
                if let data = data {
                  if  let  image = UIImage(data: data) {
                      let imageDetail: ImageData = ImageData(image: image, caption: nil, isVideo: true, videoUrl: asset, isSlowMotion: false)
                    arrayOfImages.append(imageDetail)
                    }
                }
            }
                
            } } else {
            arrayOfImages.removeAll()
            break
        }
    }
        return arrayOfImages
    }
    
    func popView() {
        navigationController?.popViewController(animated: true)
        selectedAssets = []
    }
    
    func closeKeyboard() {
        self.view.endEditing(true)
    }
}

extension ImageEditController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == topCollection {
        return imageAray.count
        }else{
            if iscamera {
                return   0
            }else{
                return imageAray.count
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == topCollection {
        let noOfCellsInRow = 1

        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout

        let totalSpace = flowLayout.sectionInset.left
            + flowLayout.sectionInset.right
            + (flowLayout.minimumInteritemSpacing * CGFloat(noOfCellsInRow - 1))

        let size = Int((view.bounds.width))
            let height = Int((view.bounds.height))

        return CGSize(width: size, height: height)
        }else {
        return CGSize(width: 50, height: 50)
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == topCollection {
            let cell:EditImageCell = collectionView.dequeueReusableCell(withReuseIdentifier: Identifiers.editImageCell, for: indexPath) as! EditImageCell
            let imgeDetail = imageAray[indexPath.row]
            cell.cellImage?.contentMode = .scaleAspectFit
            cell.cellImage?.image = imgeDetail.image
            cell.playButton?.isHidden = true
            print("ImageEditorController \(imgeDetail.isVideo)")
            if imgeDetail.isVideo {
                cell.playButton?.isHidden = false
            }
            cell.playButton?.tag = indexPath.row
            cell.playButton?.addTarget(self, action: #selector(onVideoPlay(sender:)), for: .touchUpInside)
            return cell
        }else{
            let cell:ListImageCell = collectionView.dequeueReusableCell(withReuseIdentifier: Identifiers.listImageCell, for: indexPath) as! ListImageCell
            let imgeDetail = imageAray[indexPath.row]
            cell.cellImage.contentMode = .scaleAspectFill
            cell.cellImage.image = imgeDetail.image
            if botmImageIndex == indexPath.row {
                cell.setBorder()
            }else {
                cell.removeBorder()
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == botomCollection {
            topCollection?.scrollToItem(at: indexPath, at: .left, animated: true)
            imageEditIndex = indexPath.row
            botmImageIndex = indexPath.row
            botomCollection.reloadData()
            topCollection.layoutIfNeeded()
            let rect = topCollection.layoutAttributesForItem(at:indexPath)?.frame
            topCollection.scrollRectToVisible(rect!, animated: true)
            setCaption()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch kind {
        case UICollectionView.elementKindSectionFooter:
            let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "EditImageFoorterView", for: indexPath) as! EditImageFoorterView
            footerView.name.text = profileName
            return footerView
            
        default:
            fatalError("Unexpected element kind")
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        var visibleRect = CGRect()
        visibleRect.origin = topCollection.contentOffset
        visibleRect.size = topCollection.bounds.size
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        captionTxt?.endEditing(true)
        setCaption()
        guard let indexPath = topCollection.indexPathForItem(at: visiblePoint) else { return }
        self.imageEditIndex = indexPath.row
        botmImageIndex = indexPath.row
        botomCollection.reloadData()
        setCaption()
    }
    
    func setCaption() {
        if imageEditIndex <= imageAray.count {
            let imgDetail = imageAray[imageEditIndex]
            if let caption = imgDetail.caption, caption != "" {
                captionTxt?.text = imgDetail.caption
                captionTxt?.textColor = Color.captionTxt
                setCaptionHeightCons()
            } else{
                captionTxt?.text = (captionText?.isNotEmpty ?? false && imageEditIndex == 0) ? captionText : addCaption
                captionTxt?.textColor = Color.captionTxt
                setCaptionHeightCons()
            }
        }
    }
    
    private func setCaptionHeightCons() {
        let sizeToFitIn = CGSize(width: captionTxt?.bounds.size.width ?? 0.0, height: CGFloat(MAXFLOAT))
        let newSize = captionTxt?.sizeThatFits(sizeToFitIn)
        captionHeightCons?.constant = newSize?.height ?? 0.0
    }
    
    private func addKeyboardConstraints() {
        keyboardTopCons?.isActive = true
        captionBottomCons?.isActive = false
        TopViewCons?.isActive = false
        captionViewTopCons?.isActive = false
        bottomCollectionCons?.isActive = true
    }
    
    private func removeKeyboardConstraints() {
        keyboardTopCons?.isActive = false
        captionBottomCons?.isActive = true
        TopViewCons?.isActive = true
        captionViewTopCons?.isActive = true
        bottomCollectionCons?.isActive = false
    }
}

extension ImageEditController : UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        addKeyboardConstraints()
        if textView == captionTxt {
            if textView.textColor == UIColor.darkGray {
                textView.textColor = UIColor.black
                if textView.text == addCaption {
                    textView.text = ""
                }
            }
        }
        if captionTxt?.text.contains(addCaption) == true {
            textView.text = captionTxt?.text.replacingOccurrences(of: addCaption, with: "")
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if imageEditIndex == 0 {
            captionText = nil
        }
        if let character = text.first, character.isNewline {
            textView.resignFirstResponder()
            removeKeyboardConstraints()
            return false
        }
        
        let newText = (textView.text as NSString).replacingCharacters(in: range, with: text)
        let numberOfChars = newText.count
        return numberOfChars <= 1024
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView == captionTxt {
            let sizeToFitIn = CGSize(width: captionTxt?.bounds.size.width ?? 0.0, height: CGFloat(MAXFLOAT))
            let newSize = captionTxt?.sizeThatFits(sizeToFitIn)
            if newSize?.height ?? 0.0 <= 110 {
                captionHeightCons?.constant = newSize?.height ?? 0.0
            } else {
                captionHeightCons?.constant = 110
                captionTxt?.isScrollEnabled = true
            }
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        removeKeyboardConstraints()
        if textView == captionTxt {
            if textView.text.isEmpty {
                captionTxt?.text = (captionText?.isNotEmpty ?? false) ? captionText : addCaption
            }else {
                var imgDetail = imageAray[imageEditIndex]
                imgDetail.caption = textView.text == addCaption ? "" : textView.text.trim()
               // textView.textColor = textView.text == addCaption ? UIColor.clear : Color.captionTxt
                imageAray[imageEditIndex] = imgDetail
            }
        }
    }
}

extension ImageEditController {
    @objc func onVideoPlay(sender: UIButton) {
        print("indexPath.row: onVideoPlay")
        let index = sender.tag
        print("indexPath.row: \(index)")
        let imageDetail = imageAray[index]
        playVideo(view: self, phAsset: imageDetail.videoUrl)
    }
    
    func playVideo (view:UIViewController, phAsset: PHAsset?) {
        guard (phAsset!.mediaType == PHAssetMediaType.video) else {
            print("Not a valid video media type")
            return
        }
        
        PHCachingImageManager().requestAVAsset(forVideo: phAsset!, options: nil) { (asset, audioMix, args) in
            if let _ = asset as? AVComposition {
                let options = PHVideoRequestOptions()
                options.isNetworkAccessAllowed = true
                PHCachingImageManager().requestPlayerItem(forVideo: phAsset!, options: options) { (playerItem, info) in
                    DispatchQueue.main.async {
                        let player = AVPlayer(playerItem: playerItem)
                        let playerViewController = AVPlayerViewController()
                        playerViewController.player = player
                        view.present(playerViewController, animated: true) {
                            playerViewController.player!.play()
                        }
                    }
                }
            } else {
                let asset = asset as! AVURLAsset
                DispatchQueue.main.async {
                    let player = AVPlayer(url: asset.url)
                    let playerViewController = AVPlayerViewController()
                    playerViewController.player = player
                    view.present(playerViewController, animated: true) {
                        playerViewController.player!.play()
                    }
                }
            }
        }
    }
}


