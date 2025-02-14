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
                }
                
                Spacer()
            }
            .padding(.top, 100)
        }
        .sheet(isPresented: $showCamera) {  // Presents the camera when true
            CameraView(image: $capturedImage)
        }
    }
}

#Preview {
    ContentView()
}

//
//                if let image = capturedImage {
//                    Image(uiImage: image)
//                        .resizable()
//                        .scaledToFit()
//                        .frame(height: 300)
//                        .cornerRadius(10)
//                        .padding()
//                } else {
//                    Button(action: {
//                        showCamera = true
//                    }) {
//                        Text("Take a Photo of Your Receipt")
//                            .font(.headline)
//                            .foregroundColor(.white)
//                            .padding()
//                            .background(Color.blue)
//                            .cornerRadius(10)
//                    }
//                    .padding(.top, 20)
//                }
//
//                Spacer()
//            }
//        }
//        .sheet(isPresented: $showCamera) {
//            CameraView(image: $capturedImage)
//        }
//    }
//}
//
//#Preview {
//    ContentView()
//}
