import SwiftUI

struct AssignmentView: View {
    @State private var people: [Person] = []
    @State private var newName: String = ""
    @State private var selectedPersonID: UUID? = nil

    let items: [Item]
    let total: Double
    let tax: Double
    let tip: Double
    
    var sharedItemCounts: [UUID: Int] {
        Dictionary(grouping: people.flatMap { $0.items }, by: { $0.id })
            .mapValues { $0.count }
    }
    
    // Total subtotal of all assigned items (used for proportion)
    var totalSubtotal: Double {
        people.flatMap { $0.items }.reduce(0) { $0 + $1.price }
    }

    // Calculate each person’s subtotal (based on shared item counts)
    func personSubtotal(_ person: Person) -> Double {
        person.items.reduce(0) { total, item in
            let count = sharedItemCounts[item.id] ?? 1
            return total + (item.price / Double(count))
        }
    }

    // Person’s proportional tax
    func taxFor(_ person: Person) -> Double {
        guard totalSubtotal > 0 else { return 0 }
        return (personSubtotal(person) / totalSubtotal) * tax
    }

    // Person’s proportional tip
    func tipFor(_ person: Person) -> Double {
        guard totalSubtotal > 0 else { return 0 }
        return (personSubtotal(person) / totalSubtotal) * tip
    }

    // Person’s final total
    func totalFor(_ person: Person) -> Double {
        personSubtotal(person) + taxFor(person) + tipFor(person)
    }
    
    func shareBillSplit() {
        let summary = people.map { person in
            let total = String(format: "$%.2f", totalFor(person))
            return "\(person.name): \(total)"
        }.joined(separator: "\n")

        let activityVC = UIActivityViewController(activityItems: [summary], applicationActivities: nil)

        // Present the activity view controller
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true, completion: nil)
        }
    }


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
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    }
                }
                .padding(.horizontal)
                
                List {
                    ForEach(people) { person in
                        PersonRow(
                            person: person,
                            sharedItemCounts: sharedItemCounts,
                            tax: tax,
                            tip: tip,
                            getSubtotal: personSubtotal,
                            getTax: taxFor,
                            getTip: tipFor,
                            getTotal: totalFor,
                            onAssignTapped: {
                                selectedPersonID = person.id
                            },
                            onDelete: {
                                withAnimation {
                                    if let index = people.firstIndex(where: { $0.id == person.id }) {
                                        people.remove(at: index)
                                    }
                                }
                            },
                            onNameChanged: { newName in
                                if let index = people.firstIndex(where: { $0.id == person.id }) {
                                    people[index].name = newName
                                }
                            }
                        )
                    }
                }
                .listStyle(.plain)

                Button(action: shareBillSplit) {
                    Label("Share Your Split", systemImage: "square.and.arrow.up")
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.bottom)


                Spacer()
            }
            .navigationTitle("Assign Items")
            .sheet(item: Binding(
                get: { selectedPersonID.map { SheetPerson(id: $0) } },
                set: { selectedPersonID = $0?.id }
            )) { sheetPerson in
                let selectedPerson = people.first(where: { $0.id == sheetPerson.id })!
                let itemCounts = Dictionary(grouping: people.flatMap { $0.items }, by: { $0 })
                    .mapValues { $0.count }

                AssignItemsView(
                    allItems: items,
                    assignedItems: selectedPerson.items,
                    assignedCounts: itemCounts,
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
    var assignedCounts: [Item: Int] // ← added
    var onSave: ([Item]) -> Void

    @State private var selected: Set<Item> = []
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List(allItems, id: \.self, selection: $selected) { item in
                HStack {
                    VStack(alignment: .leading) {
                        Text(item.description)
                        if let count = assignedCounts[item], count > 0 {
                            Text("Assigned to \(count) \(count == 1 ? "person" : "people")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    Text(String(format: "$%.2f", item.price))
                        .foregroundColor(.gray)
                }
            }
            .environment(\.editMode, .constant(.active))
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

struct PersonCardView: View {
    @State private var isEditingName = false
    @FocusState private var isNameFieldFocused: Bool
    @State private var editedName: String = ""
    let person: Person
    let sharedItemCounts: [UUID: Int]
    let tax: Double
    let tip: Double
    let getSubtotal: (Person) -> Double
    let getTax: (Person) -> Double
    let getTip: (Person) -> Double
    let getTotal: (Person) -> Double
    var onAssignTapped: () -> Void
    var onNameChanged: (String) -> Void
    
    func saveEditedName() {
        guard isEditingName else { return }
        isEditingName = false
        if editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return
        }
        if editedName != person.name {
            onNameChanged(editedName)
        }
    }
    

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                if isEditingName {
                    TextField("Name", text: $editedName)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.title2.bold())
                        .foregroundColor(.black)
                        .frame(maxWidth: 150)
                        .focused($isNameFieldFocused)
                        .onSubmit {
                            saveEditedName()
                        }
                        .onChange(of: isNameFieldFocused) {
                            if !isNameFieldFocused {
                                saveEditedName()
                            }
                        }

                } else {
                    Text(person.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .lineLimit(1)

                    Button(action: {
                        editedName = person.name
                        isEditingName = true
                        isNameFieldFocused = true // immediately focus the text field
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                    }
                }

                Spacer()

                Button(action: onAssignTapped) {
                    Text("Assign Items")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
            }


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

            Group {
                HStack {
                    Text("Subtotal:")
                    Spacer()
                    Text(String(format: "$%.2f", getSubtotal(person)))
                }
                HStack {
                    Text("Tax:")
                    Spacer()
                    Text(String(format: "$%.2f", getTax(person)))
                }
                HStack {
                    Text("Tip:")
                    Spacer()
                    Text(String(format: "$%.2f", getTip(person)))
                }
                Divider()
                HStack {
                    Text("Total:")
                        .fontWeight(.semibold)
                    Spacer()
                    Text(String(format: "$%.2f", getTotal(person)))
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(.black)
        }
    }
}

struct PersonRow: View {
    let person: Person
    let sharedItemCounts: [UUID: Int]
    let tax: Double
    let tip: Double
    let getSubtotal: (Person) -> Double
    let getTax: (Person) -> Double
    let getTip: (Person) -> Double
    let getTotal: (Person) -> Double
    let onAssignTapped: () -> Void
    let onDelete: () -> Void
    let onNameChanged: (String) -> Void

    var body: some View {
        ZStack {
            PersonCardView(
                person: person,
                sharedItemCounts: sharedItemCounts,
                tax: tax,
                tip: tip,
                getSubtotal: getSubtotal,
                getTax: getTax,
                getTip: getTip,
                getTotal: getTotal,
                onAssignTapped: onAssignTapped,
                onNameChanged: onNameChanged
            )
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 4)
        }
        .listRowSeparator(.hidden)
        .swipeActions {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
                    .labelStyle(IconOnlyLabelStyle())
            }
        }
    }
}



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

