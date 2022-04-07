//
//  CHatTextView.swift
//  MirrorflyUIkit
//
//  Created by User on 23/08/21.
//

import UIKit
import FlyCommon
import MapKit
import GoogleMaps
class ChatTextView: UIView, UITextViewDelegate {
    @IBOutlet weak var messageTypeView: UIView?
    @IBOutlet weak var mediaMessageImageView: UIImageView?
    @IBOutlet weak var messageTypeLabel: UILabel?
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var closeButton: UIButton?
    @IBOutlet weak var messageTypeImage: UIImageView?
    @IBOutlet weak var closeView: UIView?
    @IBOutlet weak var contentView: UIView?
    @IBOutlet weak var innerView: UIView?
    @IBOutlet weak var closeImage: UIImageView?
    @IBOutlet weak var messageTypeWidthCons: NSLayoutConstraint?
    @IBOutlet weak var spacierView: UIView?
    @IBOutlet weak var mapView: GMSMapView?
    @IBOutlet weak var contactNameLabel: UILabel?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setupUI() {
        innerView?.layer.cornerRadius = 3.0
        innerView?.backgroundColor = Color.previewInnerBgColor
        contentView?.backgroundColor = Color.previewContentBgColor
        contentView?.roundCorners(corners: [.topRight,.bottomRight], radius: 3.0)
        closeView?.makeCircleView(borderColor: UIColor.white.cgColor, borderWidth: 1.0)
    }
    
    func setSenderReceiverMessage(message: ChatMessage) {
        mapView?.isHidden = true
        contactNameLabel?.isHidden = true
        titleLabel?.text = message.isMessageSentByMe ? "You" : message.senderUserName
        messageTypeImage?.isHidden = message.messageType == .text ? true : false
        if message.messageType != .text {
        let thumbImage = message.mediaChatMessage?.mediaThumbImage ?? ""
        let converter = ImageConverter()
        let image =  converter.base64ToImage(thumbImage)
            mediaMessageImageView?.image = image
            mediaMessageImageView?.isHidden = false
        } else {
            mediaMessageImageView?.isHidden = true
        }
        switch message.messageType {
        case .text:
            messageTypeLabel?.text =  message.messageTextContent
            messageTypeWidthCons?.constant = 0
            spacierView?.isHidden = true
        case .image:
            messageTypeLabel?.text =  !(message.mediaChatMessage?.mediaCaptionText.isEmpty ?? false) ? message.mediaChatMessage?.mediaCaptionText : "Photo"
            messageTypeWidthCons?.constant = 13
            spacierView?.isHidden = false
        case .audio:
            let duration = Int(message.mediaChatMessage?.mediaDuration ?? 0)
            messageTypeLabel?.text =  "\(duration.msToSeconds.minuteSecondMS) Audio"
            messageTypeWidthCons?.constant = 13
            spacierView?.isHidden = false
        case .contact:
            let messageType = message.messageType.rawValue.capitalized
            messageTypeLabel?.text =  message.isMessageSentByMe ? "\(message.messageType.rawValue.capitalized): " : "\(messageType): "
            contactNameLabel?.isHidden = false
            contactNameLabel?.text = message.contactChatMessage?.contactName
            messageTypeWidthCons?.constant = 13
            spacierView?.isHidden = false
        default:
            messageTypeLabel?.text =  message.messageType.rawValue.capitalized
            messageTypeWidthCons?.constant = 12
            spacierView?.isHidden = false
        }
        
        switch message.messageType {
        case .image:
            messageTypeImage?.image = UIImage(named: "senderCamera")
        case .video:
            messageTypeImage?.image = UIImage(named: "senderVideo")
        case .audio:
            messageTypeImage?.image = UIImage(named: "audio")
        case .contact:
            messageTypeImage?.image = UIImage(named: "senderContact")
        case .location:
            messageTypeImage?.image = UIImage(named: "map")
        default:
            break
        }
        if message.locationChatMessage != nil {
            mapView?.isHidden = false
            guard let latitude = message.locationChatMessage?.latitude else {
                return
            }
            guard let longitude = message.locationChatMessage?.longitude  else {
                return
            }
            
            mapView?.camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: 16.0, bearing: 360.0, viewingAngle: 15.0)
            
            DispatchQueue.main.async
            { [self] in
                // 2. Perform UI Operations.
                let position = CLLocationCoordinate2DMake(latitude,longitude)
                let marker = GMSMarker(position: position)
                marker.map = mapView
            }
        }
    }
}

