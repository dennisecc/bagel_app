import SwiftUI
import SwiftData
import BagelCore

struct BalancesView: View {
    @Query private var people: [Person]
    @Query private var documents: [ExpenseDocument]

    private var balances: [Balance] {
        var totalPaid: [UUID: Decimal] = [:]
        var totalOwed: [UUID: Decimal] = [:]

        for document in documents {
            if let payerID = document.payer?.id {
                totalPaid[payerID, default: 0] += document.totalAmount
            }
            for lineItem in document.lineItems {
                for assignment in lineItem.assignments {
                    guard let personID = assignment.person?.id else { continue }
                    totalOwed[personID, default: 0] += assignment.computedAmount
                }
            }
        }
        return DebtSimplifier.computeNetBalances(totalPaidByPerson: totalPaid, totalOwedByPerson: totalOwed)
    }

    private var settlements: [SettlementTransaction] {
        DebtSimplifier.simplify(balances: balances)
    }

    private func name(for id: UUID) -> String {
        people.first { $0.id == id }?.name ?? "Unknown"
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Net Balances") {
                    ForEach(balances, id: \.personID) { balance in
                        HStack {
                            Text(name(for: balance.personID))
                            Spacer()
                            Text(Money.format(balance.netAmount))
                                .foregroundStyle(balance.netAmount >= 0 ? .green : .red)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(name(for: balance.personID))
                        .accessibilityValue(
                            balance.netAmount >= 0
                                ? "Is owed \(Money.format(balance.netAmount))"
                                : "Owes \(Money.format(abs(balance.netAmount)))"
                        )
                    }
                }

                Section("Settle Up") {
                    ForEach(Array(settlements.enumerated()), id: \.offset) { _, transaction in
                        Text("\(name(for: transaction.from)) owes \(name(for: transaction.to)) \(Money.format(transaction.amount))")
                    }
                }
            }
            .navigationTitle("Balances")
            .overlay {
                if documents.isEmpty {
                    ContentUnavailableView(
                        "Nothing to Settle",
                        systemImage: "arrow.left.arrow.right",
                        description: Text("Balances will appear once you've assigned items on an expense.")
                    )
                }
            }
        }
    }
}

#Preview {
    BalancesView()
        .modelContainer(ModelContainerFactory.makeContainer(inMemory: true))
}
