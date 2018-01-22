//
//  FirebaseUploadStream.swift
//  CamApp
//
//  Created by Xinzhe Wang on 1/5/18.
//  Copyright © 2018 IntBridge. All rights reserved.
//

import Foundation
import RxSwift
import Firebase
import AVFoundation

class FirebaseUpload {
    var type: FileType
    var timestamp: String
    var fileId: String
    var image: UIImage?
    var videoURL: URL?
    var uid: String?
    var metadata: StorageMetadata?
    
    init(_ img: UIImage) {
        type = .image
        timestamp = String(Date().timeIntervalSince1970)
        image = img
        videoURL = nil
        fileId = UUID().uuidString
    }
    
    init(_ url: URL, type: FileType) {
        self.type = type
        timestamp = String(Date().timeIntervalSince1970)
        image = nil
        videoURL = url
        fileId = UUID().uuidString
    }
}

enum FirebaseUploadStreamType {
    case newUploadStream
    case preparedUploadStream
    case uploadCompletedStream
}

class FirebaseUploadStream {
    
    fileprivate let kKeyContentIdentifier =  "com.apple.quicktime.content.identifier"
    fileprivate let kKeyStillImageTime = "com.apple.quicktime.still-image-time"
    fileprivate let kKeySpaceQuickTimeMetadata = "mdta"
    
    static let newUploadStream = PublishSubject<FirebaseUpload>()
    // static let sharedUploadStream = newUploadStream.share()
    static let newImageStream = newUploadStream.filter { (file) -> Bool in
        if file.type == .image {
            return true
        }
        return false
    }
    static let newVideoStream = newUploadStream.filter { (file) -> Bool in
        if file.type != .image {
            return true
        }
        return false
    }
    static let processedImageStream = newImageStream.map { (file) -> FirebaseUpload in
        let image = file.image!
        print("1: \(file.image!.size)")
        // Normal iPhone = 750 x 1334
        // Plus = 1242 x 2208
//        let maxSize: CGFloat = UIDevice.current.isPlusModel ? 2208.0 : 1334.0
//        let resizedImage = scale(image: image, toLessThan: maxSize)!
        let resizedImage = resize(image: image, isPlus: UIDevice.current.isPlusModel)!
        let data = UIImageJPEGRepresentation(resizedImage, 0.9)!
        let nsData = data as NSData
        print("\(scale) compression size is \(nsData.length) byte")
//        print("=====Levels of JPEG Compression=====")
//        saveAndPrint(image, scale: 1.0, save: true)
//        saveAndPrint(image, scale: 0.9, save: true)
//        saveAndPrint(image, scale: 0.8, save: false)
//        saveAndPrint(image, scale: 0.7, save: false)
//        saveAndPrint(image, scale: 0.6, save: false)
//        saveAndPrint(image, scale: 0.5, save: true)
//        saveAndPrint(image, scale: 0.4, save: true)
//        saveAndPrint(image, scale: 0.3, save: true)
        file.image = UIImage(data: data)
        print("2: \(file.image!.size)")
        return file
    }
    static let processedVideoStream = newVideoStream.flatMap { (file) -> Observable<FirebaseUpload> in
        return Observable.create({ (observer) -> Disposable in
            let data = NSData(contentsOf: file.videoURL!)!
            print("File size before compression: \(Double(data.length) / Double(1048576)) mb")
            let compressedURL = NSURL.fileURL(withPath: NSTemporaryDirectory() + file.fileId + "-compressed.mov")
            compressVideo(inputURL: file.videoURL!, outputURL: compressedURL, metadata: [metadataFor(file.fileId)]) { (exportSession) in
                guard let session = exportSession else { return }
                switch session.status {
                case .unknown:
                    break
                case .waiting:
                    break
                case .exporting:
                    break
                case .completed:
                    guard let compressedData = NSData(contentsOf: compressedURL) else { return }
                    print("File size after compression: \(Double(compressedData.length) / Double(1048576)) mb")
                    file.videoURL = compressedURL
                    observer.onNext(file)
                    observer.onCompleted()
                case .failed:
                    break
                case .cancelled:
                    break
                }
            }
            return Disposables.create()
        })
    }
    static let preparedUploadStream = Observable.of(processedImageStream, processedVideoStream).merge().share()
    static let uploadCompletedStream = preparedUploadStream
        .flatMap { (file) -> Observable<FirebaseUpload> in
            return uploadFileToFirebaseStream(file)
        }
    
