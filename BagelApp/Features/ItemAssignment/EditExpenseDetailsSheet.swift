import SwiftUI

struct EditExpenseDetailsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var document: ExpenseDocument

    @State private var merchantName: String
    @State private var documentDate: Date
    @State private var documentType: DocumentType
    @State private var totalAmountText: String
    @State private var currencyCode: String

    init(document: ExpenseDocument) {
        self.document = document
        _merchantName = State(initialValue: document.merchantName)
        _documentDate = State(initialValue: document.documentDate)
        _documentType = State(initialValue: document.documentType)
        _totalAmountText = State(initialValue: "\(document.totalAmount)")
        _currencyCode = State(initialValue: document.currencyCode)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Merchant", text: $merchantName)
                DatePicker("Date", selection: $documentDate, displayedComponents: .date)
                Picker("Type", selection: $documentType) {
                    Text("Receipt").tag(DocumentType.receipt)
                    Text("Statement").tag(DocumentType.statement)
                }
                TextField("Total Amount", text: $totalAmountText)
                    .keyboardType(.decimalPad)
                TextField("Currency Code", text: $currencyCode)
                    .textInputAutocapitalization(.characters)
            }
            .navigationTitle("Edit Expense")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(merchantName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        document.merchantName = merchantName.trimmingCharacters(in: .whitespaces)
        document.documentDate = documentDate
        document.documentType = documentType
        document.totalAmount = Decimal(string: totalAmountText) ?? document.totalAmount
        let trimmedCurrency = currencyCode.trimmingCharacters(in: .whitespaces).uppercased()
        document.currencyCode = trimmedCurrency.isEmpty ? document.currencyCode : trimmedCurrency
        dismiss()
    }
}
