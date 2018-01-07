//
//  ThumbnailCollectionViewCell.swift
//  CamApp
//
//  Created by Xinzhe Wang on 1/4/18.
//  Copyright © 2018 IntBridge. All rights reserved.
//

import UIKit
import AVFoundation

enum FileType {
    case image
    case video
}

enum ThumbnailViewType {
    case image
    case video
    case uploading
    case downloading
}

class Thumbnail {
    var type: FileType
    var fileId: String
    var name: String
    var timestamp: String
    var image: UIImage?
    var videoURL: URL?
    
    init(_ upload: FirebaseUpload) {
        type = upload.type
        image = upload.image
        videoURL = upload.videoURL
        fileId = upload.fileId
        timestamp = upload.timestamp
        name = type == .image ? "\(timestamp).jpg" : "\(timestamp).mov"
    }
    
    init(_ download: FirebaseFileChange) {
        type = download.type
        image = download.image
        videoURL = download.videoURL
        fileId = download.fileId
        timestamp = download.timestamp
        name = download.name
    }
}

class ThumbnailCollectionViewCell: UICollectionViewCell {
    
    var thumbnail: Thumbnail? {
        didSet {
            if thumbnail?.type == .image {
                thumbnailImageView.image = thumbnail?.image
            } else {
                let image = getThumbnail(thumbnail!.videoURL!)
                thumbnailImageView.image = image
            }
        }
    }
    
    func getThumbnail(_ url: URL) -> UIImage {
        let asset:AVAsset = AVAsset(url:url)
        let durationSeconds = CMTimeGetSeconds(asset.duration)
        let assetImgGenerate : AVAssetImageGenerator = AVAssetImageGenerator(asset: asset)
        
        assetImgGenerate.appliesPreferredTrackTransform = true
        
        // Jump to the third (1/3) of the video and fetch the thumbnail from there (600 is the timescale and is a multiplier of 24fps, 25fps, 30fps..)
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
        imageView.contentMode = .scaleAspectFill
        imageView.image = UIImage.from(color: .white)
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        addSubview(thumbnailImageView)
        addConstraintsWithFormat("H:|[v0]|", views: thumbnailImageView)
        addConstraintsWithFormat("V:|[v0]|", views: thumbnailImageView)
        
    }
}
