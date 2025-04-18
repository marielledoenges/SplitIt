import SwiftUI
import FirebaseFirestore

struct ResponseView: View {
    //let responseText: String
    @State private var responseText: String = ""

    /*var body: some View {
        ScrollView {
            if responseText.isEmpty {
                Text("No response received.")
                    .foregroundColor(.red)
                    .padding()
            } else {
                Text(responseText)
                    .padding()
            }
        }
        .navigationTitle("Receipt Result")
        .onAppear {
            fetchResponse()
        }
    }*/
    
    var body: some View {
        ScrollView {
            if responseText.isEmpty {
                Text("Loading response...")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                Text(responseText)
                    .padding()
            }
        }
        .navigationTitle("Receipt Result")
        .onAppear {
            fetchResponse()
        }
    }

    func fetchResponse() {
        let db = Firestore.firestore()
        db.collection("items").document("1").getDocument { snapshot, error in
            if let data = snapshot?.data(), let value = data["name"] as? String {
                responseText = value
            } else {
                responseText = "No valid response found."
            }
        }
    }

}

