//
//  MetalVideoConverter.swift
//  CamApp
//
//  Created by Xinzhe Wang on 1/9/18.
//  Copyright © 2018 IntBridge. All rights reserved.
//

import Foundation
import AVFoundation
import CoreMedia
import MetalKit
import UIKit

class MetalVideoConverter {
    
    var videoURL: URL
    var videoAsset: AVAsset
    var pipeline: MetalPipeline
    
    var frames: [CGImage]?
    var tempTime: CFTimeInterval?
    
    init(_ url: URL) {
        videoURL = url
        videoAsset = AVAsset(url: videoURL)
        pipeline = MetalPipeline()
    }
    
    func convertToImages() -> (CGImage, CGImage) {
        print("convertToImages")
        let t0 = CACurrentMediaTime()
        
        frames = retrieveFramesFromVideo()
        
        let t1 = CACurrentMediaTime()
        print("got frames \(t1-t0)")
        
        pipeline.importTextures(frames!)
        let t2 = CACurrentMediaTime()
        print("textures imported \(t2-t1)")
        
        pipeline.process()
        let t3 = CACurrentMediaTime()
        print("textures processed \(t3-t2)")
        
        let intermediateFrames = pipeline.exportImages()
        let t4 = CACurrentMediaTime()
        print("textures exported \(t4-t3)")
        
        return (intermediateFrames[0], intermediateFrames[1])
    }
    
    func convert(_ videoFrames: [CGImage]) {
        print("convertToImages")
        frames = videoFrames
        pipeline.importTextures(videoFrames)
        let t2 = CACurrentMediaTime()
        tempTime = CACurrentMediaTime()
        
        pipeline.process()
    }
    
    func export() -> (CGImage, CGImage) {
        let intermediateFrames = pipeline.exportImages()
        return (intermediateFrames[0], intermediateFrames[1])
    }
    
    func convertToImagesAsync(_ completion: (CGImage, CGImage) -> Void) {
        
    }
    
    // get info about the video
    func getDetail() {
        let duration = videoAsset.duration
        let durationTime = CMTimeGetSeconds(duration)
    }
    
    // read video from url frame by frame
    func retrieveFramesFromVideo(_ fps: Double=30.0) -> [CGImage] {
        var res = [CGImage]()
        
        let vidLength = videoAsset.duration
        let seconds = CMTimeGetSeconds(vidLength)
        let requiredFramesCount = seconds * fps
        let step = vidLength.value / Int64(requiredFramesCount)
        
        print("frameCount is \(requiredFramesCount)")
        do {
            var i: Double = 0
            var value: Int64 = 0;
            while i < requiredFramesCount {
                let generator = AVAssetImageGenerator(asset: videoAsset)
                generator.requestedTimeToleranceAfter = kCMTimeZero
                generator.requestedTimeToleranceBefore = kCMTimeZero
                generator.appliesPreferredTrackTransform = true
                generator.apertureMode = AVAssetImageGeneratorApertureMode.encodedPixels
                
                let time = CMTime(value: value, timescale: vidLength.timescale)
                
                let image = try generator.copyCGImage(at: time, actualTime: nil)
                res.append(image)
                i += 1
                value += step
            }
        } catch let error {
            print("Error: \(error)")
        }
        return res
    }
    
    // merge image
    // output
    func exportSecondImage() -> UIImage {
        let intermediateFrames = pipeline.exportImages()
        let frameWidth = intermediateFrames.first!.width
        let frameHeight = intermediateFrames.first!.height
        let width = frameWidth * 10
        let totalFrames = frames!.count + intermediateFrames.count + 1
        let row = Double(totalFrames) / 10.0
        let height = frameHeight * Int(row.rounded(.up))
        let size = CGSize(width: width, height: height)
        UIGraphicsBeginImageContext(size)
        
        for i in 0..<totalFrames {
            let indexX = (i % 10) * frameWidth
            let indexY = (i / 10) * frameHeight
            let areaSize = CGRect(x: indexX, y: indexY, width: frameWidth, height: frameHeight)
            if i == totalFrames - 1 {
                // last one
                UIImage(cgImage: frames!.last!).draw(in: areaSize)
            } else if i % 2 == 0 {
                // even number, old frame
                let index = i/2
                // print("old \(index)")
                UIImage(cgImage: frames![index]).draw(in: areaSize)
            } else {
                // odd, new frame
                let index = i/2
                // print("new \(index)")
                UIImage(cgImage: intermediateFrames[index]).draw(in: areaSize)
            }
        }
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
}
