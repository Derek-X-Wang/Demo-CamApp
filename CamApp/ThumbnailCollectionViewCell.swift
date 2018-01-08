//
//  ThumbnailCollectionViewCell.swift
//  CamApp
//
//  Created by Xinzhe Wang on 1/4/18.
//  Copyright © 2018 IntBridge. All rights reserved.
//

import UIKit
import AVFoundation
import BAFluidView
import NVActivityIndicatorView

enum FileType {
    case image
    case video
}

enum ThumbnailViewStatus {
    case imageCompleted
    case videoCompleted
    case uploading
    case downloading
}

class Thumbnail {
    var type: FileType
    var status: ThumbnailViewStatus
    var fileId: String
    var name: String
    var timestamp: String
    var image: UIImage?
    var videoURL: URL?
    
    init(_ upload: FirebaseUpload) {
        type = upload.type
        status = .uploading
        image = upload.image
        videoURL = upload.videoURL
        fileId = upload.fileId
        timestamp = upload.timestamp
        name = type == .image ? "\(timestamp).jpg" : "\(timestamp).mov"
    }
    
    init(_ download: FirebaseFileChange) {
        type = download.type
        status = .downloading
        image = download.image
        videoURL = download.videoURL
        fileId = download.fileId
        timestamp = download.timestamp
        name = download.name
    }
}

class ThumbnailCollectionViewCell: UICollectionViewCell {
    
    var fluidView: BAFluidView?
    var loadingView: NVActivityIndicatorView?
    
    var thumbnail: Thumbnail? {
        didSet {
            playImageView.isHidden = true
            if thumbnail?.type == .image {
                thumbnailImageView.image = thumbnail?.image
            } else {
                playImageView.isHidden = false
                let image = getThumbnail(thumbnail!.videoURL!)
                thumbnailImageView.image = image
            }
//            playImageView.isHidden = true
//            //uploadingLabel.isHidden = true
//            //downloadingView.isHidden = true
//            thumbnailImageView.isHidden = false
//            switch thumbnail!.status {
//            case .uploading:
//                uploadingLabel.isHidden = false
//            case .downloading:
//                thumbnailImageView.isHidden = true
//                //startFluidView()
//                startLoadingView(.downloading)
////                DispatchQueue.main.async {
////                    self.startLoadingView(.downloading)
////                }
//            case .imageCompleted:
//                thumbnailImageView.image = thumbnail?.image
//            case .videoCompleted:
//                playImageView.isHidden = false
//                let image = getThumbnail(thumbnail!.videoURL!)
//                thumbnailImageView.image = image
//            }
        }
    }
    
//    func startLoadingView(_ type: ThumbnailViewStatus) {
//        let indicatorType = type == .downloading ? NVActivityIndicatorType.ballPulse : NVActivityIndicatorType.cubeTransition
//        let text = type == .downloading ? "Download" : "upload"
//        loadingView = NVActivityIndicatorView(frame: self.frame, type: indicatorType, color: UIColor.white, padding: 30)
//
//        let animationTypeLabel = UILabel(frame: self.frame)
//
//        animationTypeLabel.text = text
//        animationTypeLabel.sizeToFit()
//        animationTypeLabel.textColor = UIColor.white
//        animationTypeLabel.frame.origin.x += 5
//        animationTypeLabel.frame.origin.y += CGFloat(self.frame.height) - animationTypeLabel.frame.size.height
//
//        //addSubview(loadingView!)
//        addSubview(animationTypeLabel)
//        //loadingView?.startAnimating()
////        UIView.animate(withDuration: 0.5, animations: {
////            self.loadingView?.alpha=1.0
////            animationTypeLabel.alpha=1.0
////        }, completion: { _ in
//////            self.titleLabels.text = "Downloading"
//////            self.startAnime.enabled = false
//////            self.exampleContainerView.removeFromSuperview()
//////            self.exampleContainerView = myView
////        })
//    }
//
//    func startFluidView() {
//        if let fv = fluidView {
//            fv.startAnimation()
//        } else {
//            fluidView = BAFluidView(frame: self.frame, startElevation: 0.6)!
//            fluidView?.translatesAutoresizingMaskIntoConstraints = false
//            fluidView?.strokeColor = UIColor.white
//            fluidView?.fillColor = UIColor.blue
//            fluidView?.keepStationary()
//            fluidView?.startAnimation()
//        }
//        addSubview(fluidView!)
//        addSubview(downloadingTextView)
//        downloadingTextView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
//        downloadingTextView.bottomAnchor.constraint(equalTo: fluidView!.bottomAnchor).isActive = true
//        downloadingTextView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
//        downloadingTextView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
//    }
    
    func getThumbnail(_ url: URL) -> UIImage {
        let asset:AVAsset = AVAsset(url:url)
        let durationSeconds = CMTimeGetSeconds(asset.duration)
        let assetImgGenerate : AVAssetImageGenerator = AVAssetImageGenerator(asset: asset)
        
        assetImgGenerate.appliesPreferredTrackTransform = true
        let time: CMTime = CMTimeMakeWithSeconds(durationSeconds/3.0, 600)
        var img: CGImage
        do {
            img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
            let frameImg: UIImage = UIImage(cgImage: img)
            return frameImg
        } catch let error as NSError {
            print("ERROR: \(error)")
            return UIImage.from(color: .white)
        }
    }
    
