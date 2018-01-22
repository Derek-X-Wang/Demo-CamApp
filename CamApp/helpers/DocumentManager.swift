//
//  DocumentManager.swift
//  CamApp
//
//  Created by Xinzhe Wang on 1/6/18.
//  Copyright © 2018 IntBridge. All rights reserved.
//

import UIKit
import Foundation

class DocumentManager {
    static let shared = DocumentManager()
    let manager: FileManager
    let homeURL: URL
    private init() {
        manager = FileManager.default
        let urlForDocument = manager.urls(for: .documentDirectory, in:.userDomainMask)
        homeURL = urlForDocument[0] as URL
        let directoryPath = homeURL.path + "/files"
        var isDir : ObjCBool = true
        let url = URL(fileURLWithPath: directoryPath)
        print(directoryPath)
        print(url.path)
        if !manager.fileExists(atPath: directoryPath, isDirectory: &isDir) {
            // file does not exist
            do {
                try manager.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)
            } catch let e {
                print("create folder fail \(e.localizedDescription)")
            }
        } else {
            print("folder existed")
        }
    }
    
    func getPath(_ name: String) -> String {
        return homeURL.path + "/files/\(name)"
    }
    
    func save(_ upload: FirebaseUpload) throws {
        if upload.type == .image {
            try save(upload.image!, name: "\(upload.timestamp).jpg")
        } else {
            try save(upload.videoURL!, name: "\(upload.timestamp).mov")
            let toUrl = getPath("\(upload.timestamp).mov")
            upload.videoURL = URL(fileURLWithPath: toUrl)
        }
    }
    
    func save(_ image: UIImage, name: String) throws {
        let filePath = getPath(name)
        let data = UIImageJPEGRepresentation(image, 1)!
        try data.write(to: URL(fileURLWithPath: filePath))
    }
    
    func save(_ image: UIImage, name: String, metadata: NSMutableDictionary) {
        let filePath = getPath(name)
        let url = URL(fileURLWithPath: filePath)
        let data = UIImageJPEGRepresentation(image, 1)!
        let source = CGImageSourceCreateWithData(data as CFData, nil)
        let uniformTypeIdentifier = CGImageSourceGetType(source!)
        let destination = CGImageDestinationCreateWithURL(url as CFURL, uniformTypeIdentifier!, 1, nil)
        CGImageDestinationAddImageFromSource(destination!, source!, 0, metadata)
        CGImageDestinationFinalize(destination!)
    }
    
    func save(_ url: URL, name: String) throws {
        print("h1")
        let toUrl = getPath(name)
        print("h2")
        // use copy not move, since we will use tmp/video for upload
        // new copy for loading when relaunch the app
        try manager.copyItem(atPath: url.path, toPath: toUrl)
        //try manager.moveItem(atPath: url.path, toPath: toUrl)
        print("h3")
    }
    
    func exited(_ name: String) -> Bool {
        let filePath = getPath(name)
        return manager.fileExists(atPath: filePath)
    }
    
    func retrieve(_ name: String) -> URL? {
        guard exited(name) else { return nil }
        let filePath = getPath(name)
        return URL(fileURLWithPath: filePath)
    }
    
    func remove(_ name: String) throws {
        guard exited(name) else { return }
        let srcUrl = getPath(name)
        try manager.removeItem(atPath: srcUrl)
    }
}
