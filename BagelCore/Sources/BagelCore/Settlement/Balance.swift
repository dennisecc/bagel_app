import Foundation

/// A single person's net position across all expenses: positive means they're
/// owed money overall, negative means they owe money overall.
public struct Balance: Sendable, Equatable {
    public var personID: UUID
    public var netAmount: Decimal

    public init(personID: UUID, netAmount: Decimal) {
        self.personID = personID
        self.netAmount = netAmount
    }
}

/// One leg of a simplified settlement: `from` pays `to` `amount`.
public struct SettlementTransaction: Sendable, Equatable {
    public var from: UUID
    public var to: UUID
    public var amount: Decimal

    public init(from: UUID, to: UUID, amount: Decimal) {
        self.from = from
        self.to = to
        self.amount = amount
    }
}
