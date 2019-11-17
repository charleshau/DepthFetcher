//
//  main.swift
//  DepthFetcher
//
//  Created by Charles He on 2019-11-16.
//  Copyright © 2019 Charles He. All rights reserved.
//

import Cocoa
import Foundation
import AVFoundation
import AppKit
import CoreImage.CIImage


//let desktopDirectory = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
// FileManager.default.changeCurrentDirectoryPath(desktopDirectory.path) // lets change the current directory to the desktop directory
// let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
let out = "IMG_0311"
let fileName = "\(out).jpg"
let fullFileName = "/Users/Charles/Library/Mobile Documents/com~apple~CloudDocs/Project/DepthFetcher/MacOS/DepthFetcher/\(fileName)"
let ext = "jpg"
let pre = "file://"
let homeDirURL = FileManager.default.homeDirectoryForCurrentUser
let projectPATH = "Library/Mobile Documents/com~apple~CloudDocs/Project/DepthFetcher/DepthFetcher"
let projectURL = homeDirURL.appendingPathComponent(projectPATH)

extension String {
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
}

let str = String(
    describing:projectURL.appendingPathComponent(fileName)).deletingPrefix(pre)

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let context = CIContext()
        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        guard
            let filter = CIFilter(name: "CISepiaTone"),
            let imageURL = Bundle.main.url(forResource: "my-image", withExtension: "png"),
            let ciImage = CIImage(contentsOf: imageURL)
        else { return }

        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(0.5, forKey: kCIInputIntensityKey)

        guard let result = filter.outputImage, let cgImage = context.createCGImage(result, from: result.extent)
        else { return }

        let destinationURL = desktopURL.appendingPathComponent("my-image.png")
        let nsImage = NSImage(cgImage: cgImage, size: ciImage.extent.size)
        if nsImage.pngWrite(to: destinationURL, options: .withoutOverwriting) {
            print("File saved")
        }
    }
}

extension NSImage {
    var pngData: Data? {
        guard let tiffRepresentation = tiffRepresentation, let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
        return bitmapImage.representation(using: .png, properties: [:])
    }
    func pngWrite(to url: URL, options: Data.WritingOptions = .atomic) -> Bool {
        do {
            try pngData?.write(to: url, options: options)
            return true
        } catch {
            print(error)
            return false
        }
    }
}

extension CIImage {
    public var nsImage: NSImage {
        let rep = NSCIImageRep(ciImage: self)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)
        return nsImage
    }
}

extension URL {
    var isDirectory: Bool {
       return (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
}

extension NSBitmapImageRep.FileType {
    var pathExtension: String {
        switch self {
        case .jpeg:
            return "jpg"
        case .png:
            return "png"
        default:
            return ""
        }
    }
}

extension NSImage {
    func save(as fileName: String, fileType: NSBitmapImageRep.FileType = .jpeg, at directory: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)) -> Bool {
        guard let tiffRepresentation = tiffRepresentation, directory.isDirectory, !fileName.isEmpty else { return false }
        do {
            try NSBitmapImageRep(data: tiffRepresentation)?
                .representation(using: fileType, properties: [:])?
                .write(to: directory.appendingPathComponent(fileName).appendingPathExtension(fileType.pathExtension))
            return true
        } catch {
            print(error)
            return false
        }
    }
}

func fprintf(EPSource:NSImage, out:String)->()
{
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    if EPSource.save(as: out, fileType: .png, at:getDocumentsDirectory()) {
        print("file saved as fullFileName2 which is the default type")
    }
}

struct property_of_iPhoneDual {
  static let slope: CGFloat = 1.0
  static let width: CGFloat = 0.3
}

func CVModifier (for Source: CIImage, focus_on focus: CGFloat, Scale scale: CGFloat) -> CIImage
{
    let s1 = property_of_iPhoneDual.slope
    let s2 = -property_of_iPhoneDual.slope
    let filterWidth =  2 / property_of_iPhoneDual.slope + property_of_iPhoneDual.width
    let b1 = -property_of_iPhoneDual.slope * (focus - filterWidth / 2)
    let b2 = -(-property_of_iPhoneDual.slope) * (focus + filterWidth / 2)
    let mask0 = Source
        .applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: s1, y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: s1, z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: s1, w: 0),
            "inputBiasVector": CIVector(x: b1, y: b1, z: b1, w: 0)])
        .applyingFilter("CIColorClamp")

    let mask1 = Source
        .applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: s2, y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: s2, z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: s2, w: 0),
            "inputBiasVector": CIVector(x: b2, y: b2, z: b2, w: 0)])
        .applyingFilter("CIColorClamp")
    let combinedMask = mask0.applyingFilter("CIDarkenBlendMode", parameters: ["inputBackgroundImage" : mask1])
    let mask = combinedMask.applyingFilter("CIBicubicScaleTransform", parameters: ["inputScale": scale])
    return mask
}

