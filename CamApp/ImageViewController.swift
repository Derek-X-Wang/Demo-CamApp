//
//  ImageViewController.swift
//  CamApp
//
//  Created by Xinzhe Wang on 1/6/18.
//  Copyright © 2018 IntBridge. All rights reserved.
//

import UIKit
import Firebase

class ImageViewController: UIViewController {
    
    private var thumbnail: Thumbnail
    private var displayedImage: UIImage

    init(_ thumbnail: Thumbnail) {
        self.thumbnail = thumbnail
        self.displayedImage = thumbnail.image!
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.gray
        let backgroundImageView = UIImageView(frame: view.frame)
        backgroundImageView.contentMode = UIViewContentMode.scaleAspectFit
        backgroundImageView.image = displayedImage
        view.addSubview(backgroundImageView)
        
        let cancelButton = UIButton(frame: CGRect(x: 10.0, y: 10.0, width: 30.0, height: 30.0))
        cancelButton.setImage(#imageLiteral(resourceName: "icons8-delete-100"), for: UIControlState())
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        view.addSubview(cancelButton)
        
        let deleteButton = UIButton(frame: CGRect(x: view.frame.width - 40, y: 10, width: 30.0, height: 30.0))
        deleteButton.setImage(#imageLiteral(resourceName: "icons8-waste-100"), for: UIControlState())
        deleteButton.addTarget(self, action: #selector(remove), for: .touchUpInside)
        view.addSubview(deleteButton)
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
    }

}
