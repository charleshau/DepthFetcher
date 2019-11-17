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
let out = "test00"
let fileName = "\(out).jpg"
let fullFileName = "/Users/Charles/Library/Mobile Documents/com~apple~CloudDocs/Project/DepthFetcher/DepthFetcher/\(fileName)"
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

func CVbufferChecker (out:String)->(NSImage)
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
            return ((0, 0), -1, nil)
        }

        var depthData: AVDepthData
        do {
            depthData = try AVDepthData(fromDictionaryRepresentation: auxDataInfo)
        } catch {
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
        let fileUrl = documentsUrl.appendingPathComponent("\(out).txt")

        var res = ""

        for x in 0...width/3
        {
            for y in 0...height/3
            {
                let sampleX = 3*x
                let sampleY = 3*y
                let point = CGPoint(x:sampleX,y:sampleY)
                let distanceAtXYPoint = depthPointer[Int(point.y * CGFloat(width) + point.x)]
                res = res + String(sampleX) + " " + String(sampleY) + " " + String(distanceAtXYPoint) + "\n"
            }
        }

        try! res.write(to: fileUrl!, atomically: true, encoding: String.Encoding.utf8)

        return ((x, y),
                0, depthData.depthDataMap
        )
    }

    let GPSource = CIImage(
        cvPixelBuffer: CVbufferMaker(ext: ext, fileName: fileName, x: 100,y: 0).2!
    )

    let EPSource = GPSource.nsImage

    return EPSource
}

fprintf(EPSource:CVbufferChecker(out:out), out:out);
