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
    case live
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
            liveImageView.isHidden = true
            switch thumbnail!.type {
            case .image:
                thumbnailImageView.image = thumbnail?.image
            case .video:
                playImageView.isHidden = false
                let image = getThumbnail(thumbnail!.videoURL!, timeScale: 3.0)
                thumbnailImageView.image = image
            case .live:
                liveImageView.isHidden = false
                let image = getThumbnail(thumbnail!.videoURL!, timeScale: 2.0)
                thumbnailImageView.image = image
            }
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
    
    let liveImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = #imageLiteral(resourceName: "icons8-sun-100-yellow")
        return imageView
    }()
    
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
        
        addConstraintsWithFormat("H:|[v0]|", views: thumbnailImageView)
        addConstraintsWithFormat("V:|[v0]|", views: thumbnailImageView)
        
        thumbnailImageView.addSubview(playImageView)
        playImageView.centerXAnchor.constraint(equalTo: thumbnailImageView.centerXAnchor).isActive = true
        playImageView.centerYAnchor.constraint(equalTo: thumbnailImageView.centerYAnchor).isActive = true
        playImageView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        playImageView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        thumbnailImageView.addSubview(liveImageView)
        liveImageView.centerXAnchor.constraint(equalTo: thumbnailImageView.centerXAnchor).isActive = true
        liveImageView.centerYAnchor.constraint(equalTo: thumbnailImageView.centerYAnchor).isActive = true
        liveImageView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        liveImageView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
    }
}

