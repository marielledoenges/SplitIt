////
////  ContentView.swift
////  SplitIt
////
////  Created by Ian Truelsegaard on 2/6/25.
////

import SwiftUI

struct ContentView: View {
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    var body: some View {
        ZStack{
            Image("coffeeBackground")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            
            
            VStack{
                Text("We hope you enjoyed\n your meal.\n\nNow let's Split-It.")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                HStack{
                    Text("Take photo of receipt")
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Spacer().frame(width: 20)
                    
                    Button(action: {
                        showCamera = true
                    }) {
                        Image(systemName: "camera.fill") // SF Symbol for a camera
                            .font(.system(size: 22))     // Adjust the icon size
                            .foregroundColor(.white)     // Set the color
                            .background(Circle()
                                .fill(Color.gray)
                                .frame(width: 40, height: 40))
                    }
//                    .onChange(of: capturedImage){
//                        _ in uploadImage()
//                    }
                    .onChange(of: capturedImage) { oldValue, newValue in
                        if newValue != nil {
                            uploadImage()
                        }
                    }

                }
                
                Spacer()
            }
            .padding(.top, 100)
        }
        .sheet(isPresented: $showCamera) {  // Presents the camera when true
            CameraView(image: $capturedImage)
        }
    }
    func uploadImage() {
        guard let image = capturedImage, let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("No image to upload")
            return
        }

        let url = URL(string: "https://your-api-endpoint.com/upload")! // Replace with your API URL
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let base64String = imageData.base64EncodedString()
        let json: [String: Any] = ["image": base64String]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: json)
        } catch {
            print("Error encoding JSON:", error)
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Upload failed:", error)
                return
            }
            print("Upload successful:", response ?? "No response")
        }.resume()
    }

}

#Preview {
    ContentView()
}
