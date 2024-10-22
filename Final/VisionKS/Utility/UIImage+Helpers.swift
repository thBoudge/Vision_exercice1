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

import UIKit
import Vision
import OSLog


//MARK: - FacesDetection UIImage extension
extension UIImage {
  /// Draws a vision rectangle on the image, adjusting for the image's orientation.
  ///
  /// This method is the main point of access, allowing you to draw a red rectangle on the image based on a vision rectangle.
  /// The rectangle's position is corrected based on the image's orientation.
  ///
  /// - Parameter visionRect: The rectangle to be drawn, provided in normalized coordinates.
  /// - Returns: A new `UIImage` with the vision rectangle drawn, or the original image if inputs are invalid.
  func drawVisionRect(_ visionRect: CGRect?) -> UIImage? {
    
    logger.debug("Original UIImage has an orientation of: \(self.imageOrientation.rawValue)")
    // Ensure the image's CGImage representation is available.
    
    guard let cgImage = self.cgImage else {
      return nil
    }
    
    // If visionRect is not provided, return the original image.
    guard let visionRect = visionRect else {
      return self
    }
    
    // Prepare the context size based on the image dimensions.
    let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
    
    // Begin a new image context with the correct size and scale.
    UIGraphicsBeginImageContextWithOptions(imageSize, false, self.scale)
    
    guard let context = UIGraphicsGetCurrentContext() else {
      return nil
    }
    
    // Draw the original image in the context.
    context.draw(cgImage, in: CGRect(origin: .zero, size: imageSize))
    
    // Calculate the rectangle using Vision's coordinate system to image coordinates.
    let correctedRect = VNImageRectForNormalizedRect(visionRect, Int(imageSize.width), Int(imageSize.height))
    
    // Draw the vision rectangle with a red fill and stroke.
    UIColor.red.withAlphaComponent(0.3).setFill()
    let rectPath = UIBezierPath(rect: correctedRect)
    rectPath.fill()
    
    UIColor.blue.setStroke()
    rectPath.lineWidth = 2.0
    rectPath.stroke()
    
    // Get the resulting image from the current context.
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    
    // End the image context to free up resources.
    UIGraphicsEndImageContext()
    
    // Adjust the image's orientation before returning.
    guard let finalCgImage = newImage?.cgImage else {
      return nil
    }
    
    let correctlyOrientedImage = UIImage(
      cgImage: finalCgImage,
      scale: self.scale,
      orientation: self.adjustOrientation()
    )
    logger.debug("Final image needs an orientation of \(correctlyOrientedImage.imageOrientation.rawValue) to look right.")
    return correctlyOrientedImage
  }
  
  /// Adjusts the orientation of the image based on its current orientation.
  ///
  /// This method is private and only accessible within the extension to ensure that it is only used internally.
  ///
  /// - Returns: The adjusted orientation that is the mirrored counterpart of the image's current orientation.
  private func adjustOrientation() -> UIImage.Orientation {
    switch self.imageOrientation {
    case .up:
      return .downMirrored
    case .upMirrored:
      return .up
    case .down:
      return .upMirrored
    case .downMirrored:
      return .down
    case .left:
      return .rightMirrored
    case .rightMirrored:
      return .left
    case .right:
      return .leftMirrored
    case .leftMirrored:
      return .right
    @unknown default:
      return self.imageOrientation
    }
  }
}

//MARK: - FunnyFaces UIImage extension
extension UIImage {
  /// Draws clown features, including eyes and mouth, on the provided image based on face observations.
  ///
  /// This method uses the face observations to detect and highlight clown features on the image,
  /// including drawing circles for the eyes and a clown-style mouth. The drawing operations are
  /// performed in a graphics context to ensure that the original image is not modified directly.
  ///
  /// - Parameter observations: An array of `VNFaceObservation` containing detected facial landmarks.
  /// - Returns: A new `UIImage` with clown features drawn on it, or nil if the operation fails.
  @MainActor func drawFunnyFace(observations: [VNFaceObservation], isWithEyes: Bool, isWithNose: Bool, isWithmouth: Bool) -> UIImage? {
    // If no face detection selected return nil
   
    logger.debug("Original UIImage has an orientation of: \(self.imageOrientation.rawValue)")
    // Ensure the image's CGImage representation is available.
    guard let cgImage = self.cgImage else {
      return nil
    }
    
    // Prepare the context size based on the image dimensions.
    let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
    
      // Start image context based on the current image
    UIGraphicsBeginImageContextWithOptions(imageSize, false, 0.0)
      
      // Get the current graphics context
      guard let context = UIGraphicsGetCurrentContext() else {
          return nil
      }
    // Draw the original image in the context.
    context.draw(cgImage, in: CGRect(origin: .zero, size: imageSize))
      
      // Loop through the face observations to find eyes
      for observation in observations {
          // Ensure landmarks are available
          guard let landmarks = observation.landmarks else { continue }
          
          // Get eye landmarks (leftEye and rightEye)
        if isWithEyes {
          if let leftEye = landmarks.leftEye {
            drawEyesCircle(for: leftEye, imageSize: imageSize, in: observation, context: context)
          }
          
          if let rightEye = landmarks.rightEye {
            drawEyesCircle(for: rightEye, imageSize: imageSize, in: observation, context: context)
          }
        }
        if isWithNose {
          if let nose = landmarks.nose {
            
            drawClownNoiseCircle(for: nose, imageSize: imageSize, in: observation, context: context)
          }
        }
        if isWithmouth {
          if let mouth = landmarks.outerLips {
            
            drawClownMouth(for: mouth, imageSize: imageSize, in: observation, context: context)
          }
        }
      }
      
    
      // Get the resulting image from the context
      let newImage = UIGraphicsGetImageFromCurrentImageContext()
      
      // End the image context
      UIGraphicsEndImageContext()
      
    // Adjust the image's orientation before returning.
    guard let finalCgImage = newImage?.cgImage else {
      return nil
    }
    
    let correctlyOrientedImage = UIImage(
      cgImage: finalCgImage,
      scale: self.scale,
      orientation: self.adjustOrientation()
    )
    logger.debug("Final image needs an orientation of \(correctlyOrientedImage.imageOrientation.rawValue) to look right.")
    return correctlyOrientedImage
  }
  