    let thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.image = UIImage.from(color: .white)
        return imageView
    }()
    
    let playImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = #imageLiteral(resourceName: "icons8-play-button-circled-filled-100")
        return imageView
    }()
    
//    let uploadingLabel: UILabel = {
//        let label = UILabel()
//        label.text = "Uploading..."
//        label.textColor = UIColor.white
////        let effect = UIBlurEffect(style: .dark)
////        let effectView = UIVisualEffectView(effect: effect)
//        return label
//    }()
    
//    let uploadingView: UITextView = {
//        let tv = UITextView()
//        tv.text = "Uploading..."
//        tv.font = UIFont.systemFont(ofSize: 14)
//        tv.translatesAutoresizingMaskIntoConstraints = false
//        tv.backgroundColor = UIColor.clear
//        tv.textColor = .white
//        tv.isEditable = false
//        return tv
//    }()
//
//    let downloadingTextView: UITextView = {
//        let tv = UITextView()
//        tv.text = "Download"
//        tv.font = UIFont.systemFont(ofSize: 14)
//        tv.translatesAutoresizingMaskIntoConstraints = false
//        tv.backgroundColor = UIColor.clear
//        tv.textColor = .white
//        tv.isEditable = false
//        return tv
//    }()
    
//    lazy var fluidView: BAFluidView = {
//        let fv = BAFluidView(frame: self.frame, startElevation: 0.6)!
//        fv.translatesAutoresizingMaskIntoConstraints = false
//        fv.strokeColor = UIColor.white
//        fv.fillColor = UIColor.blue
//        fv.keepStationary()
//        return fv
//    }()
    
//    lazy var downloadingView: LoadingView = {
//        let loadingview = LoadingView(frame: self.frame)
//        loadingview.translatesAutoresizingMaskIntoConstraints = false
//        return loadingview
//    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.black
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        addSubview(thumbnailImageView)
//        addSubview(playImageView)
//        addSubview(uploadingLabel)
        //addSubview(downloadingView)
        
        addConstraintsWithFormat("H:|[v0]|", views: thumbnailImageView)
        addConstraintsWithFormat("V:|[v0]|", views: thumbnailImageView)
        
        thumbnailImageView.addSubview(playImageView)
        playImageView.centerXAnchor.constraint(equalTo: thumbnailImageView.centerXAnchor).isActive = true
        playImageView.centerYAnchor.constraint(equalTo: thumbnailImageView.centerYAnchor).isActive = true
        playImageView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        playImageView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
//        thumbnailImageView.addSubview(uploadingView)
//        uploadingView.leftAnchor.constraint(equalTo: thumbnailImageView.leftAnchor).isActive = true
//        uploadingView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
//        uploadingView.rightAnchor.constraint(equalTo: thumbnailImageView.rightAnchor).isActive = true
//        uploadingView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        
        //addSubview(fluidView)
//        addSubview(downloadingTextView)
//        downloadingTextView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
//        downloadingTextView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
//        downloadingTextView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
//        downloadingView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
//        downloadingView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
//        downloadingView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
//        downloadingView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
//        addConstraintsWithFormat("H:|[v0]|", views: downloadingView)
//        addConstraintsWithFormat("V:|[v0]|", views: downloadingView)
    }
}

class LoadingView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
//        fluidView = BAFluidView(frame: self.frame, startElevation: 0.5)
//        fluidView.strokeColor = UIColor.white
//        fluidView.fillColor = UIColor.black
//        fluidView.keepStationary()
//        fluidView.startAnimation()
//
//        addSubview(fluidView)
        
//        UIView.animate(withDuration: 0.5, animations: {
//            self.fluidView?.alpha=1.0
//        }, completion: { _ in
////            self.titleLabels.text = "Downloading"
////            self.startAnime.enabled = false
////            self.exampleContainerView.removeFromSuperview()
////            self.exampleContainerView = myView
//        })
        backgroundColor = UIColor.green
        
        setupViews()
    }
    
    lazy var fluidView: BAFluidView = {
        let fv = BAFluidView(frame: self.frame, startElevation: 0.5)!
        fv.strokeColor = UIColor.white
        fv.fillColor = UIColor.black
        fv.keepStationary()
        return fv
    }()
    
    let backgroundImage: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.image = #imageLiteral(resourceName: "background")
        return imageView
    }()
    
    func setupViews() {
        //addSubview(backgroundImage)
        //addSubview(fluidView)
        
//        addConstraintsWithFormat("H:|[v0]|", views: backgroundImage)
//        addConstraintsWithFormat("V:|[v0]|", views: backgroundImage)
//        addConstraintsWithFormat("H:|[v0]|", views: fluidView)
//        addConstraintsWithFormat("V:|[v0]|", views: fluidView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init coder has not been implemented")
    }
}
