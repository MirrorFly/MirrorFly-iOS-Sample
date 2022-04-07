//  ImageCell.swift
//  MirrorflyUIkit
//  Created by User on 03/09/21.

import UIKit
import FlyCommon
class ImageCell: UICollectionViewCell, UIScrollViewDelegate {
    
    @IBOutlet weak var cellImage: UIImageView!
    @IBOutlet weak var zoomScroll: UIScrollView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setupUI()
    }
    
    func setupUI() {
        zoomScroll?.maximumZoomScale = 5.0
        zoomScroll?.minimumZoomScale = 1.0
        zoomScroll?.clipsToBounds = false
        zoomScroll?.delegate = self
    }
    func getCellFor(_ message: ChatMessage?, at indexPath: IndexPath?) -> ImageCell? {
       // if message?.mediaChatMessage?.mediaDownloadStatus == .downloaded {
            if let localPath = message?.mediaChatMessage?.mediaFileName {
                let directoryURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let folderPath: URL = directoryURL.appendingPathComponent("FlyMedia/Image", isDirectory: true)
                let fileURL: URL = folderPath.appendingPathComponent(localPath)
                if FileManager.default.fileExists(atPath:fileURL.relativePath) {
                        let data = NSData(contentsOf: fileURL)
                    let image = UIImage(data: data! as Data)
                cellImage.image = image
                }else {
                    if let thumImage = message?.mediaChatMessage?.mediaThumbImage {
                    let converter = ImageConverter()
                        let image =  converter.base64ToImage(thumImage)
                    cellImage.image = image
                    }
                    }
            }else {
            if let thumImage = message?.mediaChatMessage?.mediaThumbImage {
            let converter = ImageConverter()
                let image =  converter.base64ToImage(thumImage)
            cellImage.image = image
            }
            }
        cellImage.contentMode = .scaleToFill
      //  }
        return self
    }
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if scrollView.zoomScale > 1 {
            if let image = cellImage.image {
                let ratioW = cellImage.frame.width / image.size.width
                let ratioH = cellImage.frame.height / image.size.height
                
                let ratio = ratioW < ratioH ? ratioW : ratioH
                let newWidth = image.size.width * ratio
                let newHeight = image.size.height * ratio
                let conditionLeft = newWidth*scrollView.zoomScale > cellImage.frame.width
                let left = 0.5 * (conditionLeft ? newWidth - cellImage.frame.width : (scrollView.frame.width - scrollView.contentSize.width))
                let conditioTop = newHeight*scrollView.zoomScale > cellImage.frame.height
                
                let top = 0.5 * (conditioTop ? newHeight - cellImage.frame.height : (scrollView.frame.height - scrollView.contentSize.height))
                
                scrollView.contentInset = UIEdgeInsets(top: top, left: left, bottom: top, right: left)
                
            }
        } else {
            scrollView.contentInset = .zero
        }
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
           return cellImage
    }
}
