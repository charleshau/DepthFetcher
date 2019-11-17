//
//  main.swift
//  DepthFetcher
//
//  Created by Charles He on 2019-11-16.
//  Copyright © 2019 Charles He. All rights reserved.
//

import Foundation
import AVFoundation


let ext = "jpg"
let fileName = "/Users/Charles/Library/Mobile Documents/com~apple~CloudDocs/Project/DepthFetcher/DepthFetcher/test00"

//if let image:NSImage = NSImage(byReferencingFile: fileName)
//{
//    print("image size \(image.size.width):\(image.size.height)")
//}

// Create a CFURL for the image in the Bundle
func depthDataMap (ext:String, fileName:String, x:Int, y:Int) -> ((Int, Int), Float32, CVPixelBuffer?)
{
//    guard let fileURL = Bundle.main.url(forResource: fileName, withExtension: ext) as CFURL? else {
//        print("Open File \(fileName) Failed")
//        return ((0, 0), -1, nil)
//    }

    let image = NSImage(named:fileName)
    if let image = image {
        var imageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        let imageRef = image.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)
    }

    // Create a CGImageSource
//    guard let source = CGImageSourceCreateWithURL(fileURL, nil) else {
//        print("Create a CGImageSource Failed")
//        return ((0, 0), -1, nil)
//    }

    guard let auxDataInfo = CGImageSourceCopyAuxiliaryDataInfoAtIndex(source, 0, kCGImageAuxiliaryDataTypeDisparity) as? [AnyHashable : Any] else {
        return ((0, 0), -1, nil)
    }

      // This is the star of the show!
    var depthData: AVDepthData

    do { // Get the depth data from the auxiliary data info
        depthData = try AVDepthData(fromDictionaryRepresentation: auxDataInfo)
    } catch {
        return ((0, 0), -1, nil)
    }

    // Make sure the depth data is the type we want
    if depthData.depthDataType != kCVPixelFormatType_DisparityFloat32 {
        depthData = depthData.converting(toDepthDataType: kCVPixelFormatType_DisparityFloat32)
    }

    let depthDataMap = depthData.depthDataMap

    CVPixelBufferLockBaseAddress(depthDataMap, CVPixelBufferLockFlags(rawValue: 0))
    let depthPointer = unsafeBitCast(CVPixelBufferGetBaseAddress(depthDataMap), to: UnsafeMutablePointer<Float32>.self)

    let point = CGPoint(x:x,y:y)
    let width = CVPixelBufferGetWidth(depthDataMap)
    let distanceAtXYPoint = depthPointer[Int(point.y * CGFloat(width) + point.x)]

    return ((x, y), distanceAtXYPoint, depthData.depthDataMap)
}

print(depthDataMap(ext: ext, fileName: fileName, x: 0,y: 0).1);
