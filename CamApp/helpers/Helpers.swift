//
//  Helpers.swift
//  CamApp
//
//  Created by Xinzhe Wang on 1/19/18.
//  Copyright © 2018 IntBridge. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

func getThumbnail(_ url: URL, timeScale: Double) -> UIImage {
    let asset:AVAsset = AVAsset(url:url)
    let durationSeconds = CMTimeGetSeconds(asset.duration)
    let assetImgGenerate : AVAssetImageGenerator = AVAssetImageGenerator(asset: asset)
    
    assetImgGenerate.appliesPreferredTrackTransform = true
    let time: CMTime = CMTimeMakeWithSeconds(durationSeconds/timeScale, 600)
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
