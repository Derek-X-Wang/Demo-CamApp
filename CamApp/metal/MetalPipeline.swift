//
//  MetalPipeline.swift
//  CamApp
//
//  Created by Xinzhe Wang on 1/9/18.
//  Copyright © 2018 IntBridge. All rights reserved.
//

import Foundation
import Metal
import MetalKit

//protocol PipelineState {
//
//}

class MetalPipeline {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let library: MTLLibrary
    let mergeHalfAlpha: MTLFunction
    var pipelineState: MTLComputePipelineState? = nil
    
    var girdCompleted = 0
    var inTextures: [MTLTexture] = [MTLTexture]()
    var outTextures: [MTLTexture] = [MTLTexture]()
    var tempTime: CFTimeInterval?
    
    init() {
        self.device = MTLCreateSystemDefaultDevice()!
        self.commandQueue = self.device.makeCommandQueue()!
        self.library = self.device.makeDefaultLibrary()!
        self.mergeHalfAlpha = self.library.makeFunction(name: "mergeHalfAlpha")!
        do {
            self.pipelineState = try self.device.makeComputePipelineState(function: self.mergeHalfAlpha)
        } catch {
            print("Error initializing pipeline state!")
        }
    }
    
    func importTextures(_ images: [CGImage]) {
        
        inTextures = []
        outTextures = []
        let textureLoader = MTKTextureLoader(device: device)
        do {
            for image in images {
                let texture = try textureLoader.newTexture(cgImage: image, options: nil)
                let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: texture.pixelFormat, width: texture.width, height: texture.height, mipmapped: false)
                textureDescriptor.usage = .shaderWrite
                inTextures.append(texture)
                outTextures.append(device.makeTexture(descriptor: textureDescriptor)!)
            }
            // outTextures.count = inTextures - 1
            _ = outTextures.popLast()
        }
        catch {
            fatalError("Can't load texture")
        }
    }
    
    func image(_ texture: MTLTexture) -> CGImage {
        
        let bytesPerPixel = 4
        let imageByteCount = texture.width * texture.height * bytesPerPixel
        let bytesPerRow = texture.width * bytesPerPixel
        var src = [UInt8](repeating: 0, count: Int(imageByteCount))
        
        let region = MTLRegionMake2D(0, 0, texture.width, texture.height)
        texture.getBytes(&src, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
        
        let bitmapInfo = CGBitmapInfo(rawValue: (CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue))
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitsPerComponent = 8
        let context = CGContext(data: &src,
                                width: texture.width,
                                height: texture.height,
                                bitsPerComponent: bitsPerComponent,
                                bytesPerRow: bytesPerRow,
                                space: colorSpace,
                                bitmapInfo: bitmapInfo.rawValue)
        
        return context!.makeImage()!
    }
    
    func process() {
        tempTime = CACurrentMediaTime()
        let count = outTextures.count
        for i in 0..<count {
            processImageTextureAsync(inTexture1: inTextures[i], inTexture2: inTextures[i+1], outTexture: outTextures[i])
        }
        //processImageTextureAsync(inTexture1: inTextures[0], inTexture2: inTextures[1], outTexture: outTextures[0])
        //processImageTextureAsync(inTexture1: inTextures[1], inTexture2: inTextures[2], outTexture: outTextures[1])
    }
    
    func exportImages() -> [CGImage] {
        return outTextures.map({ (texture) -> CGImage in
            self.image(texture)
        })
//        return [outTextures[0], outTextures[0]].map({ (texture) -> CGImage in
//            self.image(texture)
//        })
    }
    
    func processImageTexture(inTexture1: MTLTexture, inTexture2: MTLTexture, outTexture: MTLTexture) {
        let commandBuffer = self.commandQueue.makeCommandBuffer()!
        let commandEncoder = commandBuffer.makeComputeCommandEncoder()!
        commandEncoder.setComputePipelineState(self.pipelineState!)
        commandEncoder.setTexture(inTexture1, index: 0)
        commandEncoder.setTexture(inTexture2, index: 1)
        commandEncoder.setTexture(outTexture, index: 2)
        
//        let gridSize : MTLSize = MTLSize(width: 32, height: 32, depth: 1)
//        let threadGroupSize : MTLSize = MTLSize(width: inTexture1.width/gridSize.width, height: inTexture1.height/gridSize.height, depth: 1)
        
        let w = pipelineState!.threadExecutionWidth
        let h = pipelineState!.maxTotalThreadsPerThreadgroup / w
        let threadsPerThreadgroup = MTLSizeMake(w, h, 1)
        let threadgroupsPerGrid = MTLSize(width: (inTexture1.width + w - 1) / w, height: (inTexture1.height + h - 1) / h, depth: 1)
        
        commandEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        commandEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
    
    func processImageTextureAsync(inTexture1: MTLTexture, inTexture2: MTLTexture, outTexture: MTLTexture) {
        let commandBuffer = self.commandQueue.makeCommandBuffer()!
        let commandEncoder = commandBuffer.makeComputeCommandEncoder()!
        commandEncoder.setComputePipelineState(self.pipelineState!)
        commandEncoder.setTexture(inTexture1, index: 0)
        commandEncoder.setTexture(inTexture2, index: 1)
        commandEncoder.setTexture(outTexture, index: 2)
        
        let w = pipelineState!.threadExecutionWidth
        let h = pipelineState!.maxTotalThreadsPerThreadgroup / w
        let threadsPerThreadgroup = MTLSizeMake(w, h, 1)
        let threadgroupsPerGrid = MTLSize(width: (outTexture.width + w - 1) / w, height: (outTexture.height + h - 1) / h, depth: 1)
        
        commandEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        commandEncoder.endEncoding()
        commandBuffer.addCompletedHandler({(buffer) -> Void in
            if (buffer.error != nil) {
                print("There was an error completing an image texture: \(buffer.error!.localizedDescription)")
            } else {
                self.girdCompleted = self.girdCompleted + 1
                print("girdCompleted \(self.girdCompleted)")
                if (self.girdCompleted == self.outTextures.count) {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "IMAGE_COMPLETED"), object: self, userInfo: [:])
                    let t1 = CACurrentMediaTime()
                    print("process time is \(t1 - self.tempTime!)")
                }
            }
        })
        commandBuffer.commit()
    }
}