  /// Draws a circle to represent the eyes for a given eye landmark region.
  ///
  /// This method takes the eye landmark data and calculates the appropriate size and position
  /// for drawing a circle, which visually represents the eye in the clown style. The eye is
  /// drawn with a white outer circle and a black inner circle (pupil).
  ///
  /// - Parameter eye: The `VNFaceLandmarkRegion2D` representing the eye landmarks.
  /// - Parameter imageSize: The size of the original image, used for coordinate conversion.
  /// - Parameter observation: The `VNFaceObservation` from which the bounding box is obtained.
  /// - Parameter context: The graphics context where the eye is drawn.
  @MainActor private func drawEyesCircle(for eye: VNFaceLandmarkRegion2D, imageSize: CGSize, in observation: VNFaceObservation, context: CGContext) {
      // Get the bounding box of the face observation.
      let boundingBox = observation.boundingBox

      // Extract the eye landmark points.
      let points = eye.normalizedPoints

      // Find the min and max X and Y for the eye's bounding box.
      let minX = points.min { $0.x < $1.x }!.x
      let minY = points.min { $0.y < $1.y }!.y
      let maxX = points.max { $0.x < $1.x }!.x
      let maxY = points.max { $0.y < $1.y }!.y

      // Convert min and max points to actual image coordinates using VNImagePointForFaceLandmarkPoint.
      let minPoint = VNImagePointForFaceLandmarkPoint(
          vector_float2(Float(minX), Float(minY)),
          boundingBox,
          Int(imageSize.width),
          Int(imageSize.height)
      )
      let maxPoint = VNImagePointForFaceLandmarkPoint(
          vector_float2(Float(maxX), Float(maxY)),
          boundingBox,
          Int(imageSize.width),
          Int(imageSize.height)
      )
      
      // Calculate the center point of the eye based on the bounding box.
      let centerX = (minPoint.x + maxPoint.x) / 2
      let centerY = (minPoint.y + maxPoint.y) / 2

      // Calculate the eye size based on the distance between min and max points.
      let eyeSize = min(maxPoint.x - minPoint.x, maxPoint.y - minPoint.y) * 2  // Adjust size multiplier as needed.

      // Define the outer (white) circle, adapting its size to the eye size.
      let outerRadius = eyeSize
      let outerCircleRect = CGRect(x: centerX - outerRadius, y: centerY - outerRadius, width: outerRadius * 2, height: outerRadius * 2)

      // Define the inner (black) circle, centered within the white circle.
      let innerRadius = outerRadius * 0.6  // Black circle is 60% of the white circle size

      // Adjust the Y position to lower the black circle visually while keeping it centered.
      let innerCircleCenterY = centerY + (outerRadius * 0.15)  // Move the inner circle slightly lower
      let innerCircleRect = CGRect(x: centerX - innerRadius, y: innerCircleCenterY - innerRadius, width: innerRadius * 2, height: innerRadius * 2)

      // Draw the white outer circle (the eye).
      context.setFillColor(UIColor.white.cgColor)
      context.fillEllipse(in: outerCircleRect)

      // Draw the black inner circle (pupil), centered within the white circle but slightly lower.
      context.setFillColor(UIColor.black.cgColor)
      context.fillEllipse(in: innerCircleRect)
  }