func CVBufferChecker (out:String)->(NSImage)
{
    func CVbufferMaker (ext:String, fileName:String, x:Int, y:Int) -> ((Int, Int), Float32, CVPixelBuffer?)
    {

        guard let url = NSURL.fileURL(
            withPath: fullFileName
        )
          as CFURL? else {
            print("File Exists?")
            return ((0, 0), -1, nil)
        }

        print(url)

        guard let source =
            CGImageSourceCreateWithURL(url, nil)
          else {
            print("Create Source Failed")
            return ((0, 0), -1, nil)
        }

        guard let auxDataInfo =
            CGImageSourceCopyAuxiliaryDataInfoAtIndex(
                source as CGImageSource, 0, kCGImageAuxiliaryDataTypeDisparity
            )
        as? [AnyHashable : Any] else {
            print("File Format Error")
            return ((0, 0), -1, nil)
        }

        var depthData: AVDepthData
        do {
            depthData = try AVDepthData(fromDictionaryRepresentation: auxDataInfo)
        } catch {
            print("File Format Error")
            return ((0, 0), -1, nil)
        }
        if depthData.depthDataType != kCVPixelFormatType_DisparityFloat32 {
            depthData = depthData.converting(toDepthDataType: kCVPixelFormatType_DisparityFloat32)
        }

        let depthDataMap = depthData.depthDataMap

        CVPixelBufferLockBaseAddress(
            depthDataMap,
            CVPixelBufferLockFlags(rawValue: 0)
        )
        let depthPointer = unsafeBitCast(
            CVPixelBufferGetBaseAddress(depthDataMap),
            to: UnsafeMutablePointer<Float32>.self
        )

        let width = CVPixelBufferGetWidth(depthDataMap)
        let height = CVPixelBufferGetHeight(depthDataMap)

        print(width)
        print(height)

        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as NSURL
        let fileUrl = documentsUrl
        var res = ""
        var res_2 = ""
        var res_3 = ""

        for x in 0...width-1
        {
            for y in 0...height/2-1
            {
                let sampleX_0 = x

                let sampleY_0 = y

                let point0 = CGPoint(x:sampleX_0,y:sampleY_0)

                let distanceAtXYPoint_0 = depthPointer[Int(point0.y * CGFloat(width) + point0.x)]

                res = res + String(distanceAtXYPoint_0) + ","
            }

            for y in height/2-1...height-2
            {
                let sampleX_0 = x

                let sampleY_0 = y

                let point0 = CGPoint(x:sampleX_0,y:sampleY_0)

                let distanceAtXYPoint_0 = depthPointer[Int(point0.y * CGFloat(width) + point0.x)]

                res_2 = res_2 + String(distanceAtXYPoint_0) + ","
            }
            res_3 = res_3+res+res_2
            res = ""
            res_2 = ""
            res_3 = res_3+"\n"
            print(x)
        }

        try! res_3.write(to: fileUrl.appendingPathComponent("\(out).csv")!, atomically: true, encoding: String.Encoding.utf8)

        return ((x, y),
                0, depthData.depthDataMap
        )
    }

    let core = CVbufferMaker(ext: ext, fileName: fileName, x: 100,y: 0)
    if core.1 != -1
    {
        let GPSource = CIImage(
            cvPixelBuffer: core.2!
        )
        let XPSource = CVModifier(for: GPSource, focus_on: 0 , Scale: 4)
        let EPSource = XPSource.nsImage
        return EPSource
    } else {
        print("Program Exit")
        exit(1)
    }
}

fprintf(EPSource:CVBufferChecker(out:out), out:out);
