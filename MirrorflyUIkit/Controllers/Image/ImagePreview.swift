//  ImagePreview.swift
//  MirrorflyUIkit
//  Created by User on 03/09/21.


import UIKit
import FlyCore
import FlyCommon
class ImagePreview: UIViewController {
    
    @IBOutlet weak var imageList: UICollectionView!
    
    public var imageAray = [ChatMessage]()
    var isimgLoad = false
    var imageIndex = 0
    var jid = ""
    var messageId = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
     setupUI()
        // Do any additional setup after loading the view.
    congfigureDefaults()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        navigationController?.navigationBar.isHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        navigationController?.navigationBar.isHidden = true
    }
    
    func setupUI() {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: imageList.frame.size.width, height: imageList.frame.size.width)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .horizontal
        imageList!.collectionViewLayout = layout
      imageList.isPagingEnabled = false
    }
    
    func congfigureDefaults() {
    getImages()
    }
    
    func getImages() {
        imageAray  =  FlyMessenger.getMediaMessagesOf(jid: jid)
        if imageAray.count > 0 {
            if let selelctedImage = imageAray.first(where: { $0.messageId == messageId }) {
                imageIndex = imageAray.firstIndex(of: selelctedImage) ?? 0
                setTitle()
            }else{
               setTitle()
            }
        
        }
        imageList.reloadData()
    }
    
    func setTitle() {
        let imgeDetail = imageAray[imageIndex]
        if imgeDetail.isMessageSentByMe {
            self.title = sentMedia
        }else{
            self.title = receivedMedia
        }
    }
}

extension ImagePreview: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
{
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
    {
    if isimgLoad == false
    {
    isimgLoad = true
    imageList.scrollToItem(at:IndexPath(item: imageIndex, section: 0), at: .right, animated: false)
        imageList.isPagingEnabled = true
    }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let noOfCellsInRow = 1

        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout

        let totalSpace = flowLayout.sectionInset.left
            + flowLayout.sectionInset.right
            + (flowLayout.minimumInteritemSpacing * CGFloat(noOfCellsInRow - 1))

        let size = Int((view.bounds.width))
        let height = (Int((view.bounds.height)) / 2 + 50)

        return CGSize(width: size, height: height)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        imageAray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    var cell:ImageCell = collectionView.dequeueReusableCell(withReuseIdentifier: Identifiers.imageCell, for: indexPath) as! ImageCell
    let imgeDetail = imageAray[indexPath.row]
    cell.cellImage.contentMode = .scaleToFill
    cell = cell.getCellFor(imgeDetail, at: indexPath)!
    return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
    
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        var visibleRect = CGRect()
        visibleRect.origin = imageList.contentOffset
        visibleRect.size = imageList.bounds.size
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        guard let indexPath = imageList.indexPathForItem(at: visiblePoint) else { return }
        imageIndex = indexPath.row
        setTitle()
    }
}
