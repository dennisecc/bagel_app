import SwiftUI
import SwiftData

struct PeopleListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Person.createdAt) private var people: [Person]

    @State private var personToEdit: Person?
    @State private var isPresentingNewPerson = false

    var body: some View {
        List {
            ForEach(people) { person in
                Button {
                    personToEdit = person
                } label: {
                    PersonRow(person: person)
                }
                .buttonStyle(.plain)
            }
            .onDelete(perform: deletePeople)
        }
        .navigationTitle("People")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingNewPerson = true
                } label: {
                    Label("Add Person", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isPresentingNewPerson) {
            PersonEditView(person: nil)
        }
        .sheet(item: $personToEdit) { person in
            PersonEditView(person: person)
        }
        .overlay {
            if people.isEmpty {
                ContentUnavailableView(
                    "No People Yet",
                    systemImage: "person.2",
                    description: Text("Add people to split expenses with.")
                )
            }
        }
    }

    private func deletePeople(at offsets: IndexSet) {
        for index in offsets {
            let person = people[index]
            guard !person.isDefaultOwner else { continue }
            modelContext.delete(person)
        }
    }
}

private struct PersonRow: View {
    let person: Person

    var body: some View {
        HStack {
            Circle()
                .fill(Color(hex: person.colorHex))
                .frame(width: 32, height: 32)
                .overlay(Text(person.name.prefix(1)).foregroundStyle(.white).font(.headline))
                .accessibilityHidden(true)
            Text(person.name)
            if person.isDefaultOwner {
                Spacer()
                Text("Me")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        PeopleListView()
    }
    .modelContainer(ModelContainerFactory.makeContainer(inMemory: true))
}
