//import SwiftUI
//
//struct AssignmentView: View {
//    @State private var people: [Person] = []
//    @State private var newName: String = ""
//    @State private var selectedPersonID: UUID? = nil
//    @State private var selectedItems: [Item] = []
//
//    let items: [Item]
//
//    var body: some View {
//        NavigationView {
//            VStack(spacing: 20) {
//                HStack {
//                    TextField("Add person", text: $newName)
//                        .textFieldStyle(RoundedBorderTextFieldStyle())
//                    Button("Add") {
//                        if !newName.isEmpty {
//                            people.append(Person(name: newName))
//                            newName = ""
//                        }
//                    }
//                }
//                .padding(.horizontal)
//
//                ScrollView {
//                    ForEach(people.indices, id: \ .self) { index in
//                        let person = people[index]
//                        VStack(alignment: .leading, spacing: 10) {
//                            HStack {
//                                Text(person.name)
//                                    .font(.title2)
//                                    .fontWeight(.bold)
//                                    .foregroundColor(.black)
//                                Spacer()
//                                Button("Assign Items") {
//                                    selectedPersonID = person.id
//                                    selectedItems = person.items
//                                }
//                            }
//
//                            ForEach(person.items, id: \ .description) { item in
//                                HStack {
//                                    Text(item.description)
//                                        .foregroundColor(.gray)
//                                    Spacer()
//                                    Text(String(format: "$%.2f", item.price))
//                                        .foregroundColor(.gray)
//                                }
//                            }
//
//                            Divider()
//
//                            HStack {
//                                Text("Total:")
//                                    .fontWeight(.semibold)
//                                Spacer()
//                                Text(String(format: "$%.2f", person.total))
//                                    .fontWeight(.semibold)
//                            }
//                        }
//                        .padding()
//                        .background(Color.white)
//                        .cornerRadius(12)
//                        .shadow(radius: 4)
//                        .padding(.horizontal)
//                    }
//                }
//
//                Spacer()
//            }
//            .navigationTitle("Assign Items")
//            .sheet(item: Binding(
//                get: { selectedPersonID.map { SheetPerson(id: $0) } },
//                set: { selectedPersonID = $0?.id }
//            )) { sheetPerson in
//                AssignItemsView(
//                    allItems: items,
//                    assignedItems: people.first(where: { $0.id == sheetPerson.id })?.items ?? [],
//                    onSave: { newItems in
//                        if let index = people.firstIndex(where: { $0.id == sheetPerson.id }) {
//                            people[index].items = newItems
//                        }
//                        selectedPersonID = nil
//                    }
//                )
//            }
//        }
//    }
//}
//
//struct AssignItemsView: View {
//    let allItems: [Item]
//    @State var selected: Set<String> = []
//    var assignedItems: [Item]
//    var onSave: ([Item]) -> Void
//
//    var body: some View {
//        NavigationView {
//            List(allItems, id: \ .description, selection: $selected) { item in
//                HStack {
//                    Text(item.description)
//                    Spacer()
//                    Text(String(format: "$%.2f", item.price))
//                }
//            }
//            .onAppear {
//                selected = Set(assignedItems.map { $0.description })
//            }
//            .navigationTitle("Select Items")
//            .toolbar {
//                ToolbarItem(placement: .confirmationAction) {
//                    Button("Save") {
//                        let selectedItems = allItems.filter { selected.contains($0.description) }
//                        onSave(selectedItems)
//                    }
//                }
//                ToolbarItem(placement: .cancellationAction) {
//                    Button("Cancel") {
//                        onSave(assignedItems)
//                    }
//                }
//            }
//        }
//    }
//}
//
//struct Person: Identifiable {
//    let id = UUID()
//    var name: String
//    var items: [Item] = []
//
//    var total: Double {
//        items.reduce(0) { $0 + $1.price }
//    }
//}
//
//struct SheetPerson: Identifiable {
//    var id: UUID
//}
//


import SwiftUI

