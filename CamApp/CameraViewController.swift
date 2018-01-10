//
//  CameraViewController.swift
//  CamApp
//
//  Created by Xinzhe Wang on 1/4/18.
//  Copyright © 2018 IntBridge. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: SwiftyCamViewController, SwiftyCamViewControllerDelegate {

    @IBOutlet weak var captureButton: SwiftyRecordButton!
    @IBOutlet weak var flipCameraButton: UIButton!
    @IBOutlet weak var toggleButton: UIButton!
    
    var vc: ViewController?
    var isThumbnailsViewShowed = true
    
    override func viewDidLoad() {
        videoGravity = .resizeAspectFill
        super.viewDidLoad()
        shouldPrompToAppSettings = true
        cameraDelegate = self
        maximumVideoDuration = 2.0
        videoQuality = .resolution1280x720
        shouldUseDeviceOrientation = true
        allowAutoRotate = true
        audioEnabled = true
        captureButton.buttonEnabled = false
        
        hideControl()
        NotificationCenter.default.addObserver(self, selector: #selector(toggleControl), name: NSNotification.Name(rawValue: "TOGGLE_CONTROL"), object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        captureButton.delegate = self
    }
    
}

// Swifty CamView Controller Delegate
extension CameraViewController {
    func swiftyCamSessionDidStartRunning(_ swiftyCam: SwiftyCamViewController) {
        print("Session did start running")
        captureButton.buttonEnabled = true
    }
    
    func swiftyCamSessionDidStopRunning(_ swiftyCam: SwiftyCamViewController) {
        print("Session did stop running")
        captureButton.buttonEnabled = false
    }
    
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didTake photo: UIImage) {
        print("photo taked")
        FirebaseUploadStream.send(FirebaseUpload(photo))
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didBeginRecordingVideo camera: SwiftyCamViewController.CameraSelection) {
        print("Did Begin Recording")
        captureButton.growButton()
        hideButtons()
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishRecordingVideo camera: SwiftyCamViewController.CameraSelection) {
        print("Did finish Recording")
        captureButton.shrinkButton()
        showButtons()
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFinishProcessVideoAt url: URL) {
        print("video taked")
        FirebaseUploadStream.send(FirebaseUpload(url))
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFocusAtPoint point: CGPoint) {
        print("Did focus at point: \(point)")
        focusAnimationAt(point)
    }
    
    func swiftyCamDidFailToConfigure(_ swiftyCam: SwiftyCamViewController) {
        let message = NSLocalizedString("Unable to capture media", comment: "Alert message when something goes wrong during capture session configuration")
        let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didChangeZoomLevel zoom: CGFloat) {
        print("Zoom level did change. Level: \(zoom)")
        print(zoom)
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didSwitchCameras camera: SwiftyCamViewController.CameraSelection) {
        print("Camera did change to \(camera.rawValue)")
        print(camera)
    }
    
    func swiftyCam(_ swiftyCam: SwiftyCamViewController, didFailToRecordVideo error: Error) {
        print(error)
    }
    
    @IBAction func cameraSwitchTapped(_ sender: Any) {
        switchCamera()
    }
    
    @IBAction func toggleTapped(_ sender: Any) {
        let notificationName = Notification.Name(rawValue: "TOGGLE_THUMBNAILSVIEW")
        NotificationCenter.default.post(name: notificationName, object: self,
                                        userInfo: [:])
        toggleThumbnailsViewAnimation()
    }
}

// UI Animations
extension CameraViewController {
    
    @objc func toggleControl(notification: Notification) {
        if captureButton.isHidden {
            showControl()
        } else {
            hideControl()
        }
    }
    
    fileprivate func hideControl() {
        captureButton.isHidden = true
        toggleButton.isHidden = true
        flipCameraButton.isHidden = true
    }
    
    fileprivate func showControl() {
        captureButton.isHidden = false
        toggleButton.isHidden = false
        flipCameraButton.isHidden = false
    }
    
    fileprivate func hideButtons() {
        UIView.animate(withDuration: 0.25) {
            self.captureButton.alpha = 0.0
            self.toggleButton.alpha = 0.0
            self.flipCameraButton.alpha = 0.0
        }
    }
    
    fileprivate func showButtons() {
        UIView.animate(withDuration: 0.25) {
            self.captureButton.alpha = 1.0
            self.toggleButton.alpha = 1.0
            self.flipCameraButton.alpha = 1.0
        }
    }
    
    fileprivate func focusAnimationAt(_ point: CGPoint) {
        let focusView = UIImageView(image: #imageLiteral(resourceName: "focus"))
        focusView.center = point
        focusView.alpha = 0.0
        view.addSubview(focusView)
        
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
            focusView.alpha = 1.0
            focusView.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
        }) { (success) in
            UIView.animate(withDuration: 0.15, delay: 0.5, options: .curveEaseInOut, animations: {
                focusView.alpha = 0.0
                focusView.transform = CGAffineTransform(translationX: 0.6, y: 0.6)
            }) { (success) in
                focusView.removeFromSuperview()
            }
        }
    }
    
    fileprivate func toggleThumbnailsViewAnimation() {
        isThumbnailsViewShowed = !isThumbnailsViewShowed
        if isThumbnailsViewShowed {
            toggleButton.setImage(#imageLiteral(resourceName: "icons8-sort-down-filled-100"), for: UIControlState())
        } else {
            toggleButton.setImage(#imageLiteral(resourceName: "icons8-sort-up-filled-100"), for: UIControlState())
        }
    }
}
