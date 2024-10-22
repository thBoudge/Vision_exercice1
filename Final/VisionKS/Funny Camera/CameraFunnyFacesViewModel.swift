/// Copyright (c) 2024 Kodeco Inc.
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import SwiftUI
import Combine
import Vision
import OSLog


class CameraFunnyFacesViewModel: ObservableObject {
  @Published var errorMessage: String? = nil
  @Published var faceObservations: [VNFaceObservation] = [] 
  
  @MainActor func detectFaces(for image:UIImage) {
    self.faceObservations.removeAll()
    self.errorMessage = nil
        
    let faceDetectionRequest = VNDetectFaceLandmarksRequest()

#if targetEnvironment(simulator)
    let supportedDevices = try! faceDetectionRequest.supportedComputeStageDevices
    if let mainStage = supportedDevices[.main] {
      if let cpuDevice = mainStage.first(where: { device in
        device.description.contains("CPU")
      }) {
        faceDetectionRequest.setComputeDevice(cpuDevice, for: .main)
      }
    }
#endif
    guard let cgImage = image.cgImage else {
      DispatchQueue.main.async {
        self.errorMessage = "Failed to convert UIImage to CGImage"
      }
      return
    }
    
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    
    do {
        // Perform the face detection request
        try handler.perform([faceDetectionRequest])
        
        // Retrieve the results as face observations
      guard let observations = faceDetectionRequest.results else {
            self.errorMessage = "Failed to cast results to [VNFaceObservation]"
            return
        }
        
        // Check if any faces were detected
        if observations.isEmpty {
            self.errorMessage = "No faces detected"
        } else {
            self.faceObservations = observations
        }
    } catch {
        // Handle any errors that occurred during the request
        self.errorMessage = "Failed to perform face detection: \(error.localizedDescription)"
    }
  }
}