struct AssignmentView: View {
    @State private var people: [Person] = []
    @State private var newName: String = ""
    @State private var selectedPersonID: UUID? = nil

    let items: [Item]

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                HStack {
                    TextField("Add person", text: $newName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("Add") {
                        if !newName.isEmpty {
                            people.append(Person(name: newName))
                            newName = ""
                        }
                    }
                }
                .padding(.horizontal)

                ScrollView {
                    let sharedItemCounts = Dictionary(grouping: people.flatMap { $0.items }, by: { $0.id })
                        .mapValues { $0.count }
                    
                    
                    ForEach(people.indices, id: \.self) { index in
                        let person = people[index]
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(person.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                Spacer()
                                Button("Assign Items") {
                                    selectedPersonID = person.id
                                }
                            }

//                            ForEach(person.items, id: \.id) { item in
//                                HStack {
//                                    Text(item.description)
//                                        .foregroundColor(.gray)
//                                    Spacer()
//                                    Text(String(format: "$%.2f", item.price))
//                                        .foregroundColor(.gray)
//                                }
//                            }
                            let sharedItemCounts = Dictionary(grouping: people.flatMap { $0.items }, by: { $0.id })
                                .mapValues { $0.count }

                            ForEach(person.items, id: \.id) { item in
                                let count = sharedItemCounts[item.id] ?? 1
                                let splitPrice = item.price / Double(count)
                                
                                HStack {
                                    Text(item.description)
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text(String(format: "$%.2f", splitPrice))
                                        .foregroundColor(.gray)
                                }
                            }


                            Divider()

                            HStack {
                                Text("Total:")
                                    .fontWeight(.semibold)
                                Spacer()

                                Text(String(format: "$%.2f", person.total(sharedItemCounts: sharedItemCounts)))
                                    .fontWeight(.semibold)
//                                Text(String(format: "$%.2f", person.total))
//                                    .fontWeight(.semibold)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                        .padding(.horizontal)
                    }
                }

                Spacer()
            }
            .navigationTitle("Assign Items")
            .sheet(item: Binding(
                get: { selectedPersonID.map { SheetPerson(id: $0) } },
                set: { selectedPersonID = $0?.id }
            )) { sheetPerson in
                AssignItemsView(
                    allItems: items,
                    assignedItems: people.first(where: { $0.id == sheetPerson.id })?.items ?? [],
                    onSave: { newItems in
                        if let index = people.firstIndex(where: { $0.id == sheetPerson.id }) {
                            people[index].items = newItems
                        }
                        selectedPersonID = nil
                    }
                )
            }
        }
    }
}

struct AssignItemsView: View {
    let allItems: [Item]
    var assignedItems: [Item]
    var onSave: ([Item]) -> Void

    @State private var selected: Set<Item> = []
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List(allItems, id: \.self, selection: $selected) { item in
                HStack {
                    Text(item.description)
                    Spacer()
                    Text(String(format: "$%.2f", item.price))
                }
            }
            .environment(\.editMode, .constant(.active)) // Enables multi-select UI
            .onAppear {
                selected = Set(assignedItems)
            }
            .navigationTitle("Select Items")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(Array(selected))
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

//struct Person: Identifiable {
//    let id = UUID()
//    var name: String
//    var items: [Item] = []
//
//    var total: Double {
//        items.reduce(0) { $0 + $1.price }
//    }
//}
struct Person: Identifiable {
    let id = UUID()
    var name: String
    var items: [Item] = []

    func total(sharedItemCounts: [UUID: Int]) -> Double {
        items.reduce(0) { total, item in
            let sharedCount = sharedItemCounts[item.id] ?? 1
            return total + (item.price / Double(sharedCount))
        }
    }
}


struct SheetPerson: Identifiable {
    var id: UUID
}

//struct Item: Identifiable, Hashable {
//    let id = UUID()
//    let description: String
//    let price: Double
//
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(id)
//    }
//
//    static func == (lhs: Item, rhs: Item) -> Bool {
//        lhs.id == rhs.id
//    }
//}
