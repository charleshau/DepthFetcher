/**
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#if !IOS_SIMULATOR
import AVFoundation

struct DepthReader {
  
  var name: String
  var ext: String
  
  func depthDataMap(x:Int, y:Int) -> ((Int, Int), Float32, CVPixelBuffer?) {
    
    // Create a CFURL for the image in the Bundle
    guard let fileURL = Bundle.main.url(forResource: name, withExtension: ext) as CFURL? else {
      return ((0, 0), 0, nil)
    }

    print(fileURL)

    // Create a CGImageSource
    guard let source = CGImageSourceCreateWithURL(fileURL, nil) else {
      return ((0, 0), 0, nil)
    }
        
    guard let auxDataInfo = CGImageSourceCopyAuxiliaryDataInfoAtIndex(source, 0, kCGImageAuxiliaryDataTypeDisparity) as? [AnyHashable : Any] else {
      return ((0, 0), 0, nil)
    }
    
    // This is the star of the show!
    var depthData: AVDepthData
    
    do {
      // Get the depth data from the auxiliary data info
      depthData = try AVDepthData(fromDictionaryRepresentation: auxDataInfo)
      
    } catch {
      return ((0, 0), 0, nil)
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
}
#endif

