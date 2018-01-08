//
//  ViewController.swift
//  CamApp
//
//  Created by Xinzhe Wang on 1/4/18.
//  Copyright © 2018 IntBridge. All rights reserved.
//

import UIKit
import RxSwift
import Firebase
import AVFoundation
import AVKit

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var thumbnailsView: UICollectionView!
    @IBOutlet weak var thumbnailsViewHeight: NSLayoutConstraint!
    
    var thumbnails = [Thumbnail]()
    let dispose = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        // thumbnailsView.backgroundColor = UIColor.black
        thumbnailsView.register(ThumbnailCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: ThumbnailCollectionViewCell.self))
        NotificationCenter.default.addObserver(self, selector: #selector(toggleThumbnailsView), name: NSNotification.Name(rawValue: "TOGGLE_THUMBNAILSVIEW"), object: nil)
        
        thumbnailsViewHeight.constant = view.frame.height / 4.5
        
        Auth.auth().signIn(withEmail: "demo@gmail.com", password: "88888888") { (user, error) in
            if (error != nil) {
                print("Error: \(error?.localizedDescription)")
            }
            print("successfully login")
            self.setupData(user!)
        }
        setupCollectionLayout()
        setupSubscription()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
//    override var preferredStatusBarStyle: UIStatusBarStyle {
//        return .lightContent
//    }
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @objc func toggleThumbnailsView(notification: Notification) {
        if thumbnailsViewHeight.constant == 0 {
            thumbnailsViewHeight.constant = view.frame.height / 4.5
        } else {
            thumbnailsViewHeight.constant = 0
        }
        thumbnailsView.reloadData()
    }
    
    fileprivate func setupData(_ user: User) {
        let databaseRef = Database.database().reference()
            .child("users")
            .child(user.uid)
            .child("files")
        // observeFileChange
        databaseRef.observe(.childAdded) { (snapshot) in
            let value = snapshot.value as! [String : AnyObject]
            let key = snapshot.key
            print("observe")
            print(value)
            FirebaseFileChangeStream.send(FirebaseFileChange(value, key: key), type: .fileAddedStream)
        }
        databaseRef.observe(.childRemoved) { (snapshot) in
            let value = snapshot.value as! [String : AnyObject]
            let key = snapshot.key
            print("observe remove")
            print(value)
            FirebaseFileChangeStream.send(FirebaseFileChange(value, key: key), type: .fileRemovedStream)
        }
    }
    
    fileprivate func setupSubscription() {
        // update thumbnailsView after taking a photo or video
        FirebaseUploadStream
            .asObservable(.newUploadStream)
            .observeOn(MainScheduler.instance)
            .subscribe { (event) in
                switch event {
                case .error(let err):
                    print(err)
                case .next(let upload):
                    do {
                        try DocumentManager.shared.save(upload)
                        let thumb = Thumbnail(upload)
                        self.insertThumbnails(thumb)
                        self.thumbnailsView.reloadData()
                    } catch let e {
                        print("Save error \(e.localizedDescription)")
                    }
                case .completed:
                    print("FirebaseUpload Stream Completed")
                }
            }.disposed(by: dispose)
        
        // Add file to database after upload completed, for sync
        FirebaseUploadStream
            .asObservable(.uploadCompletedStream)
            .subscribe { (event) in
                switch event {
                case .error(let err):
                    print(err)
                case .next(let upload):
                    print("Metadata is \(upload.metadata)")
                    self.addFileToFirebaseDatabase(upload)
                case .completed:
                    print("FirebaseUpload Stream Completed")
                }
            }.disposed(by: dispose)
        
        // On start
        FirebaseFileChangeStream
            .asObservable(.localFileStream)
            .observeOn(MainScheduler.instance)
            .subscribe { (event) in
                switch event {
                case .error(let err):
                    print(err)
                case .next(let fileChange):
                    let thumb = Thumbnail(fileChange)
                    // if existed, don't add it
                    // OrderSet will be a better structure for thumbnails
                    if !self.existThumbnails(thumb) {
                        print("load local image")
                        let path = DocumentManager.shared.getPath(thumb.name)
                        let url = URL(fileURLWithPath: path)
                        if thumb.type == .image {
                            // load image to memory
                            do {
                                let imageData = try Data(contentsOf: url)
                                thumb.image = UIImage(data: imageData)
                            } catch {
                                print("Error loading image : \(error)")
                                thumb.image = UIImage.from(color: .white)
                            }
                        } else {
                            thumb.videoURL = url
                        }
                        self.insertThumbnails(thumb)
                        self.thumbnailsView.reloadData()
                    }
                case .completed:
                    print("FirebaseUpload Stream Completed")
                }
            }.disposed(by: dispose)
        
        // new file uploaded by other device, download and update thumbnailsView
        FirebaseFileChangeStream
            .asObservable(.fileDownloadedStream)
            .observeOn(MainScheduler.instance)
            .subscribe { (event) in
                switch event {
                case .error(let err):
                    print(err)
                case .next(let fileChange):
                    let thumb = Thumbnail(fileChange)
                    self.insertThumbnails(thumb)
                    self.thumbnailsView.reloadData()
                case .completed:
                    print("FirebaseUpload Stream Completed")
                }
            }.disposed(by: dispose)
        
        FirebaseFileChangeStream
            .asObservable(.needRemoveStream)
            .observeOn(MainScheduler.instance)
            .subscribe { (event) in
                switch event {
                case .error(let err):
                    print(err)
                case .next(let fileChange):
                    do {
                        try DocumentManager.shared.remove(fileChange.name)
                        self.thumbnails = self.thumbnails.filter({ (thumbnail) -> Bool in
                            if thumbnail.timestamp == fileChange.timestamp {
                                return false
                            }
                            return true
                        })
                        self.thumbnailsView.reloadData()
                    } catch let e {
                        print("Save error \(e.localizedDescription)")
                    }
                case .completed:
                    print("FirebaseUpload Stream Completed")
                }
            }.disposed(by: dispose)
    }
    
    func insertThumbnails(_ thumbnail: Thumbnail) {
        thumbnails.append(thumbnail)
        thumbnails.sort { (t1, t2) -> Bool in
            return Double(t1.timestamp)! > Double(t2.timestamp)!
        }
    }
    
    func existThumbnails(_ thumbnail: Thumbnail) -> Bool {
        for t in thumbnails {
            if t.timestamp == thumbnail.timestamp {
                return true
            }
        }
        return false
    }
    
    func addFileToFirebaseDatabase(_ file: FirebaseUpload) {
        let databaseRef = Database.database().reference()
            .child("users")
            .child(file.uid!)
            .child("files")
            .child(file.fileId)
        let type = file.type == .image ? "image" : "video"
        let path = file.metadata!.path!
        let url = file.metadata!.downloadURL()?.absoluteString
        let filedata = ["type": type,
                        "uploadDevice": UIDevice.current.identifierForVendor!.uuidString,
                        "name": file.metadata!.name!,
                        "path": path,
                        "timestamp": file.timestamp,
                        "url": url]
        databaseRef.updateChildValues(filedata)
    }
    
    fileprivate func setupCollectionLayout() {
        let cellsAcross: CGFloat = 4
        let spaceBetweenCells: CGFloat = 1
        let cellWidth: CGFloat = (thumbnailsView.bounds.width - (cellsAcross - 1) * spaceBetweenCells) / cellsAcross
        let cellheight: CGFloat = thumbnailsView.frame.height
        let cellSize = CGSize(width: cellWidth , height:cellheight)
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = cellSize
        // layout.sectionInset = UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
        layout.minimumLineSpacing = spaceBetweenCells
        layout.minimumInteritemSpacing = spaceBetweenCells
        thumbnailsView.setCollectionViewLayout(layout, animated: false)
    }
    
    func getPlayerView(_ thumbnail: Thumbnail) -> AVPlayerViewController {
        let player = AVPlayer(url: thumbnail.videoURL!)
        let playerController = AVPlayerViewController()
        playerController.showsPlaybackControls = false
        
        playerController.player = player
        return playerController
    }
}

// Collection View
extension ViewController {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return thumbnails.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ThumbnailCollectionViewCell.self), for: indexPath) as! ThumbnailCollectionViewCell
        cell.thumbnail = thumbnails[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! ThumbnailCollectionViewCell
        print(cell.thumbnail)
        if cell.thumbnail!.type == .image {
            let vc = ImageViewController(cell.thumbnail!)
            self.present(vc, animated: true, completion: nil)
        } else {
            let vc = VideoViewController(cell.thumbnail!)
            self.present(vc, animated: true, completion: nil)
        }
    }
}

