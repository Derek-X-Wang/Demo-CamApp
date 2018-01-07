//
//  FirebaseFileChangeStream.swift
//  CamApp
//
//  Created by Xinzhe Wang on 1/5/18.
//  Copyright © 2018 IntBridge. All rights reserved.
//

import Foundation
import RxSwift
import Firebase

class FirebaseFileChange {
    var type: FileType
    var name: String
    var path: String
    var uploadDevice: String
    var timestamp: String
    var fileId: String
    var image: UIImage?
    var videoURL: URL?
    
    init(_ entry: [String : AnyObject], key: String) {
        fileId = key
        let entryType = entry["type"] as! String
        type = entryType == "image" ? .image : .video
        name = entry["name"] as! String
        path = entry["path"] as! String
        uploadDevice = entry["uploadDevice"] as! String
        timestamp = entry["timestamp"] as! String
    }
}

enum FirebaseFileChangeStreamType {
    case fileAddedStream
    case fileRemovedStream
    case fileDownloadedStream
    case needRemoveStream
    case localFileStream
}

class FirebaseFileChangeStream {
    static let fileChangeStream = PublishSubject<FirebaseFileChange>()
    static let fileAddedStream = PublishSubject<FirebaseFileChange>()
    static let fileRemovedStream = PublishSubject<FirebaseFileChange>()
    static let localFileStream = fileAddedStream.filter { (file) -> Bool in
        if DocumentManager.shared.exited(file.name) {
            return true
        }
        return false
    }
    //static let loadedLocalStream = localFileStream.
    static let needDownloadStream = fileAddedStream.filter { (file) -> Bool in
        // if the current device is the uploader
        if file.uploadDevice == UIDevice.current.identifierForVendor!.uuidString {
            return false
        }
        // if file exited in local storage
        if DocumentManager.shared.exited(file.name) {
            return false
        }
        return true
    }
    static let needRemoveStream = fileRemovedStream.filter { (file) -> Bool in
        if DocumentManager.shared.exited(file.name) {
            return true
        }
        return false
    }
    static let fileDownloadedStream = needDownloadStream.flatMap { (file) -> Observable<FirebaseFileChange> in
        return downloadFileFromFirebaseStorage(file)
    }
    
    
    static func send(_ object: FirebaseFileChange) {
        fileChangeStream.onNext(object)
    }
    
    static func send(_ object: FirebaseFileChange, type: FirebaseFileChangeStreamType) {
        switch type {
        case .fileAddedStream:
            fileAddedStream.onNext(object)
        case .fileRemovedStream:
            fileRemovedStream.onNext(object)
        default:
            break
        }
    }
    
    static func asObservable() -> Observable<FirebaseFileChange> {
        return fileChangeStream
    }
    
    static func asObservable(_ type: FirebaseFileChangeStreamType) -> Observable<FirebaseFileChange> {
        switch type {
        case .fileAddedStream:
            return fileAddedStream
        case .fileRemovedStream:
            return fileRemovedStream
        case .fileDownloadedStream:
            return fileDownloadedStream
        case .needRemoveStream:
            return needRemoveStream
        case .localFileStream:
            return localFileStream
        }
    }
    
    static func downloadFileFromFirebaseStorage(_ file: FirebaseFileChange) -> Observable<FirebaseFileChange> {
        return Observable.create({ (observer) -> Disposable in
            let storageRef = Storage.storage().reference(withPath: file.path)
            let path = DocumentManager.shared.getPath(file.name)
            let toURL = URL(fileURLWithPath: path)
            let downloadTask = storageRef.write(toFile: toURL) { url, error in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    observer.onError(error)
                }
                // normal
                if file.type == .image {
                    // load image to memory
                    do {
                        let imageData = try Data(contentsOf: url!)
                        file.image = UIImage(data: imageData)
                    } catch {
                        print("Error loading image : \(error)")
                        file.image = UIImage.from(color: .white)
                    }
                } else {
                    file.videoURL = url
                }
                observer.onNext(file)
                observer.onCompleted()
            }
            return Disposables.create()
        })
    }
}
