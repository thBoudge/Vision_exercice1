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

import AVFoundation
import UIKit

class CameraViewModel: NSObject, ObservableObject {
    @Published var currentFrame: UIImage?

    private var captureSession = AVCaptureSession()
    private var videoOutput = AVCaptureVideoDataOutput()
    private var videoInput: AVCaptureDeviceInput?

  @MainActor func setupSession() async {
    captureSession.sessionPreset = .photo

        // Remove existing inputs to avoid multiple input errors
        if let currentInput = videoInput {
            captureSession.removeInput(currentInput)
        }

        // Discover the front camera using AVCaptureDeviceDiscoverySession
    let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .front
        )

    guard let camera = discoverySession.devices.first else {
            print("Front camera not available.")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                videoInput = input // Store the reference to the current input
            } else {
                print("Could not add video input.")
                return
            }
        } catch {
            print("Error setting up camera: \(error)")
            return
        }

        // Add the video output
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "cameraFeed"))
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        } else {
            print("Error adding video output.")
            return
        }

    }
  
  @MainActor func startSession() async {
    captureSession.startRunning()
  }

  @MainActor func stopSession() {
        captureSession.stopRunning()
    }
  
}

extension CameraViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
      guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
      let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
    
    // Rotate the CIImage based on orientation
            let orientation = UIDevice.current.orientation
            var transform: CGAffineTransform = .identity

            switch orientation {
            case .portrait:
                transform = CGAffineTransform(rotationAngle: 0)
            case .portraitUpsideDown:
                transform = CGAffineTransform(rotationAngle: .pi)
            case .landscapeLeft:
                transform = CGAffineTransform(rotationAngle: -.pi / 2)
            case .landscapeRight:
                transform = CGAffineTransform(rotationAngle: .pi / 2)
            default:
                break
            }

            let rotatedImage = ciImage.transformed(by: transform)
    
    
            let context = CIContext()

            if let cgImage = context.createCGImage(rotatedImage, from: rotatedImage.extent) {
                let finalImage = UIImage(cgImage: cgImage)
              DispatchQueue.main.async {
                self.currentFrame = finalImage
              }
            }
    
  }
}