  /// Draws a clown-style circle for the nose based on the provided nose landmark region.
  ///
  /// This method calculates the appropriate size and position for a clown-style nose,
  /// represented as a red circle. It uses the nose landmark data to ensure proper alignment
  /// on the face.
  ///
  /// - Parameter noise: The `VNFaceLandmarkRegion2D` representing the nose landmarks.
  /// - Parameter imageSize: The size of the original image, used for coordinate conversion.
  /// - Parameter observation: The `VNFaceObservation` from which the bounding box is obtained.
  /// - Parameter context: The graphics context where the clown nose is drawn.
  @MainActor private func drawClownNoiseCircle(for noise: VNFaceLandmarkRegion2D, imageSize: CGSize, in observation: VNFaceObservation, context: CGContext) {
          // Get the bounding box of the face observation.
          let boundingBox = observation.boundingBox

          // Extract the eye landmark points.
          let points = noise.normalizedPoints

          // Find the min and max X and Y for the eye's bounding box.
          let minX = points.min { $0.x < $1.x }!.x
          let minY = points.min { $0.y < $1.y }!.y
          let maxX = points.max { $0.x < $1.x }!.x
          let maxY = points.max { $0.y < $1.y }!.y

          // Convert min and max points to actual image coordinates using VNImagePointForFaceLandmarkPoint.
          let minPoint = VNImagePointForFaceLandmarkPoint(
              vector_float2(Float(minX), Float(minY)),
              boundingBox,
              Int(imageSize.width),
              Int(imageSize.height)
          )
          let maxPoint = VNImagePointForFaceLandmarkPoint(
              vector_float2(Float(maxX), Float(maxY)),
              boundingBox,
              Int(imageSize.width),
              Int(imageSize.height)
          )
          
          // Calculate the center point of the eye based on the bounding box.
          let centerX = (minPoint.x + maxPoint.x) / 2
          let centerY = (minPoint.y + maxPoint.y) / 2

          // Calculate the eye size based on the distance between min and max points.
          let noiseSize = min(maxPoint.x - minPoint.x, maxPoint.y - minPoint.y) * 0.6  // Adjust size multiplier as needed.

          // Define the outer (red) circle, adapting its size to the eye size.
          let outerRadius = noiseSize
          let outerCircleRect = CGRect(x: centerX - outerRadius, y: centerY - outerRadius, width: outerRadius * 2, height: outerRadius * 2)

          // Draw the red outer circle (the eye).
          context.setFillColor(UIColor.red.cgColor)
          context.fillEllipse(in: outerCircleRect)
      }
  
  /// Draws a clown-style mouth based on the provided mouth landmark region.
  ///
  /// This method takes the mouth landmark data and calculates the appropriate size and
  /// position for drawing a mouth that resembles a clown's smile, using red and white lines
  /// to create a striking visual effect. It includes drawing both an outer red mouth line
  /// and an inner white mouth line, slightly offset to create depth.
  ///
  /// - Parameter mouth: The `VNFaceLandmarkRegion2D` representing the mouth landmarks.
  /// - Parameter imageSize: The size of the original image, used for coordinate conversion.
  /// - Parameter observation: The `VNFaceObservation` from which the bounding box is obtained.
  /// - Parameter context: The graphics context where the clown mouth is drawn.
  @MainActor private func drawClownMouth(for mouth: VNFaceLandmarkRegion2D, imageSize: CGSize, in observation: VNFaceObservation, context: CGContext) {
      // Get the bounding box of the face observation.
      let boundingBox = observation.boundingBox

      // Extract the mouth landmark points.
      let points = mouth.normalizedPoints

      // Convert normalized points to actual image coordinates.
      let mouthPoints: [CGPoint] = points.map { point in
          VNImagePointForFaceLandmarkPoint(
              vector_float2(Float(point.x), Float(point.y)),
              boundingBox,
              Int(imageSize.width),
              Int(imageSize.height)
          )
      }

      // Set up the context for drawing the outer red mouth.
      context.setLineWidth(50.0) // Set line width for the outer mouth
      context.setStrokeColor(UIColor.white.cgColor)
      context.beginPath()

      // Move to the first point
      if let firstPoint = mouthPoints.first {
          context.move(to: firstPoint)
      }

      // Draw lines between each of the points
      for point in mouthPoints {
          context.addLine(to: point)
      }

      // Close the path for the outer mouth
      context.closePath()
      context.strokePath() // Draw the red outer mouth line

      // Set up the context for drawing the inner white mouth.
      context.setLineWidth(20.0) // Set line width for the inner mouth
      context.setStrokeColor(UIColor.red.cgColor)
      context.beginPath()

      // Move to the first point for the inner mouth, adjusting points to make it smaller
    let innerOffset: CGFloat = 5.0 //
      if let firstPoint = mouthPoints.first {
          // Adjust to make inner mouth smaller
          context.move(to: CGPoint(x: firstPoint.x, y: firstPoint.y + innerOffset))
      }

      // Draw lines between each of the inner mouth points
      for point in mouthPoints {
          let innerPoint = CGPoint(x: point.x, y: point.y + innerOffset) // Move points slightly down
          context.addLine(to: innerPoint)
      }

      // Close the path for the inner mouth
      context.closePath()
      context.strokePath() // Draw the white inner mouth line
  }

  
}
