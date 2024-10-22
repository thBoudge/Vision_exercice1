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
import PhotosUI

struct FunnyFacesView: View {
    @StateObject var viewModel: FunnyFaceViewModel
    @State private var funnyEyes = true
    @State private var funnyNose = true
    @State private var funnyMouth = true
    @State private var isLoading = false  // Track the loading state

    var body: some View {
        VStack {
            if isLoading {  
                ProgressView("Loading image...")
                    .padding()
            } else if let image = viewModel.currenimage?.drawFunnyFace(observations: viewModel.faceObservations, isWithEyes: funnyEyes, isWithNose: funnyNose, isWithmouth: funnyMouth) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)

                HStack {
                    Toggle("Funny Eyes", isOn: $funnyEyes)
                    Toggle("Funny Nose", isOn: $funnyNose)
                    Toggle("Funny Mouth", isOn: $funnyMouth)
                }
                .padding()

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else if !funnyEyes && !funnyNose && !funnyMouth {
                    Text("Please select an image to show funny faces.")
                } else {
                    // Share link to share the image
                    if let imageURL = viewModel.saveImageToTempDirectory(image: image) {
                        ShareLink(item: imageURL, subject: Text("Check out this funny face!"), message: Text("I made this funny face!")) {
                            Label("Share Funny Face", systemImage: "square.and.arrow.up")
                        }
                        .padding()
                    }
                }
            } else {
                Text("No image available")
            }
        }
        .onAppear {
            startImageProcessing()  // Start processing when the view appears
        }
        .onChange(of: viewModel.photoPickerViewModel.selectedPhoto?.image) { newPhoto in
            startImageProcessing()  // Start processing when a new image is selected
        }
        .padding()
    }

    // Helper function to start image processing and show loading cursor
    func startImageProcessing() {
        isLoading = true  // Show loading indicator
      Task {
        await viewModel.detectFaces()
        isLoading = false
      }
    }
}
