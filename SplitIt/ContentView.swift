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
   /*func uploadImage() {
        guard let image = capturedImage, let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("No image to upload")
            return
        }

        let url = URL(string: "http://127.0.0.1:8000/upload-receipt/")! // Replace with your API URL
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
    }*/

    /*func uploadImage() {
        guard let image = capturedImage, let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("No image to upload")
            return
        }

        let url = URL(string: "http://127.0.0.1:8000/upload-receipt/")! // API URL
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type") // Correct content type

        request.httpBody = imageData // Directly send the image data

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Upload failed:", error)
                return
            }
            print("Upload successful:", response ?? "No response")
        }.resume()
    }*/

    func uploadImage() {
    guard let image = capturedImage, let imageData = image.jpegData(compressionQuality: 0.8) else {
        print("No image to upload")
        return
    }

    let url = URL(string: "http://127.0.0.1:8000/upload-receipt/")! // replace 127.0.0.1 with your local IP address
    var request = URLRequest(url: url)
    request.httpMethod = "POST"

    // Create boundary
    let boundary = "Boundary-\(UUID().uuidString)"
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

    // Create body data
    var body = Data()

    // Add the image to the body
    let filename = "receipt.jpg"  // You can change the file name
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
    body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
    body.append(imageData)
    body.append("\r\n".data(using: .utf8)!)

    // Close the body with boundary
    body.append("--\(boundary)--\r\n".data(using: .utf8)!)

    // Set the body for the request
    request.httpBody = body

    // Perform the upload request
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Upload failed:", error)
            return
        }
        
        // Check the response and print the result
        if let response = response as? HTTPURLResponse, response.statusCode == 200 {
            print("Upload successful!")
            // Optionally handle the response data if needed
            if let data = data {
                let responseString = String(data: data, encoding: .utf8) ?? "No response data"
                print("Response: \(responseString)")
            }
        } else {
            print("Upload failed. Response: \(String(describing: response))")
        }
    }.resume()
}

}

#Preview {
    ContentView()
}
