import SwiftUI
import BagelCore

struct AssignPeopleSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let lineItem: LineItem
    let people: [Person]

    @State private var selectedPersonIDs: Set<UUID>
    @State private var isAdvanced: Bool
    @State private var shareType: ShareType
    @State private var shareValues: [UUID: String]

    init(lineItem: LineItem, people: [Person]) {
        self.lineItem = lineItem
        self.people = people

        let existing = lineItem.assignments
        _selectedPersonIDs = State(initialValue: Set(existing.compactMap(\.person?.id)))

        let existingType = existing.first?.shareType ?? .equal
        _isAdvanced = State(initialValue: existingType != .equal)
        _shareType = State(initialValue: existingType == .equal ? .percentage : existingType)

        var values: [UUID: String] = [:]
        for assignment in existing {
            guard let id = assignment.person?.id, assignment.shareType != .equal else { continue }
            values[id] = "\(assignment.shareValue)"
        }
        _shareValues = State(initialValue: values)
    }

    private var selectedPeople: [Person] {
        people.filter { selectedPersonIDs.contains($0.id) }
    }

    private var currencyCode: String {
        lineItem.document?.currencyCode ?? "USD"
    }

    private var computedShares: [SplitShare]? {
        guard !selectedPersonIDs.isEmpty else { return nil }
        if !isAdvanced {
            return selectedPersonIDs.map { SplitShare(personID: $0, type: .equal) }
        }
        var shares: [SplitShare] = []
        for id in selectedPersonIDs {
            guard let raw = shareValues[id], let value = Decimal(string: raw) else { return nil }
            shares.append(SplitShare(personID: id, type: shareType, shareValue: value))
        }
        return shares
    }

    private var validationMessage: String? {
        guard isAdvanced, !selectedPersonIDs.isEmpty else { return nil }
        guard let shares = computedShares else { return "Enter a value for each person." }
        do {
            _ = try SplitCalculator.computeAmounts(lineTotal: lineItem.lineTotal, shares: shares)
            return nil
        } catch SplitCalculatorError.invalidPercentageTotal(let total) {
            return "Percentages must add up to 100 (currently \(total))."
        } catch SplitCalculatorError.exactAmountsDoNotReconcile(let expected, let actual) {
            return "Amounts must add up to \(Money.format(expected, currencyCode: currencyCode)) (currently \(Money.format(actual, currencyCode: currencyCode)))."
        } catch {
            return "Enter valid amounts."
        }
    }

    private var canSave: Bool {
        selectedPersonIDs.isEmpty || (validationMessage == nil && computedShares != nil)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Split \(lineItem.itemDescription)") {
                    ForEach(people) { person in
                        Button {
                            toggle(person)
                        } label: {
                            HStack {
                                Text(person.name)
                                Spacer()
                                if selectedPersonIDs.contains(person.id) {
                                    Image(systemName: "checkmark").foregroundStyle(.tint)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }

                if selectedPersonIDs.count > 1 {
                    Section {
                        Toggle("Advanced Split", isOn: $isAdvanced)
                        if isAdvanced {
                            Picker("Split By", selection: $shareType) {
                                Text("Percentage").tag(ShareType.percentage)
                                Text("Exact Amount").tag(ShareType.exactAmount)
                            }
                            .pickerStyle(.segmented)

                            ForEach(selectedPeople) { person in
                                HStack {
                                    Text(person.name)
                                    Spacer()
                                    TextField(shareType == .percentage ? "%" : "$", text: binding(for: person))
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 80)
                                }
                            }
                        }
                    }
                }

                if let validationMessage {
                    Section {
                        Text(validationMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Assign")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!canSave)
                }
            }
        }
    }

    private func toggle(_ person: Person) {
        if selectedPersonIDs.contains(person.id) {
            selectedPersonIDs.remove(person.id)
        } else {
            selectedPersonIDs.insert(person.id)
        }
    }

    private func binding(for person: Person) -> Binding<String> {
        Binding(
            get: { shareValues[person.id] ?? "" },
            set: { shareValues[person.id] = $0 }
        )
    }

    private func save() {
        if selectedPersonIDs.isEmpty {
            for assignment in lineItem.assignments {
                modelContext.delete(assignment)
            }
            lineItem.assignments.removeAll()
        } else if let shares = computedShares {
            try? AssignmentUpdater.apply(shares: shares, to: lineItem, people: people, in: modelContext)
        }
        dismiss()
    }
}
