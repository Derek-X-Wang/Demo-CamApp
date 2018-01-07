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
        self.view.backgroundColor = UIColor.gray
        player = AVPlayer(url: videoURL)
        playerController = AVPlayerViewController()
        
        guard player != nil && playerController != nil else {
            return
        }
        playerController!.showsPlaybackControls = false
        
        playerController!.player = player!
        self.addChildViewController(playerController!)
        self.view.addSubview(playerController!.view)
        playerController!.view.frame = view.frame
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.player!.currentItem)
        
        let cancelButton = UIButton(frame: CGRect(x: 10.0, y: 10.0, width: 30.0, height: 30.0))
        cancelButton.setImage(#imageLiteral(resourceName: "icons8-delete-100"), for: UIControlState())
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        view.addSubview(cancelButton)
        
        let deleteButton = UIButton(frame: CGRect(x: view.frame.width - 40, y: 10, width: 30.0, height: 30.0))
        deleteButton.setImage(#imageLiteral(resourceName: "icons8-waste-100"), for: UIControlState())
        deleteButton.addTarget(self, action: #selector(remove), for: .touchUpInside)
        view.addSubview(deleteButton)
        
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        player?.play()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
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
            //.child(thumbnail.fileId)
//            .removeValue { (error, df) in
//                if let err = error {
//                    print(err.localizedDescription)
//                }
//        }
    }
    
    @objc fileprivate func playerItemDidReachEnd(_ notification: Notification) {
        if self.player != nil {
            self.player!.seek(to: kCMTimeZero)
            self.player!.play()
        }
    }

}
