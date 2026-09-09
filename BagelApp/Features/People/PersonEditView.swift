import SwiftUI
import SwiftData

struct PersonEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let person: Person?

    @State private var name: String
    @State private var colorHex: String

    private static let palette = ["#4A90D9", "#5FAD56", "#F2994A", "#BB6BD9", "#EB5757", "#2D9CDB", "#F2C94C"]

    init(person: Person?) {
        self.person = person
        _name = State(initialValue: person?.name ?? "")
        _colorHex = State(initialValue: person?.colorHex ?? Self.palette.randomElement()!)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)

                Picker("Color", selection: $colorHex) {
                    ForEach(Self.palette, id: \.self) { hex in
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 24, height: 24)
                            .tag(hex)
                    }
                }
                .pickerStyle(.palette)
            }
            .navigationTitle(person == nil ? "New Person" : "Edit Person")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if let person {
            person.name = trimmedName
            person.colorHex = colorHex
        } else {
            modelContext.insert(Person(name: trimmedName, colorHex: colorHex))
        }
        dismiss()
    }
}

#Preview {
    PersonEditView(person: nil)
        .modelContainer(ModelContainerFactory.makeContainer(inMemory: true))
}
