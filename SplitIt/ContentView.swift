////
////  ContentView.swift
////  SplitIt
////
////  Created by Ian Truelsegaard on 2/6/25.
////

import SwiftUI
import UIKit
import FirebaseFirestore

struct Item: Identifiable, Hashable, Decodable {
    let id = UUID()
    let description: String
    let price: Double

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Item, rhs: Item) -> Bool {
        lhs.id == rhs.id
    }
}

struct Receipt: Decodable {
    let items: [Item]
    let total: Double
    let total_tax: Double
    let tip: Double
}

struct ContentView: View {
    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var responseText: String = ""
    @State private var showResponseView = false
    @State private var items: [Item] = []

    var body: some View {
        NavigationStack {
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
            .navigationDestination(isPresented: $showResponseView) {
                AssignmentView(items: items)
                //ResponseView()
            }
        }
    }

    func uploadImage() {
        guard let image = capturedImage, let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("No image to upload")
            return
        }

        let url = URL(string: "http://127.0.0.1:8000/upload-receipt/")!
        //replace 127.0.0.1 with your local IP address
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
                if let data = data {
                    let responseString = String(data: data, encoding: .utf8) ?? "No response data"
                    DispatchQueue.main.async {
                        self.responseText = responseString
                        self.showResponseView = true
                        print("ResponseView loaded with responseText:", responseText)
                        // Convert string back to Data
                        if let jsonData = responseString.data(using: .utf8) {
                            uploadReceiptToFirestore(from: jsonData)
                        } else {
                            print("Failed to convert responseString to Data")
                        }
                    }
                }
            } else {
                print("Upload failed. Response: \(String(describing: response))")
            }
        }.resume()
    }

    func uploadReceiptToFirestore(from jsonData: Data) {
        let db = Firestore.firestore()
        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString

        // Define models matching your JSON structure

        do {
//            let decoded = try JSONDecoder().decode(Receipt.self, from: jsonData)
//
//            let itemsArray = decoded.items.map { ["description": $0.description, "price": $0.price] }
//
//            let dataToUpload: [String: Any] = [
//                "items": itemsArray,
//                "total": decoded.total,
//                "total_tax": decoded.total_tax,
//                "tip": decoded.tip
//            ]
            let decoded = try JSONDecoder().decode(Receipt.self, from: jsonData)

            // 🔁 Update UI or @State on main thread
            DispatchQueue.main.async {
                self.items = decoded.items  // <--- Make sure you have @State var items in your ContentView
                self.showResponseView = true
            }

            // If you still want to upload to Firestore as well:
            let itemsArray = decoded.items.map { ["description": $0.description, "price": $0.price] }

            let dataToUpload: [String: Any] = [
                "items": itemsArray,
                "total": decoded.total,
                "total_tax": decoded.total_tax,
                "tip": decoded.tip
            ]

            // Upload to Firestore
            db.collection(deviceID)
                .document("Individual")
                .setData(dataToUpload) { error in
                    if let error = error {
                        print("Error writing document: \(error)")
                    } else {
                        print("Document successfully written!")
                    }
                }

        } catch {
            print("Failed to decode JSON: \(error)")
        }
    }


}

#Preview {
    ContentView()
}
