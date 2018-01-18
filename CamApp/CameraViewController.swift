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
        videoQuality = .high
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
        //switchCamera()
        showPresets()
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
    
    func showPresets() {
        let actionSheet = UIAlertController(title: "Choose Preset", message: "choose available", preferredStyle: .actionSheet)
        let highAction = UIAlertAction(title: "High(default)", style: .default, handler: { action in
            self.changePreset(.high)
        })
        let mediumAction = UIAlertAction(title: "Medium", style: .default, handler: { action in
            self.changePreset(.medium)
        })
        let lowAction = UIAlertAction(title: "Low", style: .default, handler: { action in
            self.changePreset(.low)
        })
        let resolution352x288Action = UIAlertAction(title: "resolution352x288", style: .default, handler: { action in
            self.changePreset(.resolution352x288)
        })
        let resolution640x480Action = UIAlertAction(title: "resolution640x480", style: .default, handler: { action in
            self.changePreset(.resolution640x480)
        })
        let resolution1280x720Action = UIAlertAction(title: "resolution1280x720", style: .default, handler: { action in
            self.changePreset(.resolution1280x720)
        })
        let resolution1920x1080Action = UIAlertAction(title: "resolution1920x1080", style: .default, handler: { action in
            self.changePreset(.resolution1920x1080)
        })
        let iframe960x540Action = UIAlertAction(title: "iframe960x540", style: .default, handler: { action in
            self.changePreset(.iframe960x540)
        })
        let iframe1280x720Action = UIAlertAction(title: "iframe1280x720", style: .default, handler: { action in
            self.changePreset(.iframe1280x720)
        })
        let resolution3840x2160Action = UIAlertAction(title: "resolution3840x2160(ios 9+)", style: .default, handler: { action in
            self.changePreset(.resolution3840x2160)
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            print("cancel")
        })
        actionSheet.addAction(highAction)
        actionSheet.addAction(mediumAction)
        actionSheet.addAction(lowAction)
        actionSheet.addAction(resolution352x288Action)
        actionSheet.addAction(resolution640x480Action)
        actionSheet.addAction(resolution1280x720Action)
        actionSheet.addAction(resolution1920x1080Action)
        actionSheet.addAction(iframe960x540Action)
        actionSheet.addAction(iframe1280x720Action)
        actionSheet.addAction(resolution3840x2160Action)
        actionSheet.addAction(cancelAction)
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func changePreset(_ quality: VideoQuality) {
        if session.canSetSessionPreset(AVCaptureSession.Preset(rawValue: videoInputPresetFromVideoQuality(quality: quality))) {
            videoQuality = quality
            session.sessionPreset = AVCaptureSession.Preset(rawValue: videoInputPresetFromVideoQuality(quality: quality))
        } else {
            let alert = UIAlertController(title: "Unsupported Preset", message: "Please try another preset", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: { action in
                print("okay")
            })
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    fileprivate func videoInputPresetFromVideoQuality(quality: VideoQuality) -> String {
        switch quality {
        case .high: return AVCaptureSession.Preset.high.rawValue
        case .medium: return AVCaptureSession.Preset.medium.rawValue
        case .low: return AVCaptureSession.Preset.low.rawValue
        case .resolution352x288: return AVCaptureSession.Preset.cif352x288.rawValue
        case .resolution640x480: return AVCaptureSession.Preset.vga640x480.rawValue
        case .resolution1280x720: return AVCaptureSession.Preset.hd1280x720.rawValue
        case .resolution1920x1080: return AVCaptureSession.Preset.hd1920x1080.rawValue
        case .iframe960x540: return AVCaptureSession.Preset.iFrame960x540.rawValue
        case .iframe1280x720: return AVCaptureSession.Preset.iFrame1280x720.rawValue
        case .resolution3840x2160:
            if #available(iOS 9.0, *) {
                return AVCaptureSession.Preset.hd4K3840x2160.rawValue
            }
            else {
                print("[SwiftyCam]: Resolution 3840x2160 not supported")
                return AVCaptureSession.Preset.high.rawValue
            }
        }
    }
    
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
