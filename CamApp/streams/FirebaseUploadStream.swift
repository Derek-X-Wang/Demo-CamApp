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
    
    init(_ url: URL) {
        type = .video
        timestamp = String(Date().timeIntervalSince1970)
        image = nil
        videoURL = url
        fileId = UUID().uuidString
    }
}

enum FirebaseUploadStreamType {
    case newUploadStream
    case uploadCompletedStream
}

class FirebaseUploadStream {
    static let newUploadStream = PublishSubject<FirebaseUpload>()
    static let uploadCompletedStream = newUploadStream
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
        }
    }
    
    static func uploadFileToFirebaseStream(_ file: FirebaseUpload) -> Observable<FirebaseUpload> {
        // I should check if currentUser exists or not
        // This demo hardcode user login, so I can assuem it is safe to access currentUser
        let user = Auth.auth().currentUser!
        file.uid = user.uid
        if (file.type == .image) {
            return uploadImageToFirebaseStorage(file)
        } else {
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
            let uploadTask = storageRef.putFile(from: file.videoURL!, metadata: uploadMetaData) { (metadata, error) in
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
}
