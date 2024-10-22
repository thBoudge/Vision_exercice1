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

struct CameraFunnyFacesView: View {
  @StateObject var viewModel: CameraFunnyFacesViewModel
  @StateObject var cameraViewModel: CameraViewModel
    @State private var funnyEyes = true
    @State private var funnyNose = true
    @State private var funnyMouth = true
    
    var body: some View {
      
        VStack {
          Spacer()
            if let image = cameraViewModel.currentFrame?.drawFunnyFace(observations: viewModel.faceObservations, isWithEyes: funnyEyes, isWithNose: funnyNose, isWithmouth: funnyMouth) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .rotationEffect(.degrees(90.0))
                    .padding()
            } else {
                Text("No camera feed available")
            }
          Spacer()
            HStack {
                Toggle("Funny Eyes", isOn: $funnyEyes)
                Toggle("Funny Nose", isOn: $funnyNose)
                Toggle("Funny Mouth", isOn: $funnyMouth)
            }
            .padding()
        }
        .onAppear {
          
            Task {
              await cameraViewModel.setupSession()
              await cameraViewModel.startSession()
            }
            if let image = cameraViewModel.currentFrame {
              viewModel.detectFaces(for: image)
            }
          }
        .onChange(of: cameraViewModel.currentFrame) { newFrame in
            if let image = newFrame {
              viewModel.detectFaces(for: image)
            }
        }
        .onDisappear {
          cameraViewModel.stopSession()
        }
    }
}

