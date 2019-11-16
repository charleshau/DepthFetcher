//
//  main.swift
//  DepthFetcher
//
//  Created by Charles He on 2019-11-16.
//  Copyright © 2019 Charles He. All rights reserved.
//

import Foundation
import AppKit
import AVFoundation


let fileName = "/Users/Charles/Library/Mobile Documents/com~apple~CloudDocs/Project/DepthFetcher/DepthFetcher/test00.jpg"

if let image = NSImage(byReferencingFile: fileName)
{
    print("image size \(image.size.width):\(image.size.height)")
}

depthDataMapImage.save(as: "profile", fileType: .png)