    static func send(_ object: FirebaseUpload) {
        newUploadStream.onNext(object)
    }
    
    static func asObservable() -> Observable<FirebaseUpload> {
        return newUploadStream
    }
    
    static func asObservable(_ type: FirebaseUploadStreamType) -> Observable<FirebaseUpload> {
        switch type {
        case .newUploadStream:
            return newUploadStream
        case .uploadCompletedStream:
            return uploadCompletedStream
        case .preparedUploadStream:
            return preparedUploadStream
        }
    }
    
    static func uploadFileToFirebaseStream(_ file: FirebaseUpload) -> Observable<FirebaseUpload> {
        // I should check if currentUser exists or not
        // This demo hardcode user login, so I can assuem it is safe to access currentUser
        let user = Auth.auth().currentUser!
        file.uid = user.uid
        switch file.type {
        case .image:
            return uploadImageToFirebaseStorage(file)
        case .video:
            return uploadVideoToFirebaseStorage(file)
        case .live:
            return uploadVideoToFirebaseStorage(file)
        }
    }
    
    static func uploadImageToFirebaseStorage(_ file: FirebaseUpload) -> Observable<FirebaseUpload> {
        return Observable.create({ (observer) -> Disposable in
            let imageData = UIImageJPEGRepresentation(file.image!, 0.9)
            let storageRef = Storage.storage().reference().child(file.uid!).child("files").child("\(file.timestamp).jpg")
            let uploadMetaData = StorageMetadata()
            uploadMetaData.contentType = "image/jpeg"
            let uploadTask = storageRef.putData(imageData!, metadata: uploadMetaData) { (metadata, error) in
                if (error != nil) {
                    print("Error: \(error?.localizedDescription)")
                    observer.onError(error!)
                }
                // normal
                file.metadata = metadata
                observer.onNext(file)
                observer.onCompleted()
            }
            return Disposables.create()
        })
    }
    
    static func uploadVideoToFirebaseStorage(_ file: FirebaseUpload) -> Observable<FirebaseUpload> {
        return Observable.create({ (observer) -> Disposable in
            let storageRef = Storage.storage().reference().child(file.uid!).child("files").child("\(file.timestamp).mov")
            let uploadMetaData = StorageMetadata()
            uploadMetaData.contentType = "video/quicktime"
            print("uploadVideoToFirebaseStorage1")
            let uploadTask = storageRef.putFile(from: file.videoURL!, metadata: uploadMetaData) { (metadata, error) in
                if (error != nil) {
                    print("Error: \(error?.localizedDescription)")
                    observer.onError(error!)
                }
                // normal
                print("uploadVideoToFirebaseStorage2")
                file.metadata = metadata
                observer.onNext(file)
                observer.onCompleted()
            }
            print("uploadVideoToFirebaseStorage3")
            return Disposables.create()
        })
    }
    
    private static func saveAndPrint(_ image: UIImage, scale: CGFloat, save: Bool) {
        let data = UIImageJPEGRepresentation(image, scale)!
        let newData = data as NSData
        print("\(scale) compression size is \(newData.length) byte")
        if save {
            UIImageWriteToSavedPhotosAlbum(UIImage(data: data)!, nil, nil, nil)
        }
    }
    
