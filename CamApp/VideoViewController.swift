//
//  VideoViewController.swift
//  CamApp
//
//  Created by Xinzhe Wang on 1/6/18.
//  Copyright © 2018 IntBridge. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import Firebase

class VideoViewController: UIViewController {
    
    private var thumbnail: Thumbnail
    private var videoURL: URL
    var player: AVPlayer?
    var playerController : AVPlayerViewController?
    var deleteButton: UIButton?
    var createButton: UIButton?
    
    var converter: MetalVideoConverter
    
    init(_ thumbnail: Thumbnail) {
        self.thumbnail = thumbnail
        self.videoURL = thumbnail.videoURL!
        converter = MetalVideoConverter(videoURL)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.gray
        player = AVPlayer(url: videoURL)
        playerController = AVPlayerViewController()
        
        guard player != nil && playerController != nil else {
            return
        }
        playerController!.showsPlaybackControls = true
        
        playerController!.player = player!
        self.addChildViewController(playerController!)
        self.view.addSubview(playerController!.view)
        playerController!.view.frame = view.frame
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.player!.currentItem)
        
        deleteButton = UIButton(frame: CGRect(x: view.frame.width - 50, y: 65, width: 30.0, height: 30.0))
        deleteButton?.setImage(#imageLiteral(resourceName: "icons8-waste-100"), for: UIControlState())
        deleteButton?.addTarget(self, action: #selector(remove), for: .touchUpInside)
        view.addSubview(deleteButton!)
        
        createButton = UIButton(frame: CGRect(x: view.frame.width - 50, y: 105, width: 30.0, height: 30.0))
        createButton?.setImage(#imageLiteral(resourceName: "icons8-picture-100"), for: UIControlState())
        createButton?.addTarget(self, action: #selector(createImages), for: .touchUpInside)
        view.addSubview(createButton!)
        
        // Allow background audio to continue to play
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
        } catch let error as NSError {
            print(error)
        }
        
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error as NSError {
            print(error)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(getImages), name: NSNotification.Name(rawValue: "IMAGE_COMPLETED"), object: nil)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @objc func cancel() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func getImages() {
        print("getImages output")
//        let (first, second) = converter.export()
//        let image1 = UIImage(cgImage: first)
//        let image2 = UIImage(cgImage: second)
//        UIImageWriteToSavedPhotosAlbum(image1, nil, nil, nil)
//        UIImageWriteToSavedPhotosAlbum(image2, nil, nil, nil)
        let image = converter.exportSecondImage()
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        let alert = UIAlertController(title: "Image is ready", message: "Please go to Photo library to check the result", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "ok", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func createImages() {
        DispatchQueue.global().async {
            let frames = self.converter.retrieveFramesFromVideo()
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Ready to create", message: "Click ok to start the process", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "ok", style: .default, handler: { (action) in
                    DispatchQueue.global().async {
                        self.converter.convert(frames)
                    }
                })
                    //UIAlertAction(title: "ok", style: .default, handler: nil)
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
            }
            
        }
        
//        let (first, second) = converter.convertToImages()
//        let image1 = UIImage(cgImage: first)
//        let image2 = UIImage(cgImage: second)
//        UIImageWriteToSavedPhotosAlbum(image1, nil, nil, nil)
//        UIImageWriteToSavedPhotosAlbum(image2, nil, nil, nil)
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
    
    @objc fileprivate func playerItemDidReachEnd(_ notification: Notification) {
        if self.player != nil {
            self.player!.seek(to: kCMTimeZero)
            self.player!.play()
        }
    }

}
