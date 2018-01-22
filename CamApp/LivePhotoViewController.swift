//
//  LivePhotoViewController.swift
//  CamApp
//
//  Created by Xinzhe Wang on 1/18/18.
//  Copyright © 2018 IntBridge. All rights reserved.
//

import UIKit
import Photos
import PhotosUI
import Firebase

class LivePhotoViewController: UIViewController {

    private var thumbnail: Thumbnail
    private var videoURL: URL
    
    lazy var livePhotoView: PHLivePhotoView = {
        let photoView = PHLivePhotoView(frame: self.view.bounds)
        photoView.livePhoto = nil
        // photoView.contentMode = .scaleAspectFill
        let imageName = "\(thumbnail.timestamp).live.jpg"
        let videoName = "\(thumbnail.timestamp).live.mov"
        let imagePath = DocumentManager.shared.getPath(imageName)
        let videoPath = DocumentManager.shared.getPath(videoName)
        if !DocumentManager.shared.exited(imageName) {
//            do {
//                let photo = getThumbnail(videoURL, timeScale: 2.0)
//                try DocumentManager.shared.save(photo, name: "\(thumbnail.timestamp).mov.jpg")
//            } catch let e {
//                print("Save error \(e.localizedDescription)")
//            }
            let photo = getThumbnail(videoURL, timeScale: 2.0)
            JPEG(image: photo).write(imagePath, assetIdentifier: thumbnail.fileId)
            //DocumentManager.shared.save(photo, name: imageName, metadata: ["com.apple.quicktime.still-image-time": thumbnail.fileId])
        }
        if !DocumentManager.shared.exited(videoName) {
            QuickTimeMov(path: videoURL.path).write(videoPath, assetIdentifier: thumbnail.fileId)
        }
        let imageURL = URL(fileURLWithPath: imagePath)
        let liveVideoURL = URL(fileURLWithPath: videoPath)
        
        PHLivePhoto.request(withResourceFileURLs: [liveVideoURL, imageURL], placeholderImage: UIImage.from(color: .black), targetSize: self.view.bounds.size, contentMode: .aspectFit, resultHandler: { (livePhoto, info) in
            DispatchQueue.main.async {
                self.livePhotoView.livePhoto = livePhoto
            }
        })
        return photoView
    }()
    
    init(_ thumbnail: Thumbnail) {
        self.thumbnail = thumbnail
        self.videoURL = thumbnail.videoURL!
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black
        view.addSubview(livePhotoView)
        view.addConstraintsWithFormat("H:|[v0]|", views: livePhotoView)
        view.addConstraintsWithFormat("V:|[v0]|", views: livePhotoView)
        
        let cancelButton = UIButton(frame: CGRect(x: 10.0, y: 10.0, width: 30.0, height: 30.0))
        cancelButton.setImage(#imageLiteral(resourceName: "icons8-delete-100"), for: UIControlState())
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        livePhotoView.addSubview(cancelButton)
        
        let deleteButton = UIButton(frame: CGRect(x: view.frame.width - 40, y: 10, width: 30.0, height: 30.0))
        deleteButton.setImage(#imageLiteral(resourceName: "icons8-waste-100"), for: UIControlState())
        deleteButton.addTarget(self, action: #selector(remove), for: .touchUpInside)
        livePhotoView.addSubview(deleteButton)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func cancel() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func remove() {
        let user = Auth.auth().currentUser!
        let databaseRef = Database.database().reference()
            .child("users")
            .child(user.uid)
            .child("files")
        databaseRef.observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.hasChild(self.thumbnail.fileId) {
                databaseRef.child(self.thumbnail.fileId).removeValue()
                // delete file in storage
                let storageRef = Storage.storage().reference().child(user.uid).child("files").child(self.thumbnail.name)
                storageRef.delete { error in
                    if let error = error {
                        print(error.localizedDescription)
                    }
                    print("successfully delete storage")
                }
                self.dismiss(animated: true, completion: nil)
            } else {
                let alert = UIAlertController(title: "No delete during uploading", message: "Please delete it after upload process is completed", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "ok", style: .default, handler: nil)
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
            }
        }
    }

}