    private static func scale(image originalImage: UIImage, toLessThan maxResolution: CGFloat) -> UIImage? {
        guard let imageReference = originalImage.cgImage else { return nil }
        
        let rotate90 = CGFloat.pi/2.0 // Radians
        let rotate180 = CGFloat.pi // Radians
        let rotate270 = 3.0*CGFloat.pi/2.0 // Radians
        
        let originalWidth = CGFloat(imageReference.width)
        let originalHeight = CGFloat(imageReference.height)
        let originalOrientation = originalImage.imageOrientation
        
        var newWidth = originalWidth
        var newHeight = originalHeight
        
        if originalWidth > maxResolution || originalHeight > maxResolution {
            let aspectRatio: CGFloat = originalWidth / originalHeight
            newWidth = aspectRatio > 1 ? maxResolution : maxResolution * aspectRatio
            newHeight = aspectRatio > 1 ? maxResolution / aspectRatio : maxResolution
        }
        
        let scaleRatio: CGFloat = newWidth / originalWidth
        var scale: CGAffineTransform = .init(scaleX: scaleRatio, y: -scaleRatio)
        scale = scale.translatedBy(x: 0.0, y: -originalHeight)
        
        var rotateAndMirror: CGAffineTransform
        
        switch originalOrientation {
        case .up:
            rotateAndMirror = .identity
            
        case .upMirrored:
            rotateAndMirror = .init(translationX: originalWidth, y: 0.0)
            rotateAndMirror = rotateAndMirror.scaledBy(x: -1.0, y: 1.0)
            
        case .down:
            rotateAndMirror = .init(translationX: originalWidth, y: originalHeight)
            rotateAndMirror = rotateAndMirror.rotated(by: rotate180 )
            
        case .downMirrored:
            rotateAndMirror = .init(translationX: 0.0, y: originalHeight)
            rotateAndMirror = rotateAndMirror.scaledBy(x: 1.0, y: -1.0)
            
        case .left:
            (newWidth, newHeight) = (newHeight, newWidth)
            rotateAndMirror = .init(translationX: 0.0, y: originalWidth)
            rotateAndMirror = rotateAndMirror.rotated(by: rotate270)
            scale = .init(scaleX: -scaleRatio, y: scaleRatio)
            scale = scale.translatedBy(x: -originalHeight, y: 0.0)
            
        case .leftMirrored:
            (newWidth, newHeight) = (newHeight, newWidth)
            rotateAndMirror = .init(translationX: originalHeight, y: originalWidth)
            rotateAndMirror = rotateAndMirror.scaledBy(x: -1.0, y: 1.0)
            rotateAndMirror = rotateAndMirror.rotated(by: rotate270)
            
        case .right:
            (newWidth, newHeight) = (newHeight, newWidth)
            rotateAndMirror = .init(translationX: originalHeight, y: 0.0)
            rotateAndMirror = rotateAndMirror.rotated(by: rotate90)
            scale = .init(scaleX: -scaleRatio, y: scaleRatio)
            scale = scale.translatedBy(x: -originalHeight, y: 0.0)
            
        case .rightMirrored:
            (newWidth, newHeight) = (newHeight, newWidth)
            rotateAndMirror = .init(scaleX: -1.0, y: 1.0)
            rotateAndMirror = rotateAndMirror.rotated(by: CGFloat.pi/2.0)
        }
        
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.concatenate(scale)
        context.concatenate(rotateAndMirror)
        context.draw(imageReference, in: CGRect(x: 0, y: 0, width: originalWidth, height: originalHeight))
        let copy = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return copy
    }
    
    private static func resize(image originalImage: UIImage, isPlus: Bool) -> UIImage? {
        guard let imageReference = originalImage.cgImage else { return nil }
        
        let rotate90 = CGFloat.pi/2.0 // Radians
        let rotate180 = CGFloat.pi // Radians
        let rotate270 = 3.0*CGFloat.pi/2.0 // Radians
        
        let originalWidth = CGFloat(imageReference.width)
        let originalHeight = CGFloat(imageReference.height)
        let originalOrientation = originalImage.imageOrientation
        
        // Normal iPhone = 750 x 1334
        // Plus = 1242 x 2208
        // TODO: current result is right, but the label name is wrong
        var newWidth: CGFloat = isPlus ? 2208.0 : 1334.0
        var newHeight: CGFloat = isPlus ? 1242.0 : 750.0
        
//        if originalWidth > maxResolution || originalHeight > maxResolution {
//            let aspectRatio: CGFloat = originalWidth / originalHeight
//            newWidth = aspectRatio > 1 ? maxResolution : maxResolution * aspectRatio
//            newHeight = aspectRatio > 1 ? maxResolution / aspectRatio : maxResolution
//        }
        
        let scaleRatio: CGFloat = newWidth / originalWidth
        var scale: CGAffineTransform = .init(scaleX: scaleRatio, y: -scaleRatio)
        scale = scale.translatedBy(x: 0.0, y: -originalHeight)
        
        var rotateAndMirror: CGAffineTransform
        
        switch originalOrientation {
        case .up:
            rotateAndMirror = .identity
            
        case .upMirrored:
            rotateAndMirror = .init(translationX: originalWidth, y: 0.0)
            rotateAndMirror = rotateAndMirror.scaledBy(x: -1.0, y: 1.0)
            
        case .down:
            rotateAndMirror = .init(translationX: originalWidth, y: originalHeight)
            rotateAndMirror = rotateAndMirror.rotated(by: rotate180 )
            
        case .downMirrored:
            rotateAndMirror = .init(translationX: 0.0, y: originalHeight)
            rotateAndMirror = rotateAndMirror.scaledBy(x: 1.0, y: -1.0)
            
        case .left:
            (newWidth, newHeight) = (newHeight, newWidth)
            rotateAndMirror = .init(translationX: 0.0, y: originalWidth)
            rotateAndMirror = rotateAndMirror.rotated(by: rotate270)
            scale = .init(scaleX: -scaleRatio, y: scaleRatio)
            scale = scale.translatedBy(x: -originalHeight, y: 0.0)
            
        case .leftMirrored:
            (newWidth, newHeight) = (newHeight, newWidth)
            rotateAndMirror = .init(translationX: originalHeight, y: originalWidth)
            rotateAndMirror = rotateAndMirror.scaledBy(x: -1.0, y: 1.0)
            rotateAndMirror = rotateAndMirror.rotated(by: rotate270)
            
        case .right:
            (newWidth, newHeight) = (newHeight, newWidth)
            rotateAndMirror = .init(translationX: originalHeight, y: 0.0)
            rotateAndMirror = rotateAndMirror.rotated(by: rotate90)
            scale = .init(scaleX: -scaleRatio, y: scaleRatio)
            scale = scale.translatedBy(x: -originalHeight, y: 0.0)
            
        case .rightMirrored:
            (newWidth, newHeight) = (newHeight, newWidth)
            rotateAndMirror = .init(scaleX: -1.0, y: 1.0)
            rotateAndMirror = rotateAndMirror.rotated(by: CGFloat.pi/2.0)
        }
        
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.concatenate(scale)
        context.concatenate(rotateAndMirror)
        context.draw(imageReference, in: CGRect(x: 0, y: 0, width: originalWidth, height: originalHeight))
        let copy = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return copy
    }
    
    private static func compressVideo(inputURL: URL, outputURL: URL, metadata: [AVMetadataItem], handler: @escaping (_ exportSession: AVAssetExportSession?)-> Void) {
        let urlAsset = AVURLAsset(url: inputURL, options: nil)
        guard let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPreset1280x720) else {
            handler(nil)
            return
        }
        exportSession.outputURL = outputURL
        exportSession.outputFileType = AVFileType.mov
        exportSession.metadata = metadata
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.exportAsynchronously { () -> Void in
            handler(exportSession)
        }
    }
    
    private static func metadataFor(_ assetIdentifier: String) -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.key = "com.apple.quicktime.content.identifier" as (NSCopying & NSObjectProtocol)?
        item.keySpace = AVMetadataKeySpace.quickTimeMetadata
        item.value = assetIdentifier as (NSCopying & NSObjectProtocol)?
        item.dataType = "com.apple.metadata.datatype.UTF-8"
        return item
    }
}
